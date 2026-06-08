{-# LANGUAGE AllowAmbiguousTypes #-}
module Core.ISA where

import Clash.Prelude

-- ---------------------------------------------------------------------------
-- Base ALU interface
-- ---------------------------------------------------------------------------

-- | Four-stage ALU interface. @state@ is the ISA's CPU state type;
--   instruction, address, and value types hang off it as associated types.
--
--   The four methods map directly to pipeline stages:
--     read    — what data RAM address to fetch before execute (if any)
--     compute — how the instruction transforms state (registers, flags)
--     write   — what data RAM address/value to store after execute (if any)
--     move    — where the PC goes next (Nothing = sequential)
class ALU state where
    type Instr   state
    type RamAddr state
    type RomAddr state
    type Val     state

    read    :: Instr state -> state -> Maybe (RamAddr state)
    compute :: Instr state -> Maybe (Val state) -> state -> state
    write   :: Instr state -> state -> Maybe (RamAddr state, Val state)
    move    :: Instr state -> state -> Maybe (RomAddr state)

-- ---------------------------------------------------------------------------
-- Extended pipeline qualities
-- ---------------------------------------------------------------------------

-- | Pipeline-visible qualities beyond the base ALU.
--   Covers instruction latency, multi-cycle ISA stages, and interrupts.
class ALU state => ISA state where
    type IsaStage state

    -- | Pipeline stages this instruction occupies. 1 = single-cycle.
    --   Use >1 for fixed-latency multi-cycle ops (MUL, barrel shift, etc.).
    --   The pipeline inserts latency-1 bubbles automatically.
    latency :: Instr state -> Int
    latency _ = 1

    -- | Dispatch to an ISA-specific multi-cycle stage when the generic
    --   pipeline cannot model the instruction (CALL, RET, LPM, etc.).
    --   Nothing means the generic path handles this instruction.
    toIsaStage :: Instr state -> state -> Maybe (IsaStage state)

    -- | Advance a running ISA-specific stage by one cycle.
    --   Left continues in the stage; Right () signals completion.
    isaStageStep
        :: IsaStage state
        -> (RomAddr state, Val state)   -- (code word, data RAM response)
        -> state
        -> (state, Either (IsaStage state) ())

    -- | True when the CPU can accept an interrupt at the next instruction
    --   boundary. Checked once per instruction boundary in the pipeline.
    interruptible :: state -> Bool

    -- | Accept a pending interrupt: apply any state side-effects (e.g. clear
    --   the IE flag) and optionally enter an ISA-specific stage to save the
    --   return address. Nothing means a direct jump with no save overhead.
    acceptIrq
        :: state
        -> RomAddr state
        -> (state, Maybe (IsaStage state))

-- ---------------------------------------------------------------------------
-- Flush
-- ---------------------------------------------------------------------------

-- | Every condition that causes the pipeline to discard in-flight instructions
--   and redirect the PC. First-class so events can be logged and tested
--   independently of the pipeline machinery that acts on them.
data FlushEvent romaddr
    = FlushBranch    romaddr    -- taken jump or branch
    | FlushInterrupt romaddr    -- interrupt accepted
    deriving (Generic, NFDataX, Show, Eq)

-- | A read-after-write memory hazard: an incoming load addresses a location
--   that an in-flight store has not yet committed. The pipeline holds the
--   load until the store completes.
newtype StallEvent ramaddr
    = StallReadAfterWrite ramaddr
    deriving (Generic, NFDataX, Show, Eq)

-- | Flush and stall condition detection, fully separated from the pipeline
--   mechanics that act on them.
--
--   Requires @Eq (RamAddr state)@ so addresses can be compared for the
--   read-after-write check.
--
--   Rule: both methods must depend only on *committed* instruction and
--   state — never on speculative in-flight pipeline state.
class (ISA state, Eq (RamAddr state)) => HasFlush state where

    -- | Default: flush iff @move@ is taken. ISAs with exceptions or other
    --   redirect causes override this.
    flushCondition
        :: Instr state
        -> state
        -> Maybe (FlushEvent (RomAddr state))
    flushCondition instr state = FlushBranch <$> move instr state

    -- | Default: stall iff write address exactly equals read address.
    --   ISAs with store forwarding, banked memory, or aliasing override this.
    stallCondition
        :: RamAddr state    -- pending write address
        -> RamAddr state    -- incoming read address
        -> Maybe (StallEvent (RamAddr state))
    stallCondition wa ra
        | wa == ra  = Just (StallReadAfterWrite ra)
        | otherwise = Nothing

-- ---------------------------------------------------------------------------
-- Pipeline slot
-- ---------------------------------------------------------------------------

-- | A single slot in the N-deep pipeline. Parameterised directly on the
--   instruction and stage types so the pipeline machinery does not need
--   an ISA constraint — only the ISA implementation does.
data Slot instr stage
    = SEmpty                -- bubble / no-op
    | SReady   instr        -- decoded, awaiting execute
    | SMemRead instr        -- stalled: data RAM response in flight
    | SIsa     stage        -- ISA-specific multi-cycle in progress
    deriving (Generic, NFDataX, Show, Eq)
