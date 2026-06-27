{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeApplications #-}
module AVR.ISA.BitOps where

import Prelude hiding (Word)

import Hdl.Bits hiding (zeroExtend, signExtend, truncateB, bitCoerce, slice)
import Isacle.ISA
import AVR.ISA.Types

-- ---------------------------------------------------------------------------
-- Bit manipulation: BSET, BCLR, BST, BLD
-- ---------------------------------------------------------------------------

-- BSET s — 1001_0100_0sss_1000
instrBSET :: AVR m pcW => m ()
instrBSET = do
    mnemonic "BSET"
    -- SREG[sss] := 1, where sss is a runtime field:  SREG <- SREG | (1 << sss)
    s <- defineInstruction $ do
        fixed "100101000"; s <- field @(Unsigned 3); fixed "1000"; return s
    sreg <- readField avrSREG
    one  <- litC 1
    mask <- aluOp PShiftL one (zeroExtendC (immediateF s :: IExpr 3) :: IExpr 8)
    writeField avrSREG =<< aluOp POr sreg mask
    pcAdvance

-- BCLR s — 1001_0100_1sss_1000
instrBCLR :: AVR m pcW => m ()
instrBCLR = do
    mnemonic "BCLR"
    -- SREG[sss] := 0:  SREG <- SREG & ~(1 << sss)
    s <- defineInstruction $ do
        fixed "100101001"; s <- field @(Unsigned 3); fixed "1000"; return s
    sreg    <- readField avrSREG
    one     <- litC 1
    mask    <- aluOp PShiftL one (zeroExtendC (immediateF s :: IExpr 3) :: IExpr 8)
    notMask <- aluOp PNot mask one        -- second operand ignored (PNot is unary)
    writeField avrSREG =<< aluOp PAnd sreg notMask
    pcAdvance

-- BST Rd, b — 1111_101d_dddd_0bbb
instrBST :: AVR m pcW => m ()
instrBST = do
    mnemonic "BST"
    d <- defineInstruction $ do
        fixed "1111101"; d <- field @(Unsigned 5); fixed "0"; _ <- field @(Unsigned 3); return d
    _v  <- readRegFileF avrGPR d
    alu <- cpu id
    -- Synthesis stub: set T to Lo (bit extraction not representable yet)
    setFlagLo (avrFlagT alu)
    pcAdvance

-- BLD Rd, b — 1111_100d_dddd_0bbb
instrBLD :: AVR m pcW => m ()
instrBLD = do
    mnemonic "BLD"
    d <- defineInstruction $ do
        fixed "1111100"; d <- field @(Unsigned 5); fixed "0"; _ <- field @(Unsigned 3); return d
    a <- readRegFileF avrGPR d
    -- Synthesis stub: write value unchanged (bit insert not representable yet)
    writeRegFileF avrGPR d a
    pcAdvance

-- ---------------------------------------------------------------------------
-- Skip-if-bit: SBRC, SBRS, SBIC, SBIS, CBI, SBI
-- Skip logic (PC+1 or PC+2) deferred; stub always advances by 1.
-- ---------------------------------------------------------------------------

-- SBRC Rr, b — 1111_110r_rrrr_0bbb
instrSBRC :: AVR m pcW => m ()
instrSBRC = do
    mnemonic "SBRC"
    r <- defineInstruction $ do
        fixed "1111110"; r <- field @(Unsigned 5); fixed "0"; _ <- field @(Unsigned 3); return r
    _v <- readRegFileF avrGPR r
    pcAdvance

-- SBRS Rr, b — 1111_111r_rrrr_0bbb
instrSBRS :: AVR m pcW => m ()
instrSBRS = do
    mnemonic "SBRS"
    r <- defineInstruction $ do
        fixed "1111111"; r <- field @(Unsigned 5); fixed "0"; _ <- field @(Unsigned 3); return r
    _v <- readRegFileF avrGPR r
    pcAdvance

-- CBI A, b — 1001_1000_AAAA_Abbb
instrCBI :: AVR m pcW => m ()
instrCBI = do
    mnemonic "CBI"
    a <- defineInstruction $ do
        fixed "10011000"; a <- field @(Unsigned 5); _ <- field @(Unsigned 3); return a
    ioBase <- litC 0x20
    addr <- aluOp PAdd (zeroExtendC (immediateF a :: IExpr 5) :: IExpr 16) ioBase
    v   <- readMem addr
    writeMem addr v
    pcAdvance

-- SBI A, b — 1001_1010_AAAA_Abbb
instrSBI :: AVR m pcW => m ()
instrSBI = do
    mnemonic "SBI"
    a <- defineInstruction $ do
        fixed "10011010"; a <- field @(Unsigned 5); _ <- field @(Unsigned 3); return a
    ioBase <- litC 0x20
    addr <- aluOp PAdd (zeroExtendC (immediateF a :: IExpr 5) :: IExpr 16) ioBase
    v   <- readMem addr
    writeMem addr v
    pcAdvance

-- SBIC A, b — 1001_1001_AAAA_Abbb
instrSBIC :: AVR m pcW => m ()
instrSBIC = do
    mnemonic "SBIC"
    a <- defineInstruction $ do
        fixed "10011001"; a <- field @(Unsigned 5); _ <- field @(Unsigned 3); return a
    ioBase <- litC 0x20
    addr <- aluOp PAdd (zeroExtendC (immediateF a :: IExpr 5) :: IExpr 16) ioBase
    _v   <- readMem addr
    pcAdvance

-- SBIS A, b — 1001_1011_AAAA_Abbb
instrSBIS :: AVR m pcW => m ()
instrSBIS = do
    mnemonic "SBIS"
    a <- defineInstruction $ do
        fixed "10011011"; a <- field @(Unsigned 5); _ <- field @(Unsigned 3); return a
    ioBase <- litC 0x20
    addr <- aluOp PAdd (zeroExtendC (immediateF a :: IExpr 5) :: IExpr 16) ioBase
    _v   <- readMem addr
    pcAdvance

-- ---------------------------------------------------------------------------
-- IN / OUT — I/O space access (I/O address + 0x20 = data address)
-- The 6-bit I/O address is split in the encoding (AA high, AAAA low), placed
-- with two 'slice's of one placeholder.
-- ---------------------------------------------------------------------------

-- IN Rd, A — 1011_0AAd_dddd_AAAA
instrIN :: AVR m pcW => m ()
instrIN = do
    mnemonic "IN"
    (d, a) <- defineInstruction $ do
        fixed "10110"
        a <- placeholder @(Unsigned 6)
        bindBits a 2                       -- AA: bits 10-9
        d <- field @(Unsigned 5)        -- d:  bits 8-4
        bindBits a 4                       -- AAAA: bits 3-0
        return (d, a)
    ioBase <- litC 0x20
    addr <- aluOp PAdd (zeroExtendC (immediateF a :: IExpr 6) :: IExpr 16) ioBase
    v    <- readMem addr
    writeRegFileF avrGPR d v
    pcAdvance

-- OUT A, Rr — 1011_1AAr_rrrr_AAAA
instrOUT :: AVR m pcW => m ()
instrOUT = do
    mnemonic "OUT"
    (r, a) <- defineInstruction $ do
        fixed "10111"
        a <- placeholder @(Unsigned 6)
        bindBits a 2                       -- AA: bits 10-9
        r <- field @(Unsigned 5)        -- r:  bits 8-4
        bindBits a 4                       -- AAAA: bits 3-0
        return (r, a)
    ioBase <- litC 0x20
    addr <- aluOp PAdd (zeroExtendC (immediateF a :: IExpr 6) :: IExpr 16) ioBase
    v    <- readRegFileF avrGPR r
    writeMem addr v
    pcAdvance
