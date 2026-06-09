module AVR.TH
    ( loadAvrBin
    ) where

import Prelude (FilePath)
import Language.Haskell.TH (Q, Exp)
import Core.TH (loadBin16LE)

-- | Read an assembled AVR flat binary at compile time and splice it as
--   @Vec n (BitVector 16)@.
--
--   Instruction words are little-endian (low byte first).  The binary is
--   zero-padded with NOPs (@0x0000@) to the next power of two, so the
--   resulting 'Vec' size is always a power of two — required for efficient
--   block-RAM addressing.
--
--   Usage:
--     testProgram :: Vec 16 (BitVector 16)
--     testProgram = $(loadAvrBin "src/Example/program.bin")
--
--   GHC recompiles the module whenever the file changes.
loadAvrBin :: FilePath -> Q Exp
loadAvrBin = loadBin16LE
