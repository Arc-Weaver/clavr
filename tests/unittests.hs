import Prelude

import Test.Tasty

import qualified Tests.Example.Project
import qualified Tests.AVR.InstructionSet
import qualified Tests.AVR.CPU

main :: IO ()
main = defaultMain $ testGroup "."
  [ Tests.Example.Project.accumTests
  , Tests.AVR.InstructionSet.instrTests
  , Tests.AVR.CPU.cpuTests
  ]
