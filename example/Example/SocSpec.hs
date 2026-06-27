{-# LANGUAGE TypeApplications #-}
-- | AVR SoC description — program ROM contents, peripheral wiring, memory map.
--
-- Memory map (data bus):
--   0x0040 – 0x0042   UART  (UDR / USR / UBRR)
--   0x0050 – 0x0052   Timer (TCCR / TCNT / OCR)
--   0x0060 – 0x0062   GPIO Port A (PIN / DDR / PORT)
--   0x0070 – 0x0072   Ramp  (SETPOINT / STEP / CURRENT, signed datapath)
--   0x0200 – 0x09FF   2 KB SRAM
--
-- Code bus:
--   0x0000 – 0x1FFF   Code ROM (16-bit words, AVR word-addressed)
--
-- Interrupt vectors (AVR word addresses):
--   0x000B  USART RX complete
--
-- Usage:
--   avr-soc-synth [<program.bin> [<outdir>]]
--   Defaults: example/Example/program.bin  build/avr_soc
module Main where

import Prelude
import System.Environment (getArgs)
import System.Directory (createDirectoryIfMissing)
import qualified Data.ByteString as BS
import Data.Bits (shiftL, (.|.))

import Hdl.Types
import Hdl.Net (DomId(..), ClockEdge(..), ResetPolarity(..))
import Hdl.Prim (Unsigned)
import Hdl.Emit.Vhdl
import Isacle.System.SystemDSL
import Isacle.System.HdlCircuit (GpioPhys(..), UartPhys(..))

import AVR.ISA (avrCPUDef, avrATmegaISA)

-- ---------------------------------------------------------------------------
-- Clock domain
-- ---------------------------------------------------------------------------

data Dom10MHz
instance KnownDom Dom10MHz where
    domId _ = DomId "dom10mhz" 10000000 Rising ActiveHigh "rst"

-- ---------------------------------------------------------------------------
-- Runtime binary loading
-- ---------------------------------------------------------------------------

readBin16LE :: FilePath -> IO [Integer]
readBin16LE path = do
    bytes <- BS.unpack <$> BS.readFile path
    let words16 = parseLE bytes
        n       = length words16
        n'      = nextPow2 (max 1 n)
    return (words16 ++ replicate (n' - n) 0)
  where
    parseLE []        = []
    parseLE [_]       = []
    parseLE (lo:hi:t) = ((fromIntegral hi `shiftL` 8) .|. fromIntegral lo)
                        : parseLE t
    nextPow2 k
        | k <= 1    = 1
        | otherwise = 2 * nextPow2 ((k + 1) `div` 2)

-- ---------------------------------------------------------------------------
-- SoC description (ROM contents passed in at synthesis time)
-- ---------------------------------------------------------------------------

avrSocWith :: [Integer] -> SysDSL Dom10MHz (Unsigned 8) ()
avrSocWith romWords = do
    uart0  <- createUart  "uart0"  sigFalse
    timer0 <- createTimer "timer0" sigFalse
    gpio0  <- createGpio  "gpio0"  0
    ramp0  <- createRamp  "ramp0"  sigTrue   -- advance every cycle (demonstrator)
    ram0   <- createRam   2048 [] "ram0"

    ((uartOut, gpioOut), dataBus) <- createBus "databus" $ do
        uartOut'  <- attachPeripheral 0x0040 uart0
        _         <- attachPeripheral 0x0050 timer0
        gpioOut'  <- attachPeripheral 0x0060 gpio0
        _         <- attachPeripheral 0x0070 ramp0
        _         <- attachPeripheral 0x0200 ram0
        return (uartOut', gpioOut')

    _ <- createSimpleVectorIrq [(uartRxIrq uartOut, 0x000B)]

    createHarvardCPU @16 @16 @16 "cpu" avrCPUDef avrATmegaISA dataBus romWords

    sysOutput "gpio_port" (gpioPort gpioOut)
    sysOutput "gpio_ddr"  (gpioDdr  gpioOut)

-- ---------------------------------------------------------------------------
-- Main: emit VHDL
-- ---------------------------------------------------------------------------

main :: IO ()
main = do
    args <- getArgs
    let progBin = case args of { (p:_)   -> p; _ -> "example/Example/program.bin" }
        outDir  = case args of { (_:o:_) -> o; _ -> "build/avr_soc" }
    romWords <- readBin16LE progBin
    createDirectoryIfMissing True outDir
    let design = execSystemDSL @Dom10MHz @(Unsigned 8) "avr_soc" (avrSocWith romWords)
    emitVhdlDesignFiles outDir design
    putStrLn $ "AVR SoC synthesis done — " ++ progBin ++ " → " ++ outDir
