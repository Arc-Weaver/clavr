{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE DataKinds #-}
module AVR.ISA.Arith where

import Prelude hiding (Word)

import Hdl.Bits hiding (zeroExtend, signExtend, truncateB, bitCoerce, slice, add, mul, shiftL, shiftR, xor, (.&.), (.|.))
import Isacle.ISA
import AVR.ISA.Types

-- An 8-bit value-typed operation on register contents.
type Op8 = IExpr (Unsigned 8) -> IExpr (Unsigned 8) -> IExpr (Unsigned 8)

-- ---------------------------------------------------------------------------
-- Two-register arithmetic/logical instructions  ("00XX_XXrd_dddd_rrrr")
-- The "<6 fixed bits>rd_dddd_rrrr" shape is captured by 'twoReg'.
-- ---------------------------------------------------------------------------

-- | A two-register op: read Rd and Rr, combine with @f@, write Rd.
twoRegOp :: AVR m pcW => String -> Op8 -> m ()
twoRegOp pre f = do
    (d, r) <- defineInstruction $ twoReg pre
    a <- readRegFileF avrGPR d
    b <- readRegFileF avrGPR r
    writeRegFileF avrGPR d (f a b)
    stubArith
    pcAdvance

-- | A two-register compare (no write-back): the difference drives the flags,
-- which are stubbed here, so only the operand reads remain.
twoRegCmp :: AVR m pcW => String -> m ()
twoRegCmp pre = do
    (d, r) <- defineInstruction $ twoReg pre
    _ <- readRegFileF avrGPR d
    _ <- readRegFileF avrGPR r
    stubArith
    pcAdvance

instrADD, instrADC, instrSUB, instrSBC, instrAND, instrOR, instrEOR :: AVR m pcW => m ()
instrADD = mnemonic "ADD" >> twoRegOp "000011" (+)
instrADC = mnemonic "ADC" >> twoRegOp "000111" (+)
instrSUB = mnemonic "SUB" >> twoRegOp "000110" (-)
instrSBC = mnemonic "SBC" >> twoRegOp "000010" (-)
instrAND = mnemonic "AND" >> twoRegOp "001000" (.&.)
instrOR  = mnemonic "OR"  >> twoRegOp "001010" (.|.)
instrEOR = mnemonic "EOR" >> twoRegOp "001001" xor

instrCP, instrCPC, instrCPSE :: AVR m pcW => m ()
instrCP   = mnemonic "CP"   >> twoRegCmp "000101"
instrCPC  = mnemonic "CPC"  >> twoRegCmp "000001"
instrCPSE = mnemonic "CPSE" >> twoRegCmp "000100"   -- skip stubbed: always advance 1

-- MOV Rd, Rr — 0010_11rd_dddd_rrrr
instrMOV :: AVR m pcW => m ()
instrMOV = do
    mnemonic "MOV"
    (d, r) <- defineInstruction $ twoReg "001011"
    writeRegFileF avrGPR d =<< readRegFileF avrGPR r
    pcAdvance

-- MUL Rd, Rr — 1001_11rd_dddd_rrrr  (unsigned 8×8 → 16-bit product in R1:R0)
-- The product is genuinely 16 bits: 'mul' grows the result type to Unsigned 16,
-- and its low/high bytes go to R0/R1 (fixed result registers, by constant index).
instrMUL :: AVR m pcW => m ()
instrMUL = do
    mnemonic "MUL"
    (d, r) <- defineInstruction $ twoReg "100111"
    a <- readRegFileF avrGPR d
    b <- readRegFileF avrGPR r
    let p = mul a b :: IExpr (Unsigned 16)
    writeRegFileAt avrGPR 0 (truncateB p)     -- R0 = product[7:0]
    writeRegFileAt avrGPR 1 (slice 15 8 p)    -- R1 = product[15:8]
    stubArith
    pcAdvance

-- ---------------------------------------------------------------------------
-- Upper-register + 8-bit immediate instructions  ("XXXX_KKKK_dddd_KKKK")
-- The "<4 fixed bits>KKKK_dddd_KKKK" shape (Rd+16, split K) is 'immReg'.
-- ---------------------------------------------------------------------------

-- | An upper-register immediate op: read Rd (R16–R31), combine with K via @f@.
immRegOp :: AVR m pcW => String -> Op8 -> m ()
immRegOp pre f = do
    (d, k) <- defineInstruction $ immReg pre
    a <- readRegFileFOffset avrGPR d 16
    writeRegFileFOffset avrGPR d 16 (f a (immediateF k))
    stubArith
    pcAdvance

instrSUBI, instrSBCI, instrANDI, instrORI :: AVR m pcW => m ()
instrSUBI = mnemonic "SUBI" >> immRegOp "0101" (-)
instrSBCI = mnemonic "SBCI" >> immRegOp "0100" (-)
instrANDI = mnemonic "ANDI" >> immRegOp "0111" (.&.)
instrORI  = mnemonic "ORI"  >> immRegOp "0110" (.|.)

-- LDI Rd, K — 1110_KKKK_dddd_KKKK
instrLDI :: AVR m pcW => m ()
instrLDI = do
    mnemonic "LDI"
    (d, k) <- defineInstruction $ immReg "1110"
    writeRegFileFOffset avrGPR d 16 (immediateF k)
    pcAdvance

-- CPI Rd, K — 0011_KKKK_dddd_KKKK  (compare, no write-back; flags stubbed)
instrCPI :: AVR m pcW => m ()
instrCPI = do
    mnemonic "CPI"
    (d, _k) <- defineInstruction $ immReg "0011"
    _ <- readRegFileFOffset avrGPR d 16
    stubArith
    pcAdvance

-- ---------------------------------------------------------------------------
-- Single-register instructions  ("1001_010d_dddd_XXXX", contiguous 5-bit d)
-- ---------------------------------------------------------------------------

-- | A single-register op given the 4-bit suffix and a pure transform of Rd.
oneRegOp :: AVR m pcW => String -> (IExpr (Unsigned 8) -> IExpr (Unsigned 8)) -> m ()
oneRegOp suf f = do
    d <- defineInstruction $ do
        fixed "1001010"; d <- field @(Unsigned 5); fixed suf; return d
    a <- readRegFileF avrGPR d
    writeRegFileF avrGPR d (f a)
    stubArith
    pcAdvance

instrINC, instrCOM, instrNEG, instrASR, instrLSR, instrROR :: AVR m pcW => m ()
instrINC = mnemonic "INC" >> oneRegOp "0011" (\a -> a + 1)
instrCOM = mnemonic "COM" >> oneRegOp "0000" inv
instrNEG = mnemonic "NEG" >> oneRegOp "0001" (\a -> 0 - a)
instrASR = mnemonic "ASR" >> oneRegOp "0101" (\a -> arithShiftR a 1)
instrLSR = mnemonic "LSR" >> oneRegOp "0110" (\a -> shiftR a 1)
instrROR = mnemonic "ROR" >> oneRegOp "0111" (\a -> shiftR a 1)

-- SWAP Rd — 1001_010d_dddd_0010
instrSWAP :: AVR m pcW => m ()
instrSWAP = do
    mnemonic "SWAP"
    d <- defineInstruction $ do
        fixed "1001010"; d <- field @(Unsigned 5); fixed "0010"; return d
    a <- readRegFileF avrGPR d
    let hi = shiftR a 4
        lo = shiftL a 4
    writeRegFileF avrGPR d (hi .|. lo)
    pcAdvance

-- DEC Rd — 1001_010d_dddd_1010  (sets Z, clears the other arith flags)
instrDEC :: AVR m pcW => m ()
instrDEC = do
    mnemonic "DEC"
    d <- defineInstruction $ do
        fixed "1001010"; d <- field @(Unsigned 5); fixed "1010"; return d
    a   <- readRegFileF avrGPR d
    let r = a - 1
    writeRegFileF avrGPR d r
    alu <- cpu id
    zf  <- isZero r
    setFlag (avrFlagZ alu) zf
    mapM_ setFlagLo [ avrFlagC alu, avrFlagN alu, avrFlagV alu
                    , avrFlagS alu, avrFlagH alu ]
    pcAdvance

-- ---------------------------------------------------------------------------
-- MULS — signed multiply upper regs — 0000_0010_dddd_rrrr  (d+16, r+16)
-- Same shape as MUL, but the operands are reinterpreted as signed before the
-- (now signed) growing multiply — the only difference between MUL and MULS is
-- the operand /type/, not the opcode.
-- ---------------------------------------------------------------------------

instrMULS :: AVR m pcW => m ()
instrMULS = do
    mnemonic "MULS"
    (d, r) <- defineInstruction $ do
        fixed "00000010"; d <- field @(Unsigned 4); r <- field @(Unsigned 4); return (d, r)
    a <- readRegFileFOffset avrGPR d 16
    b <- readRegFileFOffset avrGPR r 16
    let p = asUnsigned (mul (asSigned a) (asSigned b)) :: IExpr (Unsigned 16)
    writeRegFileAt avrGPR 0 (truncateB p)
    writeRegFileAt avrGPR 1 (slice 15 8 p)
    stubArith
    pcAdvance

-- ---------------------------------------------------------------------------
-- ADIW / SBIW — wide immediate add/sub on register pairs
-- 1001_011X_KKdd_KKKK  (X=0 ADIW, X=1 SBIW; d=2-bit pair selector → 24+2*d).
-- ---------------------------------------------------------------------------

-- | The wide-immediate shape: 6-bit K split (KK high, KKKK low), 2-bit pair dd.
adiwEnc :: String -> Encoding (Field (Unsigned 2), Field (Unsigned 6))
adiwEnc pre = do
    fixed pre
    k <- placeholder @(Unsigned 6)
    bindBits k 2            -- KK (bits 7-6)
    d <- field @(Unsigned 2)  -- dd (bits 5-4)
    bindBits k 4            -- KKKK (bits 3-0)
    return (d, k)

wideImmOp :: AVR m pcW => String -> Op8 -> m ()
wideImmOp pre f = do
    (d, k) <- defineInstruction $ adiwEnc pre
    a <- readRegFileFOffset avrGPR d 24
    let k8 = zeroExtendC (immediateF k :: IExpr (Unsigned 6)) :: IExpr (Unsigned 8)   -- 6 <= 8
    writeRegFileFOffset avrGPR d 24 (f a k8)
    stubArith
    pcAdvance

instrADIW, instrSBIW :: AVR m pcW => m ()
instrADIW = mnemonic "ADIW" >> wideImmOp "10010110" (+)
instrSBIW = mnemonic "SBIW" >> wideImmOp "10010111" (-)
