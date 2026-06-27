{-# LANGUAGE DataKinds #-}
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
    encoding "1001_0100_0sss_1000"
    -- SREG[sss] := 1, where sss is a runtime field:  SREG <- SREG | (1 << sss)
    s     <- immediate "sss"
    sregR <- cpu avrSREG
    sreg  <- readReg sregR
    one   <- litC 1
    mask  <- aluOp PShiftL one (zeroExtendC (s :: IExpr 3) :: IExpr 8)
    writeReg sregR =<< aluOp POr sreg mask
    pcAdvance

-- BCLR s — 1001_0100_1sss_1000
instrBCLR :: AVR m pcW => m ()
instrBCLR = do
    mnemonic "BCLR"
    encoding "1001_0100_1sss_1000"
    -- SREG[sss] := 0:  SREG <- SREG & ~(1 << sss)
    s       <- immediate "sss"
    sregR   <- cpu avrSREG
    sreg    <- readReg sregR
    one     <- litC 1
    mask    <- aluOp PShiftL one (zeroExtendC (s :: IExpr 3) :: IExpr 8)
    notMask <- aluOp PNot mask one        -- second operand ignored (PNot is unary)
    writeReg sregR =<< aluOp PAnd sreg notMask
    pcAdvance

-- BST Rd, b — 1111_101d_dddd_0bbb
instrBST :: AVR m pcW => m ()
instrBST = do
    mnemonic "BST"
    encoding "1111_101d_dddd_0bbb"
    src <- register avrGPR "ddddd"
    _v  <- readReg src
    alu <- cpu id
    -- Synthesis stub: set T to Lo (bit extraction not representable yet)
    setFlagLo (avrFlagT alu)
    pcAdvance

-- BLD Rd, b — 1111_100d_dddd_0bbb
instrBLD :: AVR m pcW => m ()
instrBLD = do
    mnemonic "BLD"
    encoding "1111_100d_dddd_0bbb"
    dst <- register avrGPR "ddddd"
    a   <- readReg dst
    -- Synthesis stub: write value unchanged (bit insert not representable yet)
    writeReg dst a
    pcAdvance

-- ---------------------------------------------------------------------------
-- Skip-if-bit: SBRC, SBRS, SBIC, SBIS, CBI, SBI
-- Skip logic (PC+1 or PC+2) deferred; stub always advances by 1.
-- ---------------------------------------------------------------------------

-- SBRC Rr, b — 1111_110r_rrrr_0bbb
instrSBRC :: AVR m pcW => m ()
instrSBRC = do
    mnemonic "SBRC"
    encoding "1111_110r_rrrr_0bbb"
    src <- register avrGPR "rrrrr"
    _v  <- readReg src
    pcAdvance

-- SBRS Rr, b — 1111_111r_rrrr_0bbb
instrSBRS :: AVR m pcW => m ()
instrSBRS = do
    mnemonic "SBRS"
    encoding "1111_111r_rrrr_0bbb"
    src <- register avrGPR "rrrrr"
    _v  <- readReg src
    pcAdvance

-- CBI A, b — 1001_1000_AAAA_Abbb
instrCBI :: AVR m pcW => m ()
instrCBI = do
    mnemonic "CBI"
    encoding "1001_1000_AAAA_Abbb"
    a   <- immediate "AAAAA"
    ioBase <- litC 0x20
    addr <- aluOp PAdd (zeroExtendC (a :: IExpr 5) :: IExpr 16) ioBase
    v   <- readMem addr
    writeMem addr v
    pcAdvance

-- SBI A, b — 1001_1010_AAAA_Abbb
instrSBI :: AVR m pcW => m ()
instrSBI = do
    mnemonic "SBI"
    encoding "1001_1010_AAAA_Abbb"
    a   <- immediate "AAAAA"
    ioBase <- litC 0x20
    addr <- aluOp PAdd (zeroExtendC (a :: IExpr 5) :: IExpr 16) ioBase
    v   <- readMem addr
    writeMem addr v
    pcAdvance

-- SBIC A, b — 1001_1001_AAAA_Abbb
instrSBIC :: AVR m pcW => m ()
instrSBIC = do
    mnemonic "SBIC"
    encoding "1001_1001_AAAA_Abbb"
    a    <- immediate "AAAAA"
    ioBase <- litC 0x20
    addr <- aluOp PAdd (zeroExtendC (a :: IExpr 5) :: IExpr 16) ioBase
    _v   <- readMem addr
    pcAdvance

-- SBIS A, b — 1001_1011_AAAA_Abbb
instrSBIS :: AVR m pcW => m ()
instrSBIS = do
    mnemonic "SBIS"
    encoding "1001_1011_AAAA_Abbb"
    a    <- immediate "AAAAA"
    ioBase <- litC 0x20
    addr <- aluOp PAdd (zeroExtendC (a :: IExpr 5) :: IExpr 16) ioBase
    _v   <- readMem addr
    pcAdvance

-- ---------------------------------------------------------------------------
-- IN / OUT — I/O space access (I/O address + 0x20 = data address)
-- ---------------------------------------------------------------------------

-- IN Rd, A — 1011_0AAd_dddd_AAAA
instrIN :: AVR m pcW => m ()
instrIN = do
    mnemonic "IN"
    encoding "1011_0AAd_dddd_AAAA"
    dst  <- register avrGPR "ddddd"
    a    <- immediate "AAAAAA"
    ioBase <- litC 0x20
    addr <- aluOp PAdd (zeroExtendC (a :: IExpr 6) :: IExpr 16) ioBase
    v    <- readMem addr
    writeReg dst v
    pcAdvance

-- OUT A, Rr — 1011_1AAr_rrrr_AAAA
instrOUT :: AVR m pcW => m ()
instrOUT = do
    mnemonic "OUT"
    encoding "1011_1AAr_rrrr_AAAA"
    src  <- register avrGPR "rrrrr"
    a    <- immediate "AAAAAA"
    ioBase <- litC 0x20
    addr <- aluOp PAdd (zeroExtendC (a :: IExpr 6) :: IExpr 16) ioBase
    v    <- readReg src
    writeMem addr v
    pcAdvance
