module AVR.Exec where

import Clash.Prelude
import AVR.Core
import AVR.InstructionSet
import AVR.ALU
import AVR.CPU (CPUState(..), cpuStep)

-- | Run instruction words sequentially, ignoring PC-changing instructions.
--   Useful for testing linear sequences of instructions.
runLinear :: KnownNat pcBits => [BitVector 16] -> CoreData pcBits -> CoreData pcBits
runLinear []      core = core
runLinear (w0:ws) core =
    let partial = decodeInstruction (w0 ++# (0 :: BitVector 16))
    in if instrWords partial == 2
       then case ws of
           (w1:rest) -> runLinear rest  $ step (decodeInstruction (w0 ++# w1)) core 2
           []        -> core
       else            runLinear ws    $ step partial core 1
  where
    step instr c n = (avrCompute instr Nothing c) { pc = pc c + n }

-- | Run a program using the PC to address into program memory, honouring
--   jumps and branches. Terminates when pc >= stopAt.
--
--   Typical use: stopAt = fromIntegral (length program)
runWithPC :: KnownNat pcBits
          => [BitVector 16]    -- program memory (word-addressed from 0)
          -> Unsigned pcBits   -- stop when pc >= this
          -> CoreData pcBits
          -> CoreData pcBits
runWithPC mem stopAt core
    | pc core >= stopAt = core
    | otherwise =
        let i       = fromIntegral (pc core) :: Int
            w0      = fetch i
            partial = decodeInstruction (w0 ++# 0)
        in if instrWords partial == 2
           then runWithPC mem stopAt $ step (decodeInstruction (w0 ++# fetch (i + 1))) core (pc core + 2)
           else runWithPC mem stopAt $ step partial core (pc core + 1)
  where
    fetch i   = maybe 0 id (listAt mem i)
    step instr c seqNext =
        let c' = avrCompute instr Nothing c
        in  c' { pc = maybe seqNext id (avrJump instr c') }

-- | Simulate the full CPU pipeline for @nCycles@ clock cycles, modelling all
--   pipeline stages and the synchronous memory latency.
--
--   The code ROM is a pure word-addressed function.  Data RAM always returns 0
--   (sufficient for programs that only write to memory, not read from it).
--
--   @irqs@ is the interrupt vector to present on each cycle; the list is
--   consumed left-to-right and padded with Nothing once exhausted.
--
--   Useful for testing multi-cycle instructions (CALL/RET, LPM) and interrupt
--   acceptance without setting up the full Signal-level simulation harness.
runPipeline
    :: KnownNat pcBits
    => (Unsigned pcBits -> BitVector 16)   -- word-addressed code ROM
    -> [Maybe AVRAddr]                     -- interrupt vector per cycle
    -> Int                                 -- total cycles to run
    -> CPUState pcBits
    -> CPUState pcBits
runPipeline codeRom irqs nCycles initState = go nCycles irqs initState 0 0
  where
    go 0 _  s _         _         = s
    go n is s pendCode  pendData  =
        let irq  = case is of { (i:_) -> i; [] -> Nothing }
            rest = case is of { (_:r) -> r; [] -> [] }
            (s', (nextCode, _, _)) = cpuStep s (pendCode, pendData, irq)
        in go (n-1) rest s' (codeRom nextCode) 0

-- Safe list index; returns Nothing for out-of-bounds.
listAt :: [a] -> Int -> Maybe a
listAt []     _ = Nothing
listAt (x:_)  0 = Just x
listAt (_:xs) n = listAt xs (n - 1)
