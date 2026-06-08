-- @createDomain@ generates orphan-instance warnings; suppress them.
{-# OPTIONS_GHC -Wno-orphans #-}

module Example.Project where

import Clash.Prelude
import AVR.Core        (AVRAddr, AVRWord)
import AVR.CPU         (avrCore)
import Core.Periph.GPIO (gpioUnit)
import AVR.TH          (loadAvrBin)

-- ---------------------------------------------------------------------------
-- Clock domain
-- ---------------------------------------------------------------------------

createDomain vSystem{vName="Dom10MHz", vPeriod=hzToPeriod 10e6}

-- ---------------------------------------------------------------------------
-- Program ROM
-- ---------------------------------------------------------------------------

testProgram :: Vec 16 (BitVector 16)
testProgram = $(loadAvrBin "example/Example/program.bin")

-- ---------------------------------------------------------------------------
-- Memory map
-- ---------------------------------------------------------------------------

-- GPIO Port A: PIN=0x0060, DDR=0x0061, PORT=0x0062
gpioABase :: AVRAddr
gpioABase = 0x0060

-- SRAM: 2 KB at 0x0200-0x09FF
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
--     ddrOut  - data-direction register.  A '1' bit means OUTPUT (driven from
--               portOut).  A '0' bit means INPUT (high-Z).
--               Connect to the T pin of each IOBUF (active-high here).
soc :: forall dom . HiddenClockResetEnable dom
    => Signal dom AVRWord                        -- GPIO A physical pin inputs
    -> (Signal dom AVRWord, Signal dom AVRWord)  -- (PORT latch, DDR / OE)
soc gpioIn = (portOut, ddrOut)
  where
    -- ── CPU ──────────────────────────────────────────────────────────────────
    (codeAddr, rdAddr, wr) = avrCore @dom @16 (pure Nothing) codeIn dataIn

    -- ── Code ROM (synchronous, 1-cycle latency via blockRam) ─────────────────
    codeIn = blockRam testProgram
                 (toRomIdx <$> codeAddr)
                 (pure Nothing)
      where
        toRomIdx :: Unsigned 16 -> Index 16
        toRomIdx = fromIntegral

    -- ── SRAM (2 KB at 0x0200) ────────────────────────────────────────────────
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
    (gpioRd, portOut, ddrOut) = gpioUnit gpioABase gpioIn rdAddr wr

    -- ── Read-data mux ────────────────────────────────────────────────────────
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
                     [ PortName "gpio_a_port"
                     , PortName "gpio_a_ddr"
                     ]
    }) #-}

{-# OPAQUE topEntity #-}

topEntity :: Clock Dom10MHz
          -> Reset Dom10MHz
          -> Enable Dom10MHz
          -> Signal Dom10MHz AVRWord
          -> (Signal Dom10MHz AVRWord, Signal Dom10MHz AVRWord)
topEntity = exposeClockResetEnable soc
