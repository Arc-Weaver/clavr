module Tests.Core.Pipeline where

import Prelude hiding (read, repeat, (!!))

import Test.Tasty
import Test.Tasty.TH
import Test.Tasty.Hedgehog
import qualified Hedgehog as H

import qualified Clash.Prelude as C

import Core.ISA
import Core.Pipeline

import Tests.Core.ISA
    ( TState(..), TInstr(..), TIsaStage(..)
    , initState, withZero, setReg, getReg
    )

-- ---------------------------------------------------------------------------
-- 2-slot pipeline helpers
-- ---------------------------------------------------------------------------

type P1 = PipeState 1 TInstr TIsaStage

emptyP1 :: P1
emptyP1 = emptyPipe

step1 :: P1 -> TState -> PipeInput TState -> (P1, TState, PipeOutput TState)
step1 = pipelineStep

noInp :: PipeInput TState
noInp = PipeInput Nothing Nothing Nothing

withInstr :: TInstr -> PipeInput TState
withInstr i = PipeInput (Just i) Nothing Nothing

-- | Feed an instruction into the 2-slot pipeline and advance it to the
--   execute head (slot 0).  The result is ready for the actual execute step.
primeExec :: TInstr -> TState -> (P1, TState)
primeExec instr s =
    let (ps1, s1, _) = step1 emptyP1 s  (withInstr instr)
        (ps2, s2, _) = step1 ps1     s1 noInp
    in (ps2, s2)

-- ---------------------------------------------------------------------------
-- Bubble behaviour
-- ---------------------------------------------------------------------------

prop_empty_pipe_no_output :: H.Property
prop_empty_pipe_no_output = H.withTests 1 . H.property $ do
    let (_, _, out) = step1 emptyP1 initState noInp
    pipeMemRead  out H.=== Nothing
    pipeMemWrite out H.=== Nothing
    pipeFlush    out H.=== Nothing
    pipeStalled  out H.=== False

