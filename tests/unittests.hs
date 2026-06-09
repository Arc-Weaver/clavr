import Prelude

import Test.Tasty

import qualified Tests.Core.ISA
import qualified Tests.Core.Pipeline
import qualified Tests.Core.GPIO
import qualified Tests.Example.Project
import qualified Tests.AVR.InstructionSet
import qualified Tests.AVR.Instructions
import qualified Tests.AVR.Interrupt
import qualified Tests.AVR.CPU

main :: IO ()
main = defaultMain $ testGroup "."
  [ Tests.Core.ISA.isaTests
  , Tests.Core.Pipeline.pipelineTests
  , Tests.Core.GPIO.gpioTests
  , Tests.Example.Project.accumTests
  , Tests.AVR.InstructionSet.instrTests
  , Tests.AVR.Instructions.instructionTests
  , Tests.AVR.Interrupt.interruptTests
  , Tests.AVR.CPU.cpuTests
  ]
