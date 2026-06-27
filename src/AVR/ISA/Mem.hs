{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeApplications #-}
module AVR.ISA.Mem where

import Prelude hiding (Word)

import Hdl.Bits hiding (zeroExtend, signExtend, truncateB, bitCoerce, slice)
import Isacle.ISA
import AVR.ISA.Types

-- ---------------------------------------------------------------------------
-- LD / ST — indirect memory access via X, Y, Z pointer registers
-- ---------------------------------------------------------------------------

-- LD Rd, Z — 1000_000d_dddd_0000
instrLD_Z :: AVR m pcW => m ()
instrLD_Z = do
    mnemonic "LD_Z"
    d <- defineInstruction $ do
        fixed "1000000"
        d <- placeholder @(Unsigned 5)   -- the Rd field, typed, 5 bits
        bind d
        fixed "0000"
        return d
    ptr <- readField avrZ
    v   <- readMem ptr
    writeRegFileF avrGPR d v             -- index the file with the field, no string
    pcAdvance

-- LD Rd, Z+ — 1001_000d_dddd_0001
instrLD_Zplus :: AVR m pcW => m ()
instrLD_Zplus = do
    mnemonic "LD_Zplus"
    encoding "1001_000d_dddd_0001"
    dst  <- register avrGPR "ddddd"
    ptr  <- readField avrZ
    v    <- readMem ptr
    writeReg dst v
    one <- litC 1
    ptr1 <- aluOp PAdd ptr one
    writeField avrZ ptr1
    pcAdvance

-- LD Rd, -Z — 1001_000d_dddd_0010
instrLD_Zminus :: AVR m pcW => m ()
instrLD_Zminus = do
    mnemonic "LD_Zminus"
    encoding "1001_000d_dddd_0010"
    dst  <- register avrGPR "ddddd"
    ptr  <- readField avrZ
    one <- litC 1
    ptr1 <- aluOp PSub ptr one
    writeField avrZ ptr1
    v    <- readMem ptr1
    writeReg dst v
    pcAdvance

-- LD Rd, Y — 1000_000d_dddd_1000
instrLD_Y :: AVR m pcW => m ()
instrLD_Y = do
    mnemonic "LD_Y"
    encoding "1000_000d_dddd_1000"
    dst  <- register avrGPR "ddddd"
    ptr  <- readField avrY
    v    <- readMem ptr
    writeReg dst v
    pcAdvance

-- LD Rd, Y+ — 1001_000d_dddd_1001
instrLD_Yplus :: AVR m pcW => m ()
instrLD_Yplus = do
    mnemonic "LD_Yplus"
    encoding "1001_000d_dddd_1001"
    dst  <- register avrGPR "ddddd"
    ptr  <- readField avrY
    v    <- readMem ptr
    writeReg dst v
    one <- litC 1
    ptr1 <- aluOp PAdd ptr one
    writeField avrY ptr1
    pcAdvance

-- LD Rd, -Y — 1001_000d_dddd_1010
instrLD_Yminus :: AVR m pcW => m ()
instrLD_Yminus = do
    mnemonic "LD_Yminus"
    encoding "1001_000d_dddd_1010"
    dst  <- register avrGPR "ddddd"
    ptr  <- readField avrY
    one <- litC 1
    ptr1 <- aluOp PSub ptr one
    writeField avrY ptr1
    v    <- readMem ptr1
    writeReg dst v
    pcAdvance

-- LD Rd, X — 1001_000d_dddd_1100
instrLD_X :: AVR m pcW => m ()
instrLD_X = do
    mnemonic "LD_X"
    encoding "1001_000d_dddd_1100"
    dst  <- register avrGPR "ddddd"
    ptr  <- readField avrX
    v    <- readMem ptr
    writeReg dst v
    pcAdvance

-- LD Rd, X+ — 1001_000d_dddd_1101
instrLD_Xplus :: AVR m pcW => m ()
instrLD_Xplus = do
    mnemonic "LD_Xplus"
    encoding "1001_000d_dddd_1101"
    dst  <- register avrGPR "ddddd"
    ptr  <- readField avrX
    v    <- readMem ptr
    writeReg dst v
    one <- litC 1
    ptr1 <- aluOp PAdd ptr one
    writeField avrX ptr1
    pcAdvance

-- LD Rd, -X — 1001_000d_dddd_1110
instrLD_Xminus :: AVR m pcW => m ()
instrLD_Xminus = do
    mnemonic "LD_Xminus"
    encoding "1001_000d_dddd_1110"
    dst  <- register avrGPR "ddddd"
    ptr  <- readField avrX
    one <- litC 1
    ptr1 <- aluOp PSub ptr one
    writeField avrX ptr1
    v    <- readMem ptr1
    writeReg dst v
    pcAdvance

-- ST Z, Rr — 1000_001r_rrrr_0000
instrST_Z :: AVR m pcW => m ()
instrST_Z = do
    mnemonic "ST_Z"
    encoding "1000_001r_rrrr_0000"
    src  <- register avrGPR "rrrrr"
    ptr  <- readField avrZ
    v    <- readReg src
    writeMem ptr v
    pcAdvance

-- ST Z+, Rr — 1001_001r_rrrr_0001
instrST_Zplus :: AVR m pcW => m ()
instrST_Zplus = do
    mnemonic "ST_Zplus"
    encoding "1001_001r_rrrr_0001"
    src  <- register avrGPR "rrrrr"
    ptr  <- readField avrZ
    v    <- readReg src
    writeMem ptr v
    one <- litC 1
    ptr1 <- aluOp PAdd ptr one
    writeField avrZ ptr1
    pcAdvance

-- ST -Z, Rr — 1001_001r_rrrr_0010
instrST_Zminus :: AVR m pcW => m ()
instrST_Zminus = do
    mnemonic "ST_Zminus"
    encoding "1001_001r_rrrr_0010"
    src  <- register avrGPR "rrrrr"
    ptr  <- readField avrZ
    one <- litC 1
    ptr1 <- aluOp PSub ptr one
    writeField avrZ ptr1
    v    <- readReg src
    writeMem ptr1 v
    pcAdvance

-- ST Y, Rr — 1000_001r_rrrr_1000
instrST_Y :: AVR m pcW => m ()
instrST_Y = do
    mnemonic "ST_Y"
    encoding "1000_001r_rrrr_1000"
    src  <- register avrGPR "rrrrr"
    ptr  <- readField avrY
    v    <- readReg src
    writeMem ptr v
    pcAdvance

-- ST Y+, Rr — 1001_001r_rrrr_1001
instrST_Yplus :: AVR m pcW => m ()
instrST_Yplus = do
    mnemonic "ST_Yplus"
    encoding "1001_001r_rrrr_1001"
    src  <- register avrGPR "rrrrr"
    ptr  <- readField avrY
    v    <- readReg src
    writeMem ptr v
    one <- litC 1
    ptr1 <- aluOp PAdd ptr one
    writeField avrY ptr1
    pcAdvance

-- ST -Y, Rr — 1001_001r_rrrr_1010
instrST_Yminus :: AVR m pcW => m ()
instrST_Yminus = do
    mnemonic "ST_Yminus"
    encoding "1001_001r_rrrr_1010"
    src  <- register avrGPR "rrrrr"
    ptr  <- readField avrY
    one <- litC 1
    ptr1 <- aluOp PSub ptr one
    writeField avrY ptr1
    v    <- readReg src
    writeMem ptr1 v
    pcAdvance

-- ST X, Rr — 1001_001r_rrrr_1100
instrST_X :: AVR m pcW => m ()
instrST_X = do
    mnemonic "ST_X"
    encoding "1001_001r_rrrr_1100"
    src  <- register avrGPR "rrrrr"
    ptr  <- readField avrX
    v    <- readReg src
    writeMem ptr v
    pcAdvance

-- ST X+, Rr — 1001_001r_rrrr_1101
instrST_Xplus :: AVR m pcW => m ()
instrST_Xplus = do
    mnemonic "ST_Xplus"
    encoding "1001_001r_rrrr_1101"
    src  <- register avrGPR "rrrrr"
    ptr  <- readField avrX
    v    <- readReg src
    writeMem ptr v
    one <- litC 1
    ptr1 <- aluOp PAdd ptr one
    writeField avrX ptr1
    pcAdvance

-- ST -X, Rr — 1001_001r_rrrr_1110
instrST_Xminus :: AVR m pcW => m ()
instrST_Xminus = do
    mnemonic "ST_Xminus"
    encoding "1001_001r_rrrr_1110"
    src  <- register avrGPR "rrrrr"
    ptr  <- readField avrX
    one <- litC 1
    ptr1 <- aluOp PSub ptr one
    writeField avrX ptr1
    v    <- readReg src
    writeMem ptr1 v
    pcAdvance

-- ---------------------------------------------------------------------------
-- 32-bit instructions — word 2 loaded via readCode at current PC.
-- ---------------------------------------------------------------------------

-- LDS Rd, k — 1001_000d_dddd_0000 + 16-bit data address word
instrLDS :: AVR m pcW => m ()
instrLDS = do
    mnemonic "LDS"
    encoding "1001_000d_dddd_0000"
    dst  <- register avrGPR "ddddd"
    pcR  <- cpu avrPC
    p    <- readReg pcR
    addr <- readCode p
    one  <- litC 1
    p1   <- aluOp PAdd p one
    writeReg pcR =<< aluOp PAdd p1 one   -- skip opcode word AND address word
    v    <- readMem addr
    writeReg dst v

-- STS k, Rr — 1001_001r_rrrr_0000 + 16-bit data address word
instrSTS :: AVR m pcW => m ()
instrSTS = do
    mnemonic "STS"
    encoding "1001_001r_rrrr_0000"
    src  <- register avrGPR "rrrrr"
    pcR  <- cpu avrPC
    p    <- readReg pcR
    addr <- readCode p
    one  <- litC 1
    p1   <- aluOp PAdd p one
    writeReg pcR =<< aluOp PAdd p1 one   -- skip opcode word AND address word
    v    <- readReg src
    writeMem addr v
