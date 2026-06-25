{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE DataKinds #-}
module AVR.ISA.Types
    ( AVRALU(..)
    , avrCPUDef
    , AVR
    , avrFlagAt
    , setFlagHi, setFlagLo
    , stubArith
    , pcAdvance
    ) where

import Prelude hiding (Word)

import Hdl.Bits hiding ((!!))
import Isacle.ISA
import Isacle.ISA.Types (CPURegister(..))

-- ---------------------------------------------------------------------------
-- AVR ALU definition record
-- pcW — width of the program counter in bits (16 for ≤32K flash, 22 for larger)
-- ---------------------------------------------------------------------------

data AVRALU pcW = AVRALU
    { avrGPR   :: CPURegFile 32 8
    , avrSP    :: CPURegister 16
    , avrPC    :: CPURegister pcW
    , avrX     :: CPURegister 16    -- data pointer (R27:R26)
    , avrY     :: CPURegister 16    -- data pointer (R29:R28)
    , avrZ     :: CPURegister 16    -- data pointer (R31:R30)
    , avrSREG  :: CPURegister 8     -- packed status register (read-only)
    , avrFlagC :: CPUFlag
    , avrFlagZ :: CPUFlag
    , avrFlagN :: CPUFlag
    , avrFlagV :: CPUFlag
    , avrFlagS :: CPUFlag
    , avrFlagH :: CPUFlag
    , avrFlagT :: CPUFlag
    , avrFlagI :: CPUFlag
    }

-- ---------------------------------------------------------------------------
-- CPUDef — parameterised over PC width via TypeApplications
-- Usage: avrCPUDef @16  or  avrCPUDef @22
-- ---------------------------------------------------------------------------

avrCPUDef :: forall pcW. KnownNat pcW => CPUDef (AVRALU pcW)
avrCPUDef = do
    endianness LittleEndian
    gpr'    <- regFile "GPR" (width @32) byte
    sp'     <- reg "SP"  w16
    pc'     <- reg "PC"  (SNat @pcW)
    x'      <- reg "X"   w16
    y'      <- reg "Y"   w16
    z'      <- reg "Z"   w16
    (sreg, fs) <- flagPack @8 "SREG" ["I","T","H","S","V","N","Z","C"]
    let i = fs!!0; t = fs!!1; h = fs!!2; s = fs!!3
        v = fs!!4; n = fs!!5; z = fs!!6; c = fs!!7
    aliasFile gpr' "0x00 + regIndex"
    aliasReg  sp'  0x5D
    aliasReg  sreg 0x5F
    pure AVRALU
        { avrGPR   = gpr'
        , avrSP    = sp'
        , avrPC    = pc'
        , avrX     = x'
        , avrY     = y'
        , avrZ     = z'
        , avrSREG  = sreg
        , avrFlagC = c
        , avrFlagZ = z
        , avrFlagN = n
        , avrFlagV = v
        , avrFlagS = s
        , avrFlagH = h
        , avrFlagT = t
        , avrFlagI = i
        }

-- ---------------------------------------------------------------------------
-- Constraint alias
-- pcW pins the PC width; CodeAddr and the PC register share the same width.
-- ---------------------------------------------------------------------------

type AVR m pcW = ( MonadHarvardALU m, AluDef m ~ AVRALU pcW
                 , KnownNat pcW
                 , Word m ~ Unsigned 8, DataAddr m ~ Unsigned 16
                 , CodeAddr m ~ Unsigned pcW, CodeWord m ~ Unsigned 16 )

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

-- | Map a 3-bit SREG bit index (0=C .. 7=I) to the corresponding CPUFlag.
avrFlagAt :: AVRALU pcW -> Int -> CPUFlag
avrFlagAt alu 0 = avrFlagC alu
avrFlagAt alu 1 = avrFlagZ alu
avrFlagAt alu 2 = avrFlagN alu
avrFlagAt alu 3 = avrFlagV alu
avrFlagAt alu 4 = avrFlagS alu
avrFlagAt alu 5 = avrFlagH alu
avrFlagAt alu 6 = avrFlagT alu
avrFlagAt alu _ = avrFlagI alu

-- | Set a flag to a compile-time constant via a proper literal wire.
setFlagHi, setFlagLo :: AVR m pcW => CPUFlag -> m ()
setFlagHi f = do { v <- litC 1; setFlag f v }
setFlagLo f = do { v <- litC 0; setFlag f v }

-- | Stub all 6 arithmetic flags to Lo (synthesis placeholder).
stubArith :: AVR m pcW => m ()
stubArith = do
    alu <- cpu id
    mapM_ setFlagLo
        [ avrFlagC alu, avrFlagZ alu, avrFlagN alu
        , avrFlagV alu, avrFlagS alu, avrFlagH alu ]

-- | Advance PC by one instruction word.
pcAdvance :: AVR m pcW => m ()
pcAdvance = do
    pcR <- cpu avrPC
    p   <- readReg pcR
    one <- litC 1
    writeReg pcR =<< aluOp PAdd p one
