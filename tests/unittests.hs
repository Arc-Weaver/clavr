import Prelude

import Test.Tasty

import qualified Tests.Core.Harvard.ISA
import qualified Tests.Core.Harvard.Pipeline
import qualified Tests.Core.GPIO
import qualified Tests.Example.Project
import qualified Tests.AVR.InstructionSet
import qualified Tests.AVR.Instructions
import qualified Tests.AVR.Interrupt
import qualified Tests.AVR.CPU

main :: IO ()
main = defaultMain $ testGroup "."
  [ Tests.Core.Harvard.ISA.isaTests
  , Tests.Core.Harvard.Pipeline.pipelineTests
  , Tests.Core.GPIO.gpioTests
  , Tests.Example.Project.accumTests
  , Tests.AVR.InstructionSet.instrTests
  , Tests.AVR.Instructions.instructionTests
  , Tests.AVR.Interrupt.interruptTests
  , Tests.AVR.CPU.cpuTests
  ]
