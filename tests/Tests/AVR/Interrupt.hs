module Tests.AVR.Interrupt where

import Prelude

import Test.Tasty
import Test.Tasty.TH
import Test.Tasty.Hedgehog
import qualified Hedgehog as H

import qualified Clash.Prelude as C
import Clash.Prelude (Bit)

import AVR.Core     (AVRAddr, zeroState, CoreData(..), StatusRegister(..))
import Core.Periph.Interrupt (interruptArbiter)
import AVR.CPU      (CPUState(..), Stage(..), cpuStep)
import AVR.Exec     (runPipeline)
import AVR.ALU      (getReg)

-- ---------------------------------------------------------------------------
-- Arbiter helpers
-- ---------------------------------------------------------------------------

-- | Evaluate a 1-source arbiter for one cycle.
--   The arbiter is purely combinatorial so no clock state is needed.
arbiter1 :: Bool -> Bool -> AVRAddr -> Maybe AVRAddr
arbiter1 req ie vec =
    let srcs :: C.Vec 1 (C.Signal C.System Bool, AVRAddr)
        srcs = (C.pure req, vec) C.:> C.Nil
        out  :: C.Signal C.System (Maybe AVRAddr)
        out  = interruptArbiter srcs (C.pure ie)
    in C.sampleN 2 out !! 1

-- | Evaluate a 2-source arbiter for one cycle.
arbiter2 :: (Bool, AVRAddr) -> (Bool, AVRAddr) -> Bool -> Maybe AVRAddr
arbiter2 (r0, v0) (r1, v1) ie =
    let srcs :: C.Vec 2 (C.Signal C.System Bool, AVRAddr)
        srcs = (C.pure r0, v0) C.:> (C.pure r1, v1) C.:> C.Nil
        out  :: C.Signal C.System (Maybe AVRAddr)
        out  = interruptArbiter srcs (C.pure ie)
    in C.sampleN 2 out !! 1

-- ---------------------------------------------------------------------------
-- Arbiter unit tests
-- ---------------------------------------------------------------------------

-- Asserted request with global interrupts enabled → forward vector.
prop_arbiter_accepts_asserted_request :: H.Property
prop_arbiter_accepts_asserted_request = H.withTests 1 . H.property $
    arbiter1 True True 0x0020 H.=== Just 0x0020

-- Deasserted request → Nothing even with interrupts enabled.
prop_arbiter_no_output_when_not_requested :: H.Property
prop_arbiter_no_output_when_not_requested = H.withTests 1 . H.property $
    arbiter1 False True 0x0020 H.=== Nothing

-- Asserted request but global interrupts disabled → gated to Nothing.
prop_arbiter_blocked_when_ie_false :: H.Property
prop_arbiter_blocked_when_ie_false = H.withTests 1 . H.property $
    arbiter1 True False 0x0020 H.=== Nothing

-- Both sources asserted: lower index (source 0) wins.
prop_arbiter_first_source_has_priority :: H.Property
prop_arbiter_first_source_has_priority = H.withTests 1 . H.property $
    arbiter2 (True, 0x0010) (True, 0x0020) True H.=== Just 0x0010

-- Only source 1 asserted: source 1 is forwarded.
prop_arbiter_second_source_wins_when_first_clear :: H.Property
prop_arbiter_second_source_wins_when_first_clear = H.withTests 1 . H.property $
    arbiter2 (False, 0x0010) (True, 0x0020) True H.=== Just 0x0020

-- Neither source asserted → Nothing.
prop_arbiter_nothing_when_no_requests :: H.Property
prop_arbiter_nothing_when_no_requests = H.withTests 1 . H.property $
    arbiter2 (False, 0x0010) (False, 0x0020) True H.=== Nothing

-- ---------------------------------------------------------------------------
-- CPU interrupt acceptance (cpuStep-level)
-- ---------------------------------------------------------------------------

-- | A CPU state at SFetch1 with global interrupts enabled.
iFetch1 :: CoreData 16 -> CPUState 16
iFetch1 core = CPUState (core { status = (status core) { interrupt_flag = 1 } }) SFetch1

-- | A CPU state at SFetch1 with global interrupts disabled.
noIFetch1 :: CoreData 16 -> CPUState 16
noIFetch1 core = CPUState (core { status = (status core) { interrupt_flag = 0 } }) SFetch1

-- I-bit is cleared the moment the interrupt is accepted.
prop_cpu_irq_clears_i_bit :: H.Property
prop_cpu_irq_clears_i_bit = H.withTests 1 . H.property $ do
    let s0 = iFetch1 (zeroState :: CoreData 16)
    let (s1, _) = cpuStep s0 (0x0000, 0x00, Just 0x0020)
    interrupt_flag (status (cpuCore s1)) H.=== (0 :: Bit)

-- When I=0, IRQ vector is ignored and the CPU fetches the instruction normally.
prop_cpu_irq_ignored_when_disabled :: H.Property
prop_cpu_irq_ignored_when_disabled = H.withTests 1 . H.property $ do
    let s0 = noIFetch1 (zeroState :: CoreData 16)
    -- NOP word (0x0000) with IRQ pending; should decode NOP, not divert.
    let (s1, _) = cpuStep s0 (0x0000, 0x00, Just 0x0020)
    -- CPU stayed in SFetch1 (NOP executed sequentially) rather than SCallPush2.
    cpuStage s1 H.=== SFetch1
    -- I-bit is still 0 (no spurious set).
    interrupt_flag (status (cpuCore s1)) H.=== (0 :: Bit)