-- An instruction fed into an empty pipeline enters at the tail (slot 1), not
-- the head (slot 0) — it needs one more advance before execution.
prop_bubble_accepts_new_instruction :: H.Property
prop_bubble_accepts_new_instruction = H.withTests 1 . H.property $ do
    let (ps', _, _) = step1 emptyP1 initState (withInstr TNop)
    C.head (psSlots ps') H.=== SEmpty
    (psSlots ps' C.!! (1 :: C.Index 2)) H.=== SReady TNop

-- ---------------------------------------------------------------------------
-- Single-cycle execution
-- ---------------------------------------------------------------------------

prop_nop_executes_and_advances :: H.Property
prop_nop_executes_and_advances = H.withTests 1 . H.property $ do
    let (ps0, s0) = primeExec TNop initState    -- TNop now at slot 0
    let (ps1, s1, out) = step1 ps0 s0 noInp    -- execute
    s1           H.=== initState
    pipeFlush out H.=== Nothing
    pipeStalled out H.=== False
    C.head (psSlots ps1) H.=== SEmpty

prop_add_updates_register :: H.Property
prop_add_updates_register = H.withTests 1 . H.property $ do
    let s0 = setReg 0 3 (setReg 1 4 initState)
    let (ps0, s0') = primeExec (TAdd 0 1) s0
    let (_, s1, _) = step1 ps0 s0' noInp
    getReg 0 s1 H.=== 7

prop_jump_flushes_pipeline :: H.Property
prop_jump_flushes_pipeline = H.withTests 1 . H.property $ do
    let (ps0, s0) = primeExec (TJump 0x42) initState
    let (ps1, _, out) = step1 ps0 s0 noInp
    pipeFlush    out H.=== Just (FlushBranch 0x42)
    pipeStalled  out H.=== False
    psSlots ps1 H.=== C.repeat SEmpty

-- ---------------------------------------------------------------------------
-- Memory read (load)
-- ---------------------------------------------------------------------------

prop_load_issues_read_request :: H.Property
prop_load_issues_read_request = H.withTests 1 . H.property $ do
    let (ps0, s0)      = primeExec (TLoad 0 0x10) initState
    let (ps1, _, out)  = step1 ps0 s0 noInp
    pipeMemRead out H.=== Just 0x10
    pipeStalled out H.=== True
    C.head (psSlots ps1) H.=== SMemRead (TLoad 0 0x10)

prop_load_stalls_without_response :: H.Property
prop_load_stalls_without_response = H.withTests 1 . H.property $ do
    let (ps0, s0) = primeExec (TLoad 0 0x10) initState
    let (ps1, s1, _)  = step1 ps0 s0 noInp   -- issues read
    let (ps2, _, out) = step1 ps1 s1 noInp   -- no response yet
    pipeStalled out H.=== True
    C.head (psSlots ps2) H.=== SMemRead (TLoad 0 0x10)

prop_load_completes_with_response :: H.Property
prop_load_completes_with_response = H.withTests 1 . H.property $ do
    let (ps0, s0) = primeExec (TLoad 2 0x10) initState
    let (ps1, s1, _) = step1 ps0 s0 noInp                                  -- issue read
    let (_, s2, out) = step1 ps1 s1 (noInp { pipeMemResp = Just 0xAB })    -- response
    pipeStalled out H.=== False
    getReg 2 s2 H.=== 0xAB

-- ---------------------------------------------------------------------------
-- Memory write (store)
-- ---------------------------------------------------------------------------

prop_store_issues_write :: H.Property
prop_store_issues_write = H.withTests 1 . H.property $ do
    let s0 = setReg 1 0xBE initState
    let (ps0, s0') = primeExec (TStore 0x20 1) s0
    let (_, _, out) = step1 ps0 s0' noInp
    pipeMemWrite out H.=== Just (0x20, 0xBE)

-- ---------------------------------------------------------------------------
-- Multi-cycle latency (TMul latency = 2)
-- ---------------------------------------------------------------------------

prop_mul_stalls_one_extra_cycle :: H.Property
prop_mul_stalls_one_extra_cycle = H.withTests 1 . H.property $ do
    let s0 = setReg 0 3 (setReg 1 4 initState)
    let (ps0, s0') = primeExec (TMul 0 1) s0     -- TMul at execute head
    -- First execution attempt: latency=2, so counts down (stall).
    let (ps1, s1, o1) = step1 ps0 s0' noInp
    pipeStalled o1 H.=== True
    -- Second attempt: countdown expired; execute.
    let (_, s2, o2) = step1 ps1 s1 noInp
    pipeStalled o2 H.=== False
    getReg 0 s2 H.=== 12   -- 3 * 4

-- ---------------------------------------------------------------------------
-- Conditional branch
-- ---------------------------------------------------------------------------

prop_brz_no_flush_when_zero_clear :: H.Property
prop_brz_no_flush_when_zero_clear = H.withTests 1 . H.property $ do
    let s0 = withZero False initState
    let (ps0, s0') = primeExec (TBrZ 0x30) s0
    let (_, _, out) = step1 ps0 s0' noInp
    pipeFlush out H.=== Nothing

prop_brz_flushes_when_zero_set :: H.Property
prop_brz_flushes_when_zero_set = H.withTests 1 . H.property $ do
    let s0 = withZero True initState
    let (ps0, s0') = primeExec (TBrZ 0x30) s0
    let (_, _, out) = step1 ps0 s0' noInp
    pipeFlush out H.=== Just (FlushBranch 0x30)

-- ---------------------------------------------------------------------------
-- Interrupt acceptance
-- ---------------------------------------------------------------------------

prop_irq_accepted_at_bubble :: H.Property
prop_irq_accepted_at_bubble = H.withTests 1 . H.property $ do
    let inp = PipeInput Nothing Nothing (Just 0xFF)
    let (_, _, out) = step1 emptyP1 initState inp
    pipeFlush   out H.=== Just (FlushInterrupt 0xFF)
    pipeStalled out H.=== False

prop_irq_clears_pipeline :: H.Property
prop_irq_clears_pipeline = H.withTests 1 . H.property $ do
    -- TState.acceptIrq returns (s, Nothing), so after IRQ head is SEmpty.
    let inp = PipeInput (Just TNop) Nothing (Just 0xFF)
    let (ps', _, _) = step1 emptyP1 initState inp
    psSlots ps' H.=== C.repeat SEmpty

pipelineTests :: TestTree
pipelineTests = $(testGroupGenerator)
