-- NB: NoImplicitPrelude is active from cabal common-options; re-import
-- standard Prelude explicitly so this module can use plain IO/Bits.
module AVR.TH
    ( loadAvrBin
    ) where

import Prelude
import Language.Haskell.TH
import Language.Haskell.TH.Syntax (addDependentFile)
import qualified Data.ByteString as BS
import Data.Bits  (shiftL, (.|.), countLeadingZeros, finiteBitSize, bit)
import Data.Word  (Word8)

import Clash.Prelude (listToVecTH)

-- | Read an assembled AVR flat binary at compile time and splice it in as a
--   @Vec n (BitVector 16)@.
--
--   The file path is relative to the project root (where GHC is invoked).
--   Instruction words are little-endian (low byte first).
--   The binary is zero-padded with NOPs (@0x0000@) to the next power of two,
--   so the resulting @Vec@ size is always a power of two — required for
--   efficient block-RAM addressing.
--
--   Usage:
--     -- In a Clash module:
--     testProgram :: Vec 16 (BitVector 16)
--     testProgram = $(loadAvrBin "src/Example/program.bin")
--
--   The Vec size must be annotated (or inferred from context); a mismatch
--   between the annotation and the actual padded file size is a type error.
--
--   GHC will recompile the module whenever @path@ changes because
--   @addDependentFile@ registers it as a dependency.
loadAvrBin :: FilePath -> Q Exp
loadAvrBin path = do
    addDependentFile path
    content <- runIO (BS.readFile path)
    let ws = padToPow2 (parseWords (BS.unpack content))
    -- listToVecTH on [Integer] emits polymorphic numeric literals, which
    -- unify with BitVector 16 (or any Num instance) at the call site.
    listToVecTH ws

-- | Parse a little-endian byte stream into 16-bit instruction words.
parseWords :: [Word8] -> [Integer]
parseWords []          = []
parseWords [_]         = []   -- trailing odd byte ignored
parseWords (lo:hi:rest) =
    ((fromIntegral hi `shiftL` 8) .|. fromIntegral lo) : parseWords rest

-- | Pad a list to the next power of two with zeros.
--   A power-of-two size means the ROM address is a clean bit-truncation of
--   the program counter (lower k bits = ROM index, no modulo needed).
padToPow2 :: [Integer] -> [Integer]
padToPow2 [] = [0]            -- degenerate: at least one element
padToPow2 xs =
    let n  = length xs
        n' = nextPow2 n
    in xs ++ replicate (n' - n) 0

-- | Smallest power of two >= n.
--   Uses countLeadingZeros so the calculation is a single bit-manipulation
--   instruction rather than a linear search or floating-point logarithm.
--
--   nextPow2 10  =  16   (1010₂  → highest bit at position 3 → 2^4)
--   nextPow2 16  =  16   (already a power of two)
--   nextPow2 17  =  32
nextPow2 :: Int -> Int
nextPow2 n
    | n <= 1    = 1
    | otherwise = bit k
  where
    -- Position of the highest set bit in (n-1).
    -- e.g. n=10: n-1=9=1001₂, highest bit at position 3, so next power = 2^4.
    -- e.g. n=16: n-1=15=1111₂, highest bit at position 3, so next power = 2^4 = 16.
    k = finiteBitSize (0 :: Int) - countLeadingZeros (n - 1)
