-- vhdl_sim.hs — cabal test-suite entry point for all GHDL simulation tests.
--
-- Each TestCase runs avr-soc-synth with a specific binary, then simulates the
-- resulting VHDL with the matching testbench.  The testbench reports a line of
-- the form:
--
--   gpio_port = 0x<decimal>  gpio_ddr = 0x<decimal>
--
-- This runner searches for expected tokens in that output.
--
-- Requirements: ghdl, avr-as, avr-ld, avr-objcopy must be on PATH.
import Prelude
import Data.List          (isInfixOf)
import System.Exit        (ExitCode(..), exitFailure, exitSuccess)
import System.Process     (readProcessWithExitCode)
import System.IO          (hPutStrLn, stderr)

-- ---------------------------------------------------------------------------
-- Test case description
-- ---------------------------------------------------------------------------

data TestCase = TestCase
    { tcName     :: String    -- short name / build dir prefix
    , tcProgBin  :: FilePath  -- pre-assembled flat binary
    , tcTbVhd    :: FilePath  -- VHDL testbench file
    , tcStopNs   :: Int       -- simulation stop time in ns
    , tcExpected :: [(String, String)]
        -- ^ list of (signal-name, expected-decimal) tokens to find in output
        --   e.g. ("gpio_port", "0x186") means the TB must print "gpio_port = 0x186"
    }

-- ---------------------------------------------------------------------------
-- All test scenarios
-- ---------------------------------------------------------------------------

tests :: [TestCase]
tests =
    -- Original GPIO toggle demo (uses the pre-built example program)
    [ TestCase
        { tcName     = "test_gpio_demo"
        , tcProgBin  = "example/Example/program.bin"
        , tcTbVhd    = "tests/ghdl/avr_soc_tb.vhd"
        , tcStopNs   = 2000
        , tcExpected = [("gpio_port", "0x85"), ("gpio_ddr", "0x255")]
          -- 0x55 = 85 decimal, 0xFF = 255 decimal
        }

    -- ALU instruction test: chain of ADD/SUB/AND/OR/EOR/INC/DEC/LSR/ASR/NEG/COM/SWAP
    -- Final GPIO_PORT = 0xBA (186 decimal)
    , TestCase
        { tcName     = "test_alu"
        , tcProgBin  = "tests/fixtures/alu_test.bin"
        , tcTbVhd    = "tests/ghdl/alu_tb.vhd"
        , tcStopNs   = 1000
        , tcExpected = [("gpio_port", "0x186"), ("gpio_ddr", "0x255")]
        }

    -- Branch / subroutine test: RJMP + RCALL/RET + BRNE countdown loop
    -- Accumulates 5+4+3+2+1 = 15 = 0x0F → GPIO_PORT = 15 decimal
    , TestCase
        { tcName     = "test_branch"
        , tcProgBin  = "tests/fixtures/branch_test.bin"
        , tcTbVhd    = "tests/ghdl/branch_tb.vhd"
        , tcStopNs   = 3000
        , tcExpected = [("gpio_port", "0x15"), ("gpio_ddr", "0x255")]
        }

    -- Memory test: STS/LDS + Z-pointer ST/LD + PUSH/POP
    -- All paths produce GPIO_PORT = 0xFF (255 decimal)
    , TestCase
        { tcName     = "test_mem"
        , tcProgBin  = "tests/fixtures/mem_test.bin"
        , tcTbVhd    = "tests/ghdl/mem_tb.vhd"
        , tcStopNs   = 2000
        , tcExpected = [("gpio_port", "0x255"), ("gpio_ddr", "0x255")]
        }

    -- Immediate instruction test: SUBI/ANDI/ORI + CPI+BRCC skip
    -- Final GPIO_PORT = 0x4C (76 decimal)
    , TestCase
        { tcName     = "test_imm"
        , tcProgBin  = "tests/fixtures/imm_test.bin"
        , tcTbVhd    = "tests/ghdl/imm_tb.vhd"
        , tcStopNs   = 500
        , tcExpected = [("gpio_port", "0x76"), ("gpio_ddr", "0x255")]
        }

    -- Timer peripheral test: write/read Timer OCR register
    -- Final GPIO_PORT = 0xA5 (165 decimal)
    , TestCase
        { tcName     = "test_timer"
        , tcProgBin  = "tests/fixtures/timer_test.bin"
        , tcTbVhd    = "tests/ghdl/timer_tb.vhd"
        , tcStopNs   = 500
        , tcExpected = [("gpio_port", "0x165"), ("gpio_ddr", "0x255")]
        }

    -- UART peripheral test: write/read UART UBRR register
    -- Final GPIO_PORT = 0x68 (104 decimal)
    , TestCase
        { tcName     = "test_uart"
        , tcProgBin  = "tests/fixtures/uart_test.bin"
        , tcTbVhd    = "tests/ghdl/uart_tb.vhd"
        , tcStopNs   = 500
        , tcExpected = [("gpio_port", "0x104"), ("gpio_ddr", "0x255")]
        }
    ]

-- ---------------------------------------------------------------------------
-- Runner
-- ---------------------------------------------------------------------------

runTest :: TestCase -> IO (String, [String])
runTest tc = do
    (rc, out, err) <- readProcessWithExitCode "bash"
        [ "tests/ghdl/run_test.sh"
        , tcName tc
        , tcProgBin tc
        , tcTbVhd tc
        , show (tcStopNs tc)
        ] ""
    let combined = out ++ err
    let failures =
            [ "MISSING token \"" ++ token ++ "\""
            | (sig, want) <- tcExpected tc
            , let token = sig ++ " = " ++ want
            , not (token `isInfixOf` combined)
            ]
        allFails =
            if rc /= ExitSuccess
                then "non-zero exit code from ghdl/synth" : failures
                else failures
    if null allFails
        then return (tcName tc, [])
        else return (tcName tc, allFails ++ ["--- output ---", combined])

main :: IO ()
main = do
    results <- mapM runTest tests
    let failed = [(name, msgs) | (name, msgs) <- results, not (null msgs)]
    if null failed
        then do
            mapM_ (\(name, _) -> putStrLn $ "PASS  " ++ name) results
            putStrLn "ghdl-sim: all tests passed"
            exitSuccess
        else do
            mapM_ (\(name, _) -> putStrLn $ "PASS  " ++ name)
                  [(n, m) | (n, m) <- results, null m]
            mapM_ (\(name, msgs) -> do
                hPutStrLn stderr $ "FAIL  " ++ name
                mapM_ (hPutStrLn stderr . ("  " ++)) msgs)
                  failed
            exitFailure
