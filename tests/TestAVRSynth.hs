{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE DataKinds #-}
module Main where

import Prelude
import System.Directory (createDirectoryIfMissing)

import Hdl.Types
import Hdl.Net (DomId(..), ClockEdge(..), ResetPolarity(..), execDesign)
import Hdl.Prim (Unsigned)
import Hdl.Emit.Vhdl
import Isacle.ISA.Backend.SynthCPU (synthHarvardCPU)

import AVR.ISA (avrCPUDef, avrATmegaISA)

data Sys

instance KnownDom Sys where
    domId _ = DomId "sys" 16000000 Rising ActiveHigh "rst"

main :: IO ()
main = do
    let outDir = "build/avr_cpu"
    createDirectoryIfMissing True outDir
    let design = execDesign "avr_cpu" $
            synthHarvardCPU @Sys @8 @16 @16 @16 avrCPUDef avrATmegaISA
    emitVhdlDesignFiles outDir design
    putStrLn $ "AVR synthesis done — VHDL written to " ++ outDir
