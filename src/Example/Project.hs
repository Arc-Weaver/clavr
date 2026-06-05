-- @createDomain@ generates orphan-instance warnings; suppress them.
{-# OPTIONS_GHC -Wno-orphans #-}

module Example.Project where

import Clash.Prelude
import AVR.Core        (AVRAddr, AVRWord)
import AVR.CPU         (avrCore)
import AVR.Periph.GPIO (gpioUnit)
import AVR.TH          (loadAvrBin)

-- ---------------------------------------------------------------------------
-- Clock domain
-- ---------------------------------------------------------------------------

createDomain vSystem{vName="Dom10MHz", vPeriod=hzToPeriod 10e6}

-- ---------------------------------------------------------------------------
-- Program ROM
--
-- Assembled from src/Example/program.S by Setup.hs at build time.
-- The binary is padded to the next power of two with NOPs (0x0000), so the
-- Vec size is always a power of two — required for block-RAM addressing.
-- The type annotation must match the padded size; a mismatch is a type error.
-- ---------------------------------------------------------------------------

testProgram :: Vec 16 (BitVector 16)
testProgram = $(loadAvrBin "src/Example/program.bin")

-- ---------------------------------------------------------------------------
-- Memory map
-- ---------------------------------------------------------------------------

-- GPIO Port A: PIN=0x0060, DDR=0x0061, PORT=0x0062
gpioABase :: AVRAddr
gpioABase = 0x0060

-- SRAM: 2 KB at 0x0200-0x09FF  (matches ATmega2560 internal SRAM base)
sramBase :: AVRAddr
sramBase = 0x0200

sramWords :: Int
sramWords = 2048

inGPIO_A :: AVRAddr -> Bool
inGPIO_A a = a >= gpioABase && a < gpioABase + 3

inSRAM :: AVRAddr -> Bool
inSRAM a = a >= sramBase && a < sramBase + fromIntegral sramWords

-- ---------------------------------------------------------------------------
-- SoC: CPU + GPIO + SRAM + bus demux
-- ---------------------------------------------------------------------------

-- | Full SoC wiring.
--
--   Returns @(portOut, ddrOut)@ for GPIO Port A:
--
--     portOut - the PORT latch; connect to the O pin of each IOBUF.
--     ddrOut  - data-direction register.  A '1' bit means the corresponding
--               pin is an OUTPUT (driven from portOut).  A '0' bit means
--               INPUT (high-Z; portOut bit is ignored electrically).
--               Connect to the T (tri-state enable) pin of each IOBUF,
--               inverting polarity if your primitive uses active-low T.
--
--   On real AVR silicon, writing PORT while DDR=0 enables the internal
--   pull-up.  This SoC does not model pull-ups.
soc :: forall dom . HiddenClockResetEnable dom
    => Signal dom AVRWord                        -- GPIO A physical pin inputs
    -> (Signal dom AVRWord, Signal dom AVRWord)  -- (PORT latch, DDR / OE)
soc gpioIn = (portOut, ddrOut)
  where
    -- ── CPU ──────────────────────────────────────────────────────────────────
    (codeAddr, rdAddr, wr) = avrCore @dom @16 codeIn dataIn

    -- ── Code ROM (synchronous, 1-cycle latency via blockRam) ─────────────────
    codeIn = blockRam testProgram
                 (toRomIdx <$> codeAddr)
                 (pure Nothing)
      where
        toRomIdx :: Unsigned 16 -> Index 16
        toRomIdx = fromIntegral

    -- ── SRAM (2 KB at 0x0200, synchronous) ──────────────────────────────────
    sramRdIdx :: Signal dom (Index 2048)
    sramRdIdx = fmap rdIdx rdAddr
      where
        rdIdx Nothing  = 0
        rdIdx (Just a) = fromIntegral (if inSRAM a then a - sramBase else 0)

    sramWr :: Signal dom (Maybe (Index 2048, AVRWord))
    sramWr = fmap wrRoute wr
      where
        wrRoute Nothing         = Nothing
        wrRoute (Just (a, v))
            | inSRAM a          = Just (fromIntegral (a - sramBase), v)
            | otherwise         = Nothing

    sramRd = blockRam (replicate (SNat @2048) 0) sramRdIdx sramWr

    -- ── GPIO Port A ──────────────────────────────────────────────────────────
    --   portOut: driven value (connect to IOBUF O)
    --   ddrOut:  output enable per-bit (connect to IOBUF T, active-high here)
    (gpioRd, portOut, ddrOut) = gpioUnit gpioABase gpioIn rdAddr wr

    -- ── Read-data mux ────────────────────────────────────────────────────────
    -- Register which peripheral was addressed so we can select the right
    -- read-data source one cycle later (when the CPU consumes dataIn).
    lastWasGPIO :: Signal dom Bool
    lastWasGPIO = register False (maybe False inGPIO_A <$> rdAddr)

    dataIn = mux lastWasGPIO gpioRd sramRd

-- ---------------------------------------------------------------------------
-- Synthesis top entity
-- ---------------------------------------------------------------------------

{-# ANN topEntity
  (Synthesize
    { t_name   = "avr_soc"
    , t_inputs = [ PortName "clk"
                 , PortName "rst_n"
                 , PortName "en"
                 , PortName "gpio_a_in"
                 ]
    , t_output = PortProduct ""
                     [ PortName "gpio_a_port"  -- PORT latch -> IOBUF O
                     , PortName "gpio_a_ddr"   -- DDR -> IOBUF T (1=output)
                     ]
    }) #-}

{-# OPAQUE topEntity #-}

topEntity :: Clock Dom10MHz
          -> Reset Dom10MHz
          -> Enable Dom10MHz
          -> Signal Dom10MHz AVRWord                         -- physical inputs (IOBUF I)
          -> (Signal Dom10MHz AVRWord, Signal Dom10MHz AVRWord) -- (gpio_a_port, gpio_a_ddr)
topEntity = exposeClockResetEnable soc
