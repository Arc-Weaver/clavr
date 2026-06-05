module Tests.Example.Project where

import Prelude

import Test.Tasty
import Test.Tasty.TH
import Test.Tasty.Hedgehog
import qualified Hedgehog as H

import qualified Clash.Prelude as C

import Example.Project (soc, testProgram)
import AVR.Core        (AVRWord)

-- | Run the SoC for enough cycles to execute the initialisation sequence
--   (DDR write) and one full PORT toggle (0x55 then 0xAA).
--
--   The program sequence (in CPU cycles, approximate):
--     ~6  cycles: LDI + STS DDR
--     ~4  cycles: LDI + STS PORT=0x55
--     ~4  cycles: LDI + STS PORT=0xAA
--     ~1  cycle:  RJMP back
--
--   We simulate 200 cycles which is more than enough for several iterations.
prop_socGpioToggle :: H.Property
prop_socGpioToggle = H.withTests 1 . H.property $ do
    let gpioIn  = C.fromList (repeat (0 :: AVRWord))
        (portSig, ddrSig) = C.withClockResetEnable
                              (C.clockGen @C.System) C.resetGen C.enableGen
                              soc gpioIn
        portOut = C.sampleN 200 portSig
        ddrOut  = C.sampleN 200 ddrSig
        -- After init the PORT must have toggled between 0x55 and 0xAA
        seen55 = 0x55 `elem` portOut
        seenAA = 0xAA `elem` portOut
        -- DDR should be 0xFF once the init write lands
        ddrSet = 0xFF `elem` ddrOut
    H.assert seen55
    H.assert seenAA
    H.assert ddrSet

-- | The test program Vec has the right size (16 words).
prop_programSize :: H.Property
prop_programSize = H.withTests 1 . H.property $
    H.assert (length (C.toList testProgram) == 16)

accumTests :: TestTree
accumTests = $(testGroupGenerator)
