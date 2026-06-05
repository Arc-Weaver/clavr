module AVR.Exec where

import Clash.Prelude
import AVR.Core
import AVR.InstructionSet
import AVR.ALU

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

-- Safe list index; returns Nothing for out-of-bounds.
listAt :: [a] -> Int -> Maybe a
listAt []     _ = Nothing
listAt (x:_)  0 = Just x
listAt (_:xs) n = listAt xs (n - 1)
