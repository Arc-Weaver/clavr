{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE DataKinds #-}
module AVR.ISA.Arith where

import Prelude hiding (Word)

import Hdl.Bits hiding (zeroExtend, signExtend, truncateB, bitCoerce, slice)
import Isacle.ISA
import Isacle.ISA.Types (CPURegister(..))
import AVR.ISA.Types

-- ---------------------------------------------------------------------------
-- Two-register arithmetic/logical instructions
-- Encoding pattern: "00XX_XXrd_dddd_rrrr"  (d=5-bit, r=5-bit)
-- ---------------------------------------------------------------------------

-- ADD Rd, Rr — 0000_11rd_dddd_rrrr
instrADD :: AVR m pcW => m ()
instrADD = do
    mnemonic "ADD"
    encoding "0000_11rd_dddd_rrrr"
    dst <- register avrGPR "ddddd"
    src <- register avrGPR "rrrrr"
    a   <- readReg dst
    b   <- readReg src
    r   <- aluOp PAdd a b
    writeReg dst r
    stubArith
    pcAdvance

-- ADC Rd, Rr — 0001_11rd_dddd_rrrr
instrADC :: AVR m pcW => m ()
instrADC = do
    mnemonic "ADC"
    encoding "0001_11rd_dddd_rrrr"
    dst <- register avrGPR "ddddd"
    src <- register avrGPR "rrrrr"
    a   <- readReg dst
    b   <- readReg src
    r   <- aluOp PAdd a b
    writeReg dst r
    stubArith
    pcAdvance

-- SUB Rd, Rr — 0001_10rd_dddd_rrrr
instrSUB :: AVR m pcW => m ()
instrSUB = do
    mnemonic "SUB"
    encoding "0001_10rd_dddd_rrrr"
    dst <- register avrGPR "ddddd"
    src <- register avrGPR "rrrrr"
    a   <- readReg dst
    b   <- readReg src
    r   <- aluOp PSub a b
    writeReg dst r
    stubArith
    pcAdvance

-- SBC Rd, Rr — 0000_10rd_dddd_rrrr
instrSBC :: AVR m pcW => m ()
instrSBC = do
    mnemonic "SBC"
    encoding "0000_10rd_dddd_rrrr"
    dst <- register avrGPR "ddddd"
    src <- register avrGPR "rrrrr"
    a   <- readReg dst
    b   <- readReg src
    r   <- aluOp PSub a b
    writeReg dst r
    stubArith
    pcAdvance

-- AND Rd, Rr — 0010_00rd_dddd_rrrr
instrAND :: AVR m pcW => m ()
instrAND = do
    mnemonic "AND"
    encoding "0010_00rd_dddd_rrrr"
    dst <- register avrGPR "ddddd"
    src <- register avrGPR "rrrrr"
    a   <- readReg dst
    b   <- readReg src
    r   <- aluOp PAnd a b
    writeReg dst r
    stubArith
    pcAdvance

-- OR Rd, Rr — 0010_10rd_dddd_rrrr
instrOR :: AVR m pcW => m ()
instrOR = do
    mnemonic "OR"
    encoding "0010_10rd_dddd_rrrr"
    dst <- register avrGPR "ddddd"
    src <- register avrGPR "rrrrr"
    a   <- readReg dst
    b   <- readReg src
    r   <- aluOp POr a b
    writeReg dst r
    stubArith
    pcAdvance

-- EOR Rd, Rr — 0010_01rd_dddd_rrrr
instrEOR :: AVR m pcW => m ()
instrEOR = do
    mnemonic "EOR"
    encoding "0010_01rd_dddd_rrrr"
    dst <- register avrGPR "ddddd"
    src <- register avrGPR "rrrrr"
    a   <- readReg dst
    b   <- readReg src
    r   <- aluOp PXor a b
    writeReg dst r
    stubArith
    pcAdvance

-- MOV Rd, Rr — 0010_11rd_dddd_rrrr
instrMOV :: AVR m pcW => m ()
instrMOV = do
    mnemonic "MOV"
    encoding "0010_11rd_dddd_rrrr"
    dst <- register avrGPR "ddddd"
    src <- register avrGPR "rrrrr"
    v   <- readReg src
    writeReg dst v
    pcAdvance

-- CP Rd, Rr — 0001_01rd_dddd_rrrr
instrCP :: AVR m pcW => m ()
instrCP = do
    mnemonic "CP"
    encoding "0001_01rd_dddd_rrrr"
    dst <- register avrGPR "ddddd"
    src <- register avrGPR "rrrrr"
    a   <- readReg dst
    b   <- readReg src
    _r  <- aluOp PSub a b
    stubArith
    pcAdvance

-- CPC Rd, Rr — 0000_01rd_dddd_rrrr
instrCPC :: AVR m pcW => m ()
instrCPC = do
    mnemonic "CPC"
    encoding "0000_01rd_dddd_rrrr"
    dst <- register avrGPR "ddddd"
    src <- register avrGPR "rrrrr"
    a   <- readReg dst
    b   <- readReg src
    _r  <- aluOp PSub a b
    stubArith
    pcAdvance

-- CPSE Rd, Rr — 0001_00rd_dddd_rrrr  (skip if equal; stub: always advance 1)
instrCPSE :: AVR m pcW => m ()
instrCPSE = do
    mnemonic "CPSE"
    encoding "0001_00rd_dddd_rrrr"
    dst <- register avrGPR "ddddd"
    src <- register avrGPR "rrrrr"
    a   <- readReg dst
    b   <- readReg src
    _r  <- aluOp PSub a b
    stubArith
    pcAdvance

-- MUL Rd, Rr — 1001_11rd_dddd_rrrr
instrMUL :: AVR m pcW => m ()
instrMUL = do
    mnemonic "MUL"
    encoding "1001_11rd_dddd_rrrr"
    dst <- register avrGPR "ddddd"
    src <- register avrGPR "rrrrr"
    a   <- readReg dst
    b   <- readReg src
    r   <- aluOp PMul a b
    let r0 = CPURegister "GPR:0"  :: CPURegister 8
        r1 = CPURegister "GPR:1"  :: CPURegister 8
    writeReg r0 r
    writeReg r1 r
    stubArith
    pcAdvance

-- ---------------------------------------------------------------------------
-- Upper-register + 8-bit immediate instructions
-- Encoding pattern: "XXXX_KKKK_dddd_KKKK"  (d=4-bit+16, K=8-bit)
-- ---------------------------------------------------------------------------

-- LDI Rd, K — 1110_KKKK_dddd_KKKK
instrLDI :: AVR m pcW => m ()
instrLDI = do
    mnemonic "LDI"
    encoding "1110_KKKK_dddd_KKKK"
    dst <- registerWithOffset avrGPR "dddd" 16
    k   <- immediate "KKKKKKKK"
    writeReg dst (k :: IExpr 8)
    pcAdvance

-- SUBI Rd, K — 0101_KKKK_dddd_KKKK
instrSUBI :: AVR m pcW => m ()
instrSUBI = do
    mnemonic "SUBI"
    encoding "0101_KKKK_dddd_KKKK"
    dst <- registerWithOffset avrGPR "dddd" 16
    k   <- immediate "KKKKKKKK"
    a   <- readReg dst
    r   <- aluOp PSub a (k :: IExpr 8)
    writeReg dst r
    stubArith
    pcAdvance

-- SBCI Rd, K — 0100_KKKK_dddd_KKKK
instrSBCI :: AVR m pcW => m ()
instrSBCI = do
    mnemonic "SBCI"
    encoding "0100_KKKK_dddd_KKKK"
    dst <- registerWithOffset avrGPR "dddd" 16
    k   <- immediate "KKKKKKKK"
    a   <- readReg dst
    r   <- aluOp PSub a (k :: IExpr 8)
    writeReg dst r
    stubArith
    pcAdvance

-- ANDI Rd, K — 0111_KKKK_dddd_KKKK
instrANDI :: AVR m pcW => m ()
instrANDI = do
    mnemonic "ANDI"
    encoding "0111_KKKK_dddd_KKKK"
    dst <- registerWithOffset avrGPR "dddd" 16
    k   <- immediate "KKKKKKKK"
    a   <- readReg dst
    r   <- aluOp PAnd a (k :: IExpr 8)
    writeReg dst r
    stubArith
    pcAdvance

-- ORI Rd, K — 0110_KKKK_dddd_KKKK
instrORI :: AVR m pcW => m ()
instrORI = do
    mnemonic "ORI"
    encoding "0110_KKKK_dddd_KKKK"
    dst <- registerWithOffset avrGPR "dddd" 16
    k   <- immediate "KKKKKKKK"
    a   <- readReg dst
    r   <- aluOp POr a (k :: IExpr 8)
    writeReg dst r
    stubArith
    pcAdvance

-- CPI Rd, K — 0011_KKKK_dddd_KKKK
instrCPI :: AVR m pcW => m ()
instrCPI = do
    mnemonic "CPI"
    encoding "0011_KKKK_dddd_KKKK"
    dst <- registerWithOffset avrGPR "dddd" 16
    k   <- immediate "KKKKKKKK"
    a   <- readReg dst
    _r  <- aluOp PSub a (k :: IExpr 8)
    stubArith
    pcAdvance

-- ---------------------------------------------------------------------------
-- Single-register instructions
-- Encoding pattern: "1001_010d_dddd_XXXX"  (d=5-bit)
-- ---------------------------------------------------------------------------

-- INC Rd — 1001_010d_dddd_0011
instrINC :: AVR m pcW => m ()
instrINC = do
    mnemonic "INC"
    encoding "1001_010d_dddd_0011"
    dst <- register avrGPR "ddddd"
    a   <- readReg dst
    one <- litC 1
    r   <- aluOp PAdd a one
    writeReg dst r
    stubArith
    pcAdvance

-- DEC Rd — 1001_010d_dddd_1010
instrDEC :: AVR m pcW => m ()
instrDEC = do
    mnemonic "DEC"
    encoding "1001_010d_dddd_1010"
    dst <- register avrGPR "ddddd"
    a   <- readReg dst
    one <- litC 1
    r   <- aluOp PSub a one
    writeReg dst r
    alu <- cpu id
    zf  <- isZero r
    setFlag (avrFlagZ alu) zf
    mapM_ setFlagLo [ avrFlagC alu, avrFlagN alu, avrFlagV alu
                    , avrFlagS alu, avrFlagH alu ]
    pcAdvance

-- COM Rd — 1001_010d_dddd_0000
instrCOM :: AVR m pcW => m ()
instrCOM = do
    mnemonic "COM"
    encoding "1001_010d_dddd_0000"
    dst <- register avrGPR "ddddd"
    a   <- readReg dst
    r   <- aluOp PNot a a
    writeReg dst r
    stubArith
    pcAdvance

-- NEG Rd — 1001_010d_dddd_0001
instrNEG :: AVR m pcW => m ()
instrNEG = do
    mnemonic "NEG"
    encoding "1001_010d_dddd_0001"
    dst <- register avrGPR "ddddd"
    a   <- readReg dst
    zero <- litC 0
    r   <- aluOp PSub zero a
    writeReg dst r
    stubArith
    pcAdvance

-- ASR Rd — 1001_010d_dddd_0101
instrASR :: AVR m pcW => m ()
instrASR = do
    mnemonic "ASR"
    encoding "1001_010d_dddd_0101"
    dst <- register avrGPR "ddddd"
    a   <- readReg dst
    one <- litC 1
    r   <- aluOp PArithShiftR a one
    writeReg dst r
    stubArith
    pcAdvance

-- LSR Rd — 1001_010d_dddd_0110
instrLSR :: AVR m pcW => m ()
instrLSR = do
    mnemonic "LSR"
    encoding "1001_010d_dddd_0110"
    dst <- register avrGPR "ddddd"
    a   <- readReg dst
    one <- litC 1
    r   <- aluOp PShiftR a one
    writeReg dst r
    stubArith
    pcAdvance

-- ROR Rd — 1001_010d_dddd_0111
instrROR :: AVR m pcW => m ()
instrROR = do
    mnemonic "ROR"
    encoding "1001_010d_dddd_0111"
    dst <- register avrGPR "ddddd"
    a   <- readReg dst
    one <- litC 1
    r   <- aluOp PShiftR a one
    writeReg dst r
    stubArith
    pcAdvance

-- SWAP Rd — 1001_010d_dddd_0010
instrSWAP :: AVR m pcW => m ()
instrSWAP = do
    mnemonic "SWAP"
    encoding "1001_010d_dddd_0010"
    dst <- register avrGPR "ddddd"
    a   <- readReg dst
    four <- litC 4
    hi  <- aluOp PShiftR a four
    lo  <- aluOp PShiftL a four
    r   <- aluOp POr hi lo
    writeReg dst r
    pcAdvance

-- ---------------------------------------------------------------------------
-- MULS — signed multiply upper regs
-- Encoding: 0000_0010_dddd_rrrr  (d+16, r+16)
-- ---------------------------------------------------------------------------

instrMULS :: AVR m pcW => m ()
instrMULS = do
    mnemonic "MULS"
    encoding "0000_0010_dddd_rrrr"
    dst <- registerWithOffset avrGPR "dddd" 16
    src <- registerWithOffset avrGPR "rrrr" 16
    a   <- readReg dst
    b   <- readReg src
    r   <- aluOp PMulSigned a b
    let r0 = CPURegister "GPR:0" :: CPURegister 8
        r1 = CPURegister "GPR:1" :: CPURegister 8
    writeReg r0 r
    writeReg r1 r
    stubArith
    pcAdvance

-- ---------------------------------------------------------------------------
-- ADIW / SBIW — wide immediate add/sub on register pairs
-- Encoding: 1001_011X_KKdd_KKKK  (X=0 ADIW, X=1 SBIW; d=2-bit pair selector)
-- For synthesis: operate on lo byte of the pair at 24+2*d, stub hi.
-- ---------------------------------------------------------------------------

instrADIW :: AVR m pcW => m ()
instrADIW = do
    mnemonic "ADIW"
    encoding "1001_0110_KKdd_KKKK"
    lo  <- registerWithOffset avrGPR "dd" 24
    k   <- immediate "KKKKKK"
    a   <- readReg lo
    r   <- aluOp PAdd a (k :: IExpr 8)
    writeReg lo r
    stubArith
    pcAdvance

instrSBIW :: AVR m pcW => m ()
instrSBIW = do
    mnemonic "SBIW"
    encoding "1001_0111_KKdd_KKKK"
    lo  <- registerWithOffset avrGPR "dd" 24
    k   <- immediate "KKKKKK"
    a   <- readReg lo
    r   <- aluOp PSub a (k :: IExpr 8)
    writeReg lo r
    stubArith
    pcAdvance
