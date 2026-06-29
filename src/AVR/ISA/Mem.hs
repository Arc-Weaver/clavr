{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeApplications #-}
module AVR.ISA.Mem where

import Prelude hiding (Word)

import Hdl.Bits hiding (zeroExtend, signExtend, truncateB, bitCoerce, slice, add, mul)
import Isacle.ISA
import AVR.ISA.Types

-- ---------------------------------------------------------------------------
-- LD / ST — indirect memory access via X, Y, Z pointer registers
--
-- Encodings are built with the field DSL: 'fixed' opcode bits and a typed
-- 'field' placeholder for the Rd/Rr register index (5 bits), which is then the
-- index into 'avrGPR' — no register handle, no field-name string.
-- ---------------------------------------------------------------------------

-- LD Rd, Z — 1000_000d_dddd_0000
instrLD_Z :: AVR m pcW => m ()
instrLD_Z = do
    mnemonic "LD_Z"
    d <- defineInstruction $ do
        fixed "1000000"; d <- field @(Unsigned 5); fixed "0000"; return d
    ptr <- readField avrZ
    v   <- readMem ptr
    writeRegFileF avrGPR d v
    pcAdvance

-- LD Rd, Z+ — 1001_000d_dddd_0001
instrLD_Zplus :: AVR m pcW => m ()
instrLD_Zplus = do
    mnemonic "LD_Zplus"
    d <- defineInstruction $ do
        fixed "1001000"; d <- field @(Unsigned 5); fixed "0001"; return d
    ptr  <- readField avrZ
    v    <- readMem ptr
    writeRegFileF avrGPR d v
    one  <- litC 1
    writeField avrZ (ptr + one)
    pcAdvance

-- LD Rd, -Z — 1001_000d_dddd_0010
instrLD_Zminus :: AVR m pcW => m ()
instrLD_Zminus = do
    mnemonic "LD_Zminus"
    d <- defineInstruction $ do
        fixed "1001000"; d <- field @(Unsigned 5); fixed "0010"; return d
    ptr  <- readField avrZ
    one  <- litC 1
    let ptr1 = ptr - one
    writeField avrZ ptr1
    v    <- readMem ptr1
    writeRegFileF avrGPR d v
    pcAdvance

-- LD Rd, Y — 1000_000d_dddd_1000
instrLD_Y :: AVR m pcW => m ()
instrLD_Y = do
    mnemonic "LD_Y"
    d <- defineInstruction $ do
        fixed "1000000"; d <- field @(Unsigned 5); fixed "1000"; return d
    ptr <- readField avrY
    v   <- readMem ptr
    writeRegFileF avrGPR d v
    pcAdvance

-- LD Rd, Y+ — 1001_000d_dddd_1001
instrLD_Yplus :: AVR m pcW => m ()
instrLD_Yplus = do
    mnemonic "LD_Yplus"
    d <- defineInstruction $ do
        fixed "1001000"; d <- field @(Unsigned 5); fixed "1001"; return d
    ptr <- readField avrY
    v   <- readMem ptr
    writeRegFileF avrGPR d v
    one <- litC 1
    writeField avrY (ptr + one)
    pcAdvance

-- LD Rd, -Y — 1001_000d_dddd_1010
instrLD_Yminus :: AVR m pcW => m ()
instrLD_Yminus = do
    mnemonic "LD_Yminus"
    d <- defineInstruction $ do
        fixed "1001000"; d <- field @(Unsigned 5); fixed "1010"; return d
    ptr  <- readField avrY
    one  <- litC 1
    let ptr1 = ptr - one
    writeField avrY ptr1
    v    <- readMem ptr1
    writeRegFileF avrGPR d v
    pcAdvance

-- LD Rd, X — 1001_000d_dddd_1100
instrLD_X :: AVR m pcW => m ()
instrLD_X = do
    mnemonic "LD_X"
    d <- defineInstruction $ do
        fixed "1001000"; d <- field @(Unsigned 5); fixed "1100"; return d
    ptr <- readField avrX
    v   <- readMem ptr
    writeRegFileF avrGPR d v
    pcAdvance

-- LD Rd, X+ — 1001_000d_dddd_1101
instrLD_Xplus :: AVR m pcW => m ()
instrLD_Xplus = do
    mnemonic "LD_Xplus"
    d <- defineInstruction $ do
        fixed "1001000"; d <- field @(Unsigned 5); fixed "1101"; return d
    ptr <- readField avrX
    v   <- readMem ptr
    writeRegFileF avrGPR d v
    one <- litC 1
    writeField avrX (ptr + one)
    pcAdvance

-- LD Rd, -X — 1001_000d_dddd_1110
instrLD_Xminus :: AVR m pcW => m ()
instrLD_Xminus = do
    mnemonic "LD_Xminus"
    d <- defineInstruction $ do
        fixed "1001000"; d <- field @(Unsigned 5); fixed "1110"; return d
    ptr  <- readField avrX
    one  <- litC 1
    let ptr1 = ptr - one
    writeField avrX ptr1
    v    <- readMem ptr1
    writeRegFileF avrGPR d v
    pcAdvance

-- ST Z, Rr — 1000_001r_rrrr_0000
instrST_Z :: AVR m pcW => m ()
instrST_Z = do
    mnemonic "ST_Z"
    r <- defineInstruction $ do
        fixed "1000001"; r <- field @(Unsigned 5); fixed "0000"; return r
    ptr <- readField avrZ
    v   <- readRegFileF avrGPR r
    writeMem ptr v
    pcAdvance

-- ST Z+, Rr — 1001_001r_rrrr_0001
instrST_Zplus :: AVR m pcW => m ()
instrST_Zplus = do
    mnemonic "ST_Zplus"
    r <- defineInstruction $ do
        fixed "1001001"; r <- field @(Unsigned 5); fixed "0001"; return r
    ptr <- readField avrZ
    v   <- readRegFileF avrGPR r
    writeMem ptr v
    one <- litC 1
    writeField avrZ (ptr + one)
    pcAdvance

-- ST -Z, Rr — 1001_001r_rrrr_0010
instrST_Zminus :: AVR m pcW => m ()
instrST_Zminus = do
    mnemonic "ST_Zminus"
    r <- defineInstruction $ do
        fixed "1001001"; r <- field @(Unsigned 5); fixed "0010"; return r
    ptr  <- readField avrZ
    one  <- litC 1
    let ptr1 = ptr - one
    writeField avrZ ptr1
    v    <- readRegFileF avrGPR r
    writeMem ptr1 v
    pcAdvance

-- ST Y, Rr — 1000_001r_rrrr_1000
instrST_Y :: AVR m pcW => m ()
instrST_Y = do
    mnemonic "ST_Y"
    r <- defineInstruction $ do
        fixed "1000001"; r <- field @(Unsigned 5); fixed "1000"; return r
    ptr <- readField avrY
    v   <- readRegFileF avrGPR r
    writeMem ptr v
    pcAdvance

-- ST Y+, Rr — 1001_001r_rrrr_1001
instrST_Yplus :: AVR m pcW => m ()
instrST_Yplus = do
    mnemonic "ST_Yplus"
    r <- defineInstruction $ do
        fixed "1001001"; r <- field @(Unsigned 5); fixed "1001"; return r
    ptr <- readField avrY
    v   <- readRegFileF avrGPR r
    writeMem ptr v
    one <- litC 1
    writeField avrY (ptr + one)
    pcAdvance

-- ST -Y, Rr — 1001_001r_rrrr_1010
instrST_Yminus :: AVR m pcW => m ()
instrST_Yminus = do
    mnemonic "ST_Yminus"
    r <- defineInstruction $ do
        fixed "1001001"; r <- field @(Unsigned 5); fixed "1010"; return r
    ptr  <- readField avrY
    one  <- litC 1
    let ptr1 = ptr - one
    writeField avrY ptr1
    v    <- readRegFileF avrGPR r
    writeMem ptr1 v
    pcAdvance

-- ST X, Rr — 1001_001r_rrrr_1100
instrST_X :: AVR m pcW => m ()
instrST_X = do
    mnemonic "ST_X"
    r <- defineInstruction $ do
        fixed "1001001"; r <- field @(Unsigned 5); fixed "1100"; return r
    ptr <- readField avrX
    v   <- readRegFileF avrGPR r
    writeMem ptr v
    pcAdvance

-- ST X+, Rr — 1001_001r_rrrr_1101
instrST_Xplus :: AVR m pcW => m ()
instrST_Xplus = do
    mnemonic "ST_Xplus"
    r <- defineInstruction $ do
        fixed "1001001"; r <- field @(Unsigned 5); fixed "1101"; return r
    ptr <- readField avrX
    v   <- readRegFileF avrGPR r
    writeMem ptr v
    one <- litC 1
    writeField avrX (ptr + one)
    pcAdvance

-- ST -X, Rr — 1001_001r_rrrr_1110
instrST_Xminus :: AVR m pcW => m ()
instrST_Xminus = do
    mnemonic "ST_Xminus"
    r <- defineInstruction $ do
        fixed "1001001"; r <- field @(Unsigned 5); fixed "1110"; return r
    ptr  <- readField avrX
    one  <- litC 1
    let ptr1 = ptr - one
    writeField avrX ptr1
    v    <- readRegFileF avrGPR r
    writeMem ptr1 v
    pcAdvance

-- ---------------------------------------------------------------------------
-- 32-bit instructions — word 2 loaded via readCode at current PC.
-- ---------------------------------------------------------------------------

-- LDS Rd, k — 1001_000d_dddd_0000 + 16-bit data address word
instrLDS :: AVR m pcW => m ()
instrLDS = do
    mnemonic "LDS"
    d <- defineInstruction $ do
        fixed "1001000"; d <- field @(Unsigned 5); fixed "0000"; return d
    p    <- readField avrPC
    addr <- readCode p
    one  <- litC 1
    let p1 = p + one
    writeField avrPC (p1 + one)   -- skip opcode word AND address word
    v    <- readMem addr
    writeRegFileF avrGPR d v

-- STS k, Rr — 1001_001r_rrrr_0000 + 16-bit data address word
instrSTS :: AVR m pcW => m ()
instrSTS = do
    mnemonic "STS"
    r <- defineInstruction $ do
        fixed "1001001"; r <- field @(Unsigned 5); fixed "0000"; return r
    p    <- readField avrPC
    addr <- readCode p
    one  <- litC 1
    let p1 = p + one
    writeField avrPC (p1 + one)
    v    <- readRegFileF avrGPR r
    writeMem addr v
