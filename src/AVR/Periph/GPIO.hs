module AVR.Periph.GPIO
    ( GPIOState(..)
    , gpioUnit
    ) where

import Clash.Prelude
import AVR.Core (AVRAddr, AVRWord)

-- | Internal state of one 8-bit GPIO port.
data GPIOState = GPIOState
    { gpioDdr  :: AVRWord   -- data direction register  (1 = output)
    , gpioPort :: AVRWord   -- output latch
    } deriving (Generic, NFDataX, Show, Eq)

-- | AVR-style GPIO port with three memory-mapped registers:
--
--     base + 0  PIN   read  → sampled physical inputs
--     base + 1  DDR   read/write → data direction (1 = output)
--     base + 2  PORT  read/write → output latch
--
--   Writes take effect on the rising edge; reads return the value
--   written in the same cycle (write-then-read, consistent with
--   the CPU's SMemRead stage which consumes data one cycle after
--   presenting the address).
--
--   Outputs:
--     rdData  – registered read result (feeds the CPU's dataIn bus)
--     portOut – PORT latch (connect to output-enabled pins)
--     ddrOut  – DDR register (connect to tri-state enable: 1 = driven)
gpioUnit :: HiddenClockResetEnable dom
         => AVRAddr                                  -- base address
         -> Signal dom AVRWord                        -- physical pin inputs
         -> Signal dom (Maybe AVRAddr)                -- data bus read address
         -> Signal dom (Maybe (AVRAddr, AVRWord))     -- data bus write
         -> ( Signal dom AVRWord                      -- read data (registered)
            , Signal dom AVRWord                      -- PORT output latch
            , Signal dom AVRWord                      -- DDR (output enable)
            )
gpioUnit base pinsIn rdAddr wr = (rdData, portOut, ddrOut)
  where
    step (GPIOState ddr port) (pins, mrd, mwr) =
        let -- Apply writes (base+1 = DDR, base+2 = PORT; PIN is read-only)
            (ddr', port') = case mwr of
                Just (a, v)
                    | a == base + 1 -> (v,   port)
                    | a == base + 2 -> (ddr, v   )
                _                   -> (ddr, port)
            -- Compute read result from the post-write state
            rd = case mrd of
                Just a
                    | a == base     -> pins   -- PIN: sample physical inputs
                    | a == base + 1 -> ddr'
                    | a == base + 2 -> port'
                _                   -> 0
        in (GPIOState ddr' port', (rd, port', ddr'))

    out     = mealy step (GPIOState 0 0) (bundle (pinsIn, rdAddr, wr))
    rdData  = fmap (\(r, _, _) -> r) out
    portOut = fmap (\(_, p, _) -> p) out
    ddrOut  = fmap (\(_, _, d) -> d) out
