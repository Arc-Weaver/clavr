{-# LANGUAGE DataKinds #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
module AVR.ISA.Branch where

import Prelude hiding (Word)

import Hdl.Bits hiding (zeroExtend, signExtend, truncateB, bitCoerce, slice)
import Isacle.ISA
import AVR.ISA.Types

-- ---------------------------------------------------------------------------
-- Stack: PUSH, POP
-- ---------------------------------------------------------------------------

-- PUSH Rr — 1001_001d_dddd_1111
instrPUSH :: AVR m pcW => m ()
instrPUSH = do
    mnemonic "PUSH"
    encoding "1001_001d_dddd_1111"
    src  <- register avrGPR "ddddd"
    spR  <- cpu avrSP
    spV  <- readReg spR
    val  <- readReg src
    writeMem spV val
    one  <- litC 1
    writeReg spR =<< aluOp PSub spV one
    pcAdvance

-- POP Rd — 1001_000d_dddd_1111
instrPOP :: AVR m pcW => m ()
instrPOP = do
    mnemonic "POP"
    encoding "1001_000d_dddd_1111"
    dst  <- register avrGPR "ddddd"
    spR  <- cpu avrSP
    spV  <- readReg spR
    one  <- litC 1
    newSp <- aluOp PAdd spV one
    writeReg spR newSp
    writeReg dst =<< readMem newSp
    pcAdvance

-- ---------------------------------------------------------------------------
-- Stack helpers shared by CALL/RET instructions
-- ---------------------------------------------------------------------------

-- | Push a pcW-wide return address onto the stack (hi byte first, AVR convention).
pushRetAddr :: AVR m pcW => IExpr pcW -> m ()
pushRetAddr ret = do
    spR   <- cpu avrSP
    spV   <- readReg spR
    eight <- litC 8
    retHi <- aluOp PShiftR (zeroExtend ret :: IExpr 16) eight
    writeMem spV (truncateC retHi :: IExpr 8)   -- 8 <= 16, statically checked
    one   <- litC 1
    spV1  <- aluOp PSub spV one
    writeMem spV1 (truncateB ret :: IExpr 8)
    spV2  <- aluOp PSub spV1 one
    writeReg spR spV2

-- | Pop a 16-bit return address from the stack and jump to it.
retFromStack :: AVR m pcW => m ()
retFromStack = do
    spR  <- cpu avrSP
    spV  <- readReg spR
    one  <- litC 1
    spV1 <- aluOp PAdd spV one
    lo   <- readMem spV1
    spV2 <- aluOp PAdd spV1 one
    hi   <- readMem spV2
    writeReg spR spV2
    eight <- litC 8
    hiW   <- aluOp PShiftL (zeroExtendC hi :: IExpr 16) eight   -- Word m ~ IExpr 8, 8 <= 16
    ret   <- aluOp POr (zeroExtendC lo :: IExpr 16) hiW
    pcR   <- cpu avrPC
    writeReg pcR (zeroExtend ret)

-- ---------------------------------------------------------------------------
-- Relative branches
-- These compute the full target PC = (PC+1) + k, so no separate pcAdvance.
-- ---------------------------------------------------------------------------

-- RJMP k — 1100_kkkk_kkkk_kkkk  (12-bit signed offset)
-- target = (PC+1) + sign_extend(k); the offset must be sign-extended so backward
-- jumps (negative k) work — see BRBS/BRBC below for the same pattern.
instrRJMP :: forall m pcW. AVR m pcW => m ()
instrRJMP = do
    mnemonic "RJMP"
    encoding "1100_kkkk_kkkk_kkkk"
    pcR <- cpu avrPC
    p   <- readReg pcR
    k12 <- (immediate "kkkkkkkkkkkk" :: m (IExpr 12))
    one <- litC 1
    p1  <- aluOp PAdd p one
    k   <- signExtendBits k12
    writeReg pcR =<< aluOp PAdd p1 k

-- RCALL k — 1101_kkkk_kkkk_kkkk  (12-bit signed offset, sign-extended)
instrRCALL :: forall m pcW. AVR m pcW => m ()
instrRCALL = do
    mnemonic "RCALL"
    encoding "1101_kkkk_kkkk_kkkk"
    pcR <- cpu avrPC
    p   <- readReg pcR
    k12 <- (immediate "kkkkkkkkkkkk" :: m (IExpr 12))
    one <- litC 1
    ret <- aluOp PAdd p one
    pushRetAddr ret
    k   <- signExtendBits k12
    writeReg pcR =<< aluOp PAdd ret k

-- RET — 1001_0101_0000_1000
instrRET :: AVR m pcW => m ()
instrRET = do
    mnemonic "RET"
    encoding "1001_0101_0000_1000"
    retFromStack

-- RETI — 1001_0101_0001_1000
instrRETI :: AVR m pcW => m ()
instrRETI = do
    mnemonic "RETI"
    encoding "1001_0101_0001_1000"
    retFromStack
    alu <- cpu id
    setFlagHi (avrFlagI alu)

-- ---------------------------------------------------------------------------
-- Conditional relative branches — BRBS / BRBC
-- Encoding: 1111_00kk_kkkk_ksss (BRBS) / 1111_01kk_kkkk_ksss (BRBC)
-- sss = 3-bit SREG bit index: 0=C 1=Z 2=N 3=V 4=S 5=H 6=T 7=I
-- target = (PC+1) + sign_extend(k)
--
-- Read SREG, shift right by sss, mask bit 0: that is the selected flag.
-- BRBS branches when the flag is set; BRBC when it is clear.
-- ---------------------------------------------------------------------------

instrBRBS :: forall m pcW. AVR m pcW => m ()
instrBRBS = do
    mnemonic "BRBS"
    encoding "1111_00kk_kkkk_ksss"
    pcR    <- cpu avrPC
    p      <- readReg pcR
    k7     <- (immediate "kkkkkkk" :: m (IExpr 7))
    pcOne  <- litC 1
    p1     <- aluOp PAdd p pcOne
    k      <- signExtendBits k7
    target <- aluOp PAdd p1 k
    sss    <- (immediate "sss" :: m (IExpr 3))
    sregR  <- cpu avrSREG
    sreg   <- readReg sregR
    let sss8 = zeroExtendC sss :: IExpr 8   -- 3 <= 8, statically checked
    shifted <- aluOp PShiftR sreg sss8
    one8    <- litC 1
    masked  <- aluOp PAnd shifted one8
    cond    <- isZero =<< isZero masked   -- 1 when flag is set
    absJumpIf pcR cond target

instrBRBC :: forall m pcW. AVR m pcW => m ()
instrBRBC = do
    mnemonic "BRBC"
    encoding "1111_01kk_kkkk_ksss"
    pcR    <- cpu avrPC
    p      <- readReg pcR
    k7     <- (immediate "kkkkkkk" :: m (IExpr 7))
    pcOne  <- litC 1
    p1     <- aluOp PAdd p pcOne
    k      <- signExtendBits k7
    target <- aluOp PAdd p1 k
    sss    <- (immediate "sss" :: m (IExpr 3))
    sregR  <- cpu avrSREG
    sreg   <- readReg sregR
    let sss8 = zeroExtendC sss :: IExpr 8   -- 3 <= 8, statically checked
    shifted <- aluOp PShiftR sreg sss8
    one8    <- litC 1
    masked  <- aluOp PAnd shifted one8
    cond    <- isZero masked              -- 1 when flag is clear
    absJumpIf pcR cond target

-- Named aliases — kept for documentation; same encodings as BRBS/BRBC with fixed sss bits.
-- Not included in avrCoreInstrs (BRBS/BRBC subsume them all).
instrBREQ, instrBRNE :: AVR m pcW => m ()
instrBRCS, instrBRCC :: AVR m pcW => m ()
instrBRMI, instrBRPL :: AVR m pcW => m ()
instrBRVS, instrBRVC :: AVR m pcW => m ()
instrBRLT, instrBRGE :: AVR m pcW => m ()
instrBRHS, instrBRHC :: AVR m pcW => m ()
instrBRTS, instrBRTC :: AVR m pcW => m ()
instrBRIE, instrBRID :: AVR m pcW => m ()
instrBRLO, instrBRSH :: AVR m pcW => m ()
instrBREQ = instrBRBS; instrBRNE = instrBRBC
instrBRCS = instrBRBS; instrBRCC = instrBRBC
instrBRMI = instrBRBS; instrBRPL = instrBRBC
instrBRVS = instrBRBS; instrBRVC = instrBRBC
instrBRLT = instrBRBS; instrBRGE = instrBRBC
instrBRHS = instrBRBS; instrBRHC = instrBRBC
instrBRTS = instrBRBS; instrBRTC = instrBRBC
instrBRIE = instrBRBS; instrBRID = instrBRBC
instrBRLO = instrBRBS; instrBRSH = instrBRBC

-- ---------------------------------------------------------------------------
-- Absolute / indirect control flow + misc
-- ---------------------------------------------------------------------------

-- IJMP — 1001_0100_0000_1001
instrIJMP :: AVR m pcW => m ()
instrIJMP = do
    mnemonic "IJMP"
    encoding "1001_0100_0000_1001"
    pcR <- cpu avrPC
    zr  <- cpu avrZ
    writeReg pcR . zeroExtend =<< readReg zr

-- ICALL — 1001_0101_0000_1001
instrICALL :: AVR m pcW => m ()
instrICALL = do
    mnemonic "ICALL"
    encoding "1001_0101_0000_1001"
    pcR  <- cpu avrPC
    p    <- readReg pcR
    one  <- litC 1
    ret  <- aluOp PAdd p one
    pushRetAddr ret
    zr   <- cpu avrZ
    writeReg pcR . zeroExtend =<< readReg zr

-- NOP — 0000_0000_0000_0000
instrNOP :: AVR m pcW => m ()
instrNOP = do
    mnemonic "NOP"
    encoding "0000_0000_0000_0000"
    pcAdvance

-- ---------------------------------------------------------------------------
-- 32-bit (two-word) control flow
-- ---------------------------------------------------------------------------

-- JMP k — 1001_010k_kkkk_110k + 16-bit target word
instrJMP :: AVR m pcW => m ()
instrJMP = do
    mnemonic "JMP"
    encoding "1001_010k_kkkk_110k"
    pcR <- cpu avrPC
    p   <- readReg pcR
    tgt <- readCode p
    writeReg pcR (zeroExtend tgt)

-- CALL k — 1001_010k_kkkk_111k + 16-bit target word
instrCALL :: AVR m pcW => m ()
instrCALL = do
    mnemonic "CALL"
    encoding "1001_010k_kkkk_111k"
    pcR  <- cpu avrPC
    p    <- readReg pcR
    tgt  <- readCode p
    one  <- litC 1
    p1   <- aluOp PAdd p one
    ret  <- aluOp PAdd p1 one        -- return address = after both words (p+2)
    pushRetAddr ret
    writeReg pcR (zeroExtend tgt)

-- MOVW Rd+1:Rd, Rr+1:Rr — 0000_0001_dddd_rrrr  (stub: copy lo register)
instrMOVW :: AVR m pcW => m ()
instrMOVW = do
    mnemonic "MOVW"
    encoding "0000_0001_dddd_rrrr"
    dst <- register avrGPR "dddd"
    src <- register avrGPR "rrrr"
    writeReg dst =<< readReg src
    pcAdvance
