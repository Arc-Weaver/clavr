{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE DataKinds #-}
module AVR.ISA.Arith where

import Prelude hiding (Word)

import Hdl.Bits hiding (zeroExtend, signExtend, truncateB, bitCoerce, slice)
import Isacle.ISA
import Isacle.ISA.Types (CPURegister(..))
import AVR.ISA.Types

-- ---------------------------------------------------------------------------
-- Two-register arithmetic/logical instructions  ("00XX_XXrd_dddd_rrrr")
-- The "<6 fixed bits>rd_dddd_rrrr" shape is captured by 'twoReg'.
-- ---------------------------------------------------------------------------

-- | A two-register op: read Rd and Rr, combine, write Rd.
twoRegOp :: AVR m pcW => String -> ALUPrim -> m ()
twoRegOp pre op = do
    (d, r) <- defineInstruction $ twoReg pre
    a <- readRegFileF avrGPR d
    b <- readRegFileF avrGPR r
    writeRegFileF avrGPR d =<< aluOp op a b
    stubArith
    pcAdvance

-- | A two-register compare (no write-back): read Rd and Rr, subtract, discard.
twoRegCmp :: AVR m pcW => String -> m ()
twoRegCmp pre = do
    (d, r) <- defineInstruction $ twoReg pre
    a <- readRegFileF avrGPR d
    b <- readRegFileF avrGPR r
    _ <- aluOp PSub a b
    stubArith
    pcAdvance

instrADD, instrADC, instrSUB, instrSBC, instrAND, instrOR, instrEOR :: AVR m pcW => m ()
instrADD = mnemonic "ADD" >> twoRegOp "000011" PAdd
instrADC = mnemonic "ADC" >> twoRegOp "000111" PAdd
instrSUB = mnemonic "SUB" >> twoRegOp "000110" PSub
instrSBC = mnemonic "SBC" >> twoRegOp "000010" PSub
instrAND = mnemonic "AND" >> twoRegOp "001000" PAnd
instrOR  = mnemonic "OR"  >> twoRegOp "001010" POr
instrEOR = mnemonic "EOR" >> twoRegOp "001001" PXor

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

-- MUL Rd, Rr — 1001_11rd_dddd_rrrr  (result → R1:R0, both fixed registers)
instrMUL :: AVR m pcW => m ()
instrMUL = do
    mnemonic "MUL"
    (d, r) <- defineInstruction $ twoReg "100111"
    a <- readRegFileF avrGPR d
    b <- readRegFileF avrGPR r
    res <- aluOp PMul a b
    let r0 = CPURegister "GPR:0" :: CPURegister (Unsigned 8)   -- fixed result regs
        r1 = CPURegister "GPR:1" :: CPURegister (Unsigned 8)
    writeReg r0 res
    writeReg r1 res
    stubArith
    pcAdvance

-- ---------------------------------------------------------------------------
-- Upper-register + 8-bit immediate instructions  ("XXXX_KKKK_dddd_KKKK")
-- The "<4 fixed bits>KKKK_dddd_KKKK" shape (Rd+16, split K) is 'immReg'.
-- ---------------------------------------------------------------------------

-- | An upper-register immediate op: read Rd (R16–R31), combine with K, write Rd.
immRegOp :: AVR m pcW => String -> ALUPrim -> m ()
immRegOp pre op = do
    (d, k) <- defineInstruction $ immReg pre
    a <- readRegFileFOffset avrGPR d 16
    writeRegFileFOffset avrGPR d 16 =<< aluOp op a (immediateF k :: IExpr 8)
    stubArith
    pcAdvance

instrSUBI, instrSBCI, instrANDI, instrORI :: AVR m pcW => m ()
instrSUBI = mnemonic "SUBI" >> immRegOp "0101" PSub
instrSBCI = mnemonic "SBCI" >> immRegOp "0100" PSub
instrANDI = mnemonic "ANDI" >> immRegOp "0111" PAnd
instrORI  = mnemonic "ORI"  >> immRegOp "0110" POr

-- LDI Rd, K — 1110_KKKK_dddd_KKKK
instrLDI :: AVR m pcW => m ()
instrLDI = do
    mnemonic "LDI"
    (d, k) <- defineInstruction $ immReg "1110"
    writeRegFileFOffset avrGPR d 16 (immediateF k :: IExpr 8)
    pcAdvance

-- CPI Rd, K — 0011_KKKK_dddd_KKKK  (compare, no write-back)
instrCPI :: AVR m pcW => m ()
instrCPI = do
    mnemonic "CPI"
    (d, k) <- defineInstruction $ immReg "0011"
    a <- readRegFileFOffset avrGPR d 16
    _ <- aluOp PSub a (immediateF k :: IExpr 8)
    stubArith
    pcAdvance

-- ---------------------------------------------------------------------------
-- Single-register instructions  ("1001_010d_dddd_XXXX", contiguous 5-bit d)
-- ---------------------------------------------------------------------------

-- | A single-register op given the 4-bit suffix and a transform of Rd.
oneRegOp :: AVR m pcW => String -> (IExpr 8 -> m (IExpr 8)) -> m ()
oneRegOp suf f = do
    d <- defineInstruction $ do
        fixed "1001010"; d <- field @(Unsigned 5); fixed suf; return d
    a <- readRegFileF avrGPR d
    writeRegFileF avrGPR d =<< f a
    stubArith
    pcAdvance

instrINC, instrCOM, instrNEG, instrASR, instrLSR, instrROR :: AVR m pcW => m ()
instrINC = mnemonic "INC" >> oneRegOp "0011" (\a -> litC 1 >>= aluOp PAdd a)
instrCOM = mnemonic "COM" >> oneRegOp "0000" (\a -> aluOp PNot a a)
instrNEG = mnemonic "NEG" >> oneRegOp "0001" (\a -> litC 0 >>= \z -> aluOp PSub z a)
instrASR = mnemonic "ASR" >> oneRegOp "0101" (\a -> litC 1 >>= aluOp PArithShiftR a)
instrLSR = mnemonic "LSR" >> oneRegOp "0110" (\a -> litC 1 >>= aluOp PShiftR a)
instrROR = mnemonic "ROR" >> oneRegOp "0111" (\a -> litC 1 >>= aluOp PShiftR a)

-- SWAP Rd — 1001_010d_dddd_0010
instrSWAP :: AVR m pcW => m ()
instrSWAP = do
    mnemonic "SWAP"
    d <- defineInstruction $ do
        fixed "1001010"; d <- field @(Unsigned 5); fixed "0010"; return d
    a   <- readRegFileF avrGPR d
    four <- litC 4
    hi  <- aluOp PShiftR a four
    lo  <- aluOp PShiftL a four
    writeRegFileF avrGPR d =<< aluOp POr hi lo
    pcAdvance

-- DEC Rd — 1001_010d_dddd_1010  (sets Z, clears the other arith flags)
instrDEC :: AVR m pcW => m ()
instrDEC = do
    mnemonic "DEC"
    d <- defineInstruction $ do
        fixed "1001010"; d <- field @(Unsigned 5); fixed "1010"; return d
    a   <- readRegFileF avrGPR d
    one <- litC 1
    r   <- aluOp PSub a one
    writeRegFileF avrGPR d r
    alu <- cpu id
    zf  <- isZero r
    setFlag (avrFlagZ alu) zf
    mapM_ setFlagLo [ avrFlagC alu, avrFlagN alu, avrFlagV alu
                    , avrFlagS alu, avrFlagH alu ]
    pcAdvance

-- ---------------------------------------------------------------------------
-- MULS — signed multiply upper regs — 0000_0010_dddd_rrrr  (d+16, r+16)
-- ---------------------------------------------------------------------------

instrMULS :: AVR m pcW => m ()
instrMULS = do
    mnemonic "MULS"
    (d, r) <- defineInstruction $ do
        fixed "00000010"; d <- field @(Unsigned 4); r <- field @(Unsigned 4); return (d, r)
    a <- readRegFileFOffset avrGPR d 16
    b <- readRegFileFOffset avrGPR r 16
    res <- aluOp PMulSigned a b
    let r0 = CPURegister "GPR:0" :: CPURegister (Unsigned 8)
        r1 = CPURegister "GPR:1" :: CPURegister (Unsigned 8)
    writeReg r0 res
    writeReg r1 res
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

wideImmOp :: AVR m pcW => String -> ALUPrim -> m ()
wideImmOp pre op = do
    (d, k) <- defineInstruction $ adiwEnc pre
    a <- readRegFileFOffset avrGPR d 24
    let k8 = zeroExtendC (immediateF k :: IExpr 6) :: IExpr 8   -- 6 <= 8
    writeRegFileFOffset avrGPR d 24 =<< aluOp op a k8
    stubArith
    pcAdvance

instrADIW, instrSBIW :: AVR m pcW => m ()
instrADIW = mnemonic "ADIW" >> wideImmOp "10010110" PAdd
instrSBIW = mnemonic "SBIW" >> wideImmOp "10010111" PSub
