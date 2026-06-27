{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeApplications #-}
module Main where

import Prelude
import Data.Proxy   (Proxy(..))
import GHC.TypeLits (natVal)
import System.Exit  (exitFailure)
import Test.Tasty

import Hdl.Types (Width, toBits, fromBits)
import Hdl.Bits  (Vec(..))
import AVR.ISA.Types (AvrState(..), Sreg(..))

-- A plain regression check (no extra test deps) locking in the AvrState /
-- Sreg HdlType records (C1/C2): widths and a round-trip through bits.
assert :: String -> Bool -> IO ()
assert msg False = putStrLn ("FAIL: " ++ msg) >> exitFailure
assert msg True  = putStrLn ("ok:   " ++ msg)

stateChecks :: IO ()
stateChecks = do
    assert "Width Sreg = 8"
        (natVal (Proxy @(Width Sreg)) == 8)
    assert "Width (AvrState 16) = 344"
        (natVal (Proxy @(Width (AvrState 16))) == 344)
    let s = AvrState (Vec (replicate 32 0)) 0xBEEF 1 2 3 0x1234 (Sreg 1 0 0 0 0 0 0 1)
            :: AvrState 16
        s' = fromBits (toBits s) :: AvrState 16
    assert "AvrState round-trips SP"     (asSP s' == 0xBEEF)
    assert "AvrState round-trips PC"     (asPC s' == 0x1234)
    assert "AvrState round-trips SREG.I" (sI (asSREG s') == 1)
    assert "AvrState round-trips SREG.C" (sC (asSREG s') == 1)

main :: IO ()
main = do
    stateChecks
    defaultMain $ testGroup "." []
