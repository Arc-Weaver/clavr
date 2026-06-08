module AVR.Core where

import Clash.Prelude
import AVR.InstructionSet (Instruction, instrWords, decodeInstruction)

type AVRWord  = Unsigned 8
type AVRAddr  = Unsigned 16
type AVRXAddr = Unsigned 24  -- 24-bit byte address for ELPM/RAMPZ

data StatusRegister = StatusReg
    { carry_flag     :: Bit  -- SREG bit 0
    , zero_flag      :: Bit  -- SREG bit 1
    , negative_flag  :: Bit  -- SREG bit 2
    , overflow_flag  :: Bit  -- SREG bit 3
    , sign_flag      :: Bit  -- SREG bit 4
    , half_carry     :: Bit  -- SREG bit 5
    , bit_copy       :: Bit  -- SREG bit 6
    , interrupt_flag :: Bit  -- SREG bit 7
    } deriving (Generic, NFDataX, Show, Eq)

instance BitPack StatusRegister where
    type BitSize StatusRegister = 8
    pack   = pack . statusToWord
    unpack = wordToStatus . unpack

statusToWord :: StatusRegister -> AVRWord
statusToWord sr =
    let bits = pack (interrupt_flag sr)  -- bit 7 MSB
            ++# pack (bit_copy sr)       -- bit 6
            ++# pack (half_carry sr)     -- bit 5
            ++# pack (sign_flag sr)      -- bit 4
            ++# pack (overflow_flag sr)  -- bit 3
            ++# pack (negative_flag sr)  -- bit 2
            ++# pack (zero_flag sr)      -- bit 1
            ++# pack (carry_flag sr)     -- bit 0 LSB
            :: BitVector 8
    in unpack bits

wordToStatus :: AVRWord -> StatusRegister
wordToStatus w =
    let bits = pack w :: BitVector 8
    in StatusReg
        { carry_flag     = unpack (slice d0 d0 bits)
        , zero_flag      = unpack (slice d1 d1 bits)
        , negative_flag  = unpack (slice d2 d2 bits)
        , overflow_flag  = unpack (slice d3 d3 bits)
        , sign_flag      = unpack (slice d4 d4 bits)
        , half_carry     = unpack (slice d5 d5 bits)
        , bit_copy       = unpack (slice d6 d6 bits)
        , interrupt_flag = unpack (slice d7 d7 bits)
        }

-- | CPU register file and special-purpose registers.
--
--   pcBits is the word-address width of the program counter:
--     16 → devices with ≤128KB flash  (e.g. ATmega328P)
--     22 → devices with ≤8MB flash    (e.g. ATmega2560, XMEGA)
data CoreData (pcBits :: Nat) = CoreData
    { registers :: Vec 32 AVRWord
    , sp        :: AVRAddr
    , pc        :: Unsigned pcBits
    , rampd     :: AVRWord
    , rampx     :: AVRWord
    , rampy     :: AVRWord
    , rampz     :: AVRWord
    , eind      :: AVRWord
    , status    :: StatusRegister
    } deriving (Generic, NFDataX, Show)

type SmallAVR = CoreData 16  -- ATmega328P, ATtiny88, etc.
type LargeAVR = CoreData 22  -- ATmega2560, XMEGA, etc.

-- | All-zeros reset state; suitable as a starting point for simulation.
zeroState :: KnownNat pcBits => CoreData pcBits
zeroState = CoreData
    { registers = repeat 0
    , sp        = 0
    , pc        = 0
    , rampd     = 0, rampx = 0, rampy = 0, rampz = 0, eind = 0
    , status    = StatusReg { carry_flag = 0, zero_flag = 0, negative_flag = 0
                            , overflow_flag = 0, sign_flag = 0, half_carry = 0
                            , bit_copy = 0, interrupt_flag = 0 }
    }

-- ---------------------------------------------------------------------------
-- Instruction fetch/decode pipeline
-- ---------------------------------------------------------------------------

-- | Decode pipeline state. Handles the 4 two-word instructions
--   (CALL, JMP, LDS, STS) by stashing the first word until the second arrives.
data DecodeState = AwaitFirst | AwaitSecond (BitVector 16)
    deriving (Generic, NFDataX, Show, Eq)

-- | One pipeline step: consume one 16-bit word from code memory.
--
--   First word: decode zero-padded. instrWords on the result determines
--   whether a second word is needed — no separate pre-decoder required.
--
--   Second word (if needed): decode the full 32-bit instruction.
--
--   Returns Nothing on the stall cycle between the two words of a
--   2-word instruction.
decodeStep :: DecodeState -> BitVector 16 -> (DecodeState, Maybe Instruction)
decodeStep AwaitFirst w0 =
    let partial = decodeInstruction (w0 ++# (0 :: BitVector 16))
    in if instrWords partial == 1
       then (AwaitFirst,      Just partial)
       else (AwaitSecond w0,  Nothing)
decodeStep (AwaitSecond w0) w1 =
    (AwaitFirst, Just (decodeInstruction (w0 ++# w1)))

-- | Mealy machine wrapping decodeStep.
--   Input:  stream of 16-bit words from code memory (one per clock).
--   Output: Nothing while waiting for the second word of a 2-word instruction,
--           Just instr when a complete instruction has been decoded.
instructionDecoder
    :: HiddenClockResetEnable dom
    => Signal dom (BitVector 16)
    -> Signal dom (Maybe Instruction)
instructionDecoder = mealy decodeStep AwaitFirst
