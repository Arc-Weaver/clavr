{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UndecidableInstances #-}
{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE FlexibleContexts #-}
module AVR.ISA.Types
    ( AVRALU(..)
    , Sreg(..)
    , AvrState(..)
    , avrCPUDef
    , AVR
    , avrFlagAt
    , setFlagHi, setFlagLo
    , stubArith
    , pcAdvance
    ) where

import Prelude hiding (Word)
import GHC.Generics (Generic, Rep)

import Hdl.Bits hiding ((!!), zeroExtend, signExtend, truncateB, bitCoerce, slice)
import Hdl.Types (HdlType(..), GWidth, genericToBits, genericFromBits)
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
-- SREG as a bit-map record HdlType
-- The status register's bit layout *is* this record's structure: declaration
-- order is MSB-first, so sI occupies bit 7 … sC bit 0 (the AVR SREG layout).
-- 'flagRec' derives each flag's bit position from it — no separate bit-index
-- declaration (C2/C5).
-- ---------------------------------------------------------------------------

data Sreg = Sreg
    { sI :: Bit   -- ^ bit 7 — global interrupt enable
    , sT :: Bit   -- ^ bit 6 — bit copy / transfer
    , sH :: Bit   -- ^ bit 5 — half carry
    , sS :: Bit   -- ^ bit 4 — sign (N xor V)
    , sV :: Bit   -- ^ bit 3 — two's-complement overflow
    , sN :: Bit   -- ^ bit 2 — negative
    , sZ :: Bit   -- ^ bit 1 — zero
    , sC :: Bit   -- ^ bit 0 — carry
    } deriving Generic

instance HdlType Sreg where
    type Width Sreg = GWidth (Rep Sreg)
    toBits   = genericToBits
    fromBits = genericFromBits

-- ---------------------------------------------------------------------------
-- AVR architectural state as one HdlType record (C1: "core satisfies HdlType")
--
-- The whole core state is a record whose every field is itself an 'HdlType':
-- the register file is a 'Vec' array (H4), the pointers/SP are 'Unsigned',
-- the PC is 'Unsigned pcW' (its width is the field's 'Width' — length-by-default,
-- so no free pcW thread), and SREG is the bit-map record above (C2). Core,
-- registers and bit-maps are the *same* HdlType mechanism, recursively.
--
-- This is the structural view the eventual full reframe builds on; the
-- instruction-access machinery (AVRALU handles) still drives synthesis today.
-- ---------------------------------------------------------------------------

data AvrState pcW = AvrState
    { gpr  :: Vec 32 (Unsigned 8)   -- ^ R0..R31
    , sp   :: Unsigned 16           -- ^ stack pointer
    , x    :: Unsigned 16           -- ^ X pointer (R27:R26)
    , y    :: Unsigned 16           -- ^ Y pointer (R29:R28)
    , z    :: Unsigned 16           -- ^ Z pointer (R31:R30)
    , pc   :: Unsigned pcW          -- ^ program counter (width = field Width)
    , sreg :: Sreg                  -- ^ status register (bit-map record)
    } deriving Generic

instance (KnownNat pcW, KnownNat (GWidth (Rep (AvrState pcW))))
      => HdlType (AvrState pcW) where
    type Width (AvrState pcW) = GWidth (Rep (AvrState pcW))
    toBits   = genericToBits
    fromBits = genericFromBits

-- | The AVR core's handle record stands for the typed 'AvrState' record, so
-- 'readField'/'writeField' (from "Isacle.ISA") reach a scalar register by its
-- 'AvrState' field name with the width taken from the field's type.
--
-- > sreg <- readField @"sreg"          -- IExpr 8  (from the Sreg field)
-- > writeField @"pc" newPc             -- width = pcW (the pc field's width)
type instance CoreState (AVRALU pcW) = AvrState pcW

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
    -- SREG and its flags derive from the Sreg record layout (MSB-first):
    -- fs = [sI@7, sT@6, sH@5, sS@4, sV@3, sN@2, sZ@1, sC@0].
    (sreg, fs) <- flagRec @Sreg "SREG"
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
                 , Word m ~ IExpr 8, DataAddr m ~ IExpr 16
                 , CodeAddr m ~ IExpr pcW, CodeWord m ~ IExpr 16 )

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