-- After acceptance the CPU completes the CALL push and jumps to the vector.
prop_cpu_irq_jumps_to_vector :: H.Property
prop_cpu_irq_jumps_to_vector = H.withTests 1 . H.property $ do
    let s0 = iFetch1 (zeroState :: CoreData 16)
    let (s1, _) = cpuStep s0 (0x0000, 0x00, Just 0x0020)
    let (s2, _) = cpuStep s1 (0x0000, 0x00, Nothing)
    cpuStage s2     H.=== SFetch1
    pc (cpuCore s2) H.=== (0x0020 :: C.Unsigned 16)

-- ---------------------------------------------------------------------------
-- Full interrupt → ISR → RETI round-trip (cpuStep trace)
-- ---------------------------------------------------------------------------

-- Interrupt accepted, ISR executes RETI, CPU returns to interrupted PC
-- with the I-bit restored.
--
-- Trace (initial PC=0, SP=0, I=1):
--   Step 1: IRQ @ 0x0020 → accept, clear I, push lo(PC=0)=0x00, SP → 0xFFFF
--   Step 2: push hi=0x00 to 0xFFFF, SP → 0xFFFE, PC → 0x0020, SFetch1
--   Step 3: fetch RETI (0x9518) → startRet True, SP → 0xFFFF, SRetRead1
--   Step 4: pop hi byte (0x00 from addr 0xFFFF) → SP → 0x0000, SRetRead2
--   Step 5: pop lo byte (0x00 from addr 0x0000) → restore PC=0, I=1, SFetch1
prop_full_interrupt_reti_cycle :: H.Property
prop_full_interrupt_reti_cycle = H.withTests 1 . H.property $ do
    let s0 = iFetch1 (zeroState :: CoreData 16)

    -- Step 1: IRQ arrives → I cleared, CALL push sequence starts
    let (s1, _) = cpuStep s0 (0x0000, 0x00, Just (0x0020 :: AVRAddr))
    interrupt_flag (status (cpuCore s1)) H.=== (0 :: Bit)

    -- Step 2: second push completes → jump to ISR
    let (s2, _) = cpuStep s1 (0x0000, 0x00, Nothing)
    cpuStage s2     H.=== SFetch1
    pc (cpuCore s2) H.=== (0x0020 :: C.Unsigned 16)

    -- Step 3: fetch RETI at ISR address → begin stack pop
    let (s3, _) = cpuStep s2 (0x9518, 0x00, Nothing)
    cpuStage s3 H.=== SRetRead1 True

    -- Step 4: receive hi byte of return address (0x00 pushed earlier)
    let (s4, _) = cpuStep s3 (0x0000, 0x00, Nothing)

    -- Step 5: receive lo byte → PC restored, I re-enabled
    let (s5, _) = cpuStep s4 (0x0000, 0x00, Nothing)
    cpuStage s5                          H.=== SFetch1
    pc (cpuCore s5)                      H.=== (0x0000 :: C.Unsigned 16)
    interrupt_flag (status (cpuCore s5)) H.=== (1 :: Bit)

-- ---------------------------------------------------------------------------
-- Pipeline-level interrupt test (runPipeline)
-- ---------------------------------------------------------------------------

-- A program that enables interrupts (SEI = BSET 7) and then loops (RJMP .-2).
-- An IRQ is injected mid-run; verify the CPU eventually reaches the vector.
--
--   word 0: SEI  = 0x9478   (BSET 7, sets SREG.I)
--   word 1: RJMP .-2 (k=-1) = 0xCFFF  (loop back to word 1 itself after jump)
--   word 2: RETI = 0x9518   (ISR: just return immediately)
seiLoopProg :: C.Unsigned 16 -> C.BitVector 16
seiLoopProg 0 = 0x9478   -- SEI
seiLoopProg 1 = 0xCFFF   -- RJMP -1 (infinite loop at word 1)
seiLoopProg 2 = 0x9518   -- RETI  (ISR)
seiLoopProg _ = 0x0000   -- NOP padding

prop_pipeline_irq_redirects_pc :: H.Property
prop_pipeline_irq_redirects_pc = H.withTests 1 . H.property $ do
    -- Start from SStart so the pipeline fetches word 0 (SEI) on the first
    -- cycle rather than processing a stale 0x0000 = NOP.
    -- Inject IRQ vector 0x0002 from cycle 6 onward (giving SEI time to set I).
    let irqs     = replicate 6 Nothing ++ repeat (Just 0x0002)
        initCPU  = CPUState (zeroState :: CoreData 16) SStart
        finalCPU = runPipeline seiLoopProg irqs 14 initCPU
    -- After 14 cycles the CPU should have jumped to the ISR at 0x0002.
    H.assert (pc (cpuCore finalCPU) >= 0x0002)

interruptTests :: TestTree
interruptTests = $(testGroupGenerator)
