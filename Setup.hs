import Distribution.Simple
import Distribution.Simple.Utils (notice, warn)
import Distribution.Verbosity    (normal)
import System.Directory          (doesFileExist, findExecutable,
                                  getModificationTime)
import System.FilePath           ((</>))
import System.Process            (callProcess)
import Control.Monad             (when)
import Control.Exception         (try, SomeException)

main :: IO ()
main = defaultMainWithHooks simpleUserHooks
    { preBuild = \args flags -> do
        assembleExampleProgram
        preBuild simpleUserHooks args flags
    }

-- | Assemble example/Example/program.S → program.bin if avr-binutils is
--   available and the source is newer than the binary.
--
--   Silently skips if:
--     - program.S does not exist (nothing to do)
--     - avr-as is not on PATH AND program.bin already exists (use stale bin)
--
--   Fails loudly if:
--     - avr-as is not on PATH AND program.bin does not exist
assembleExampleProgram :: IO ()
assembleExampleProgram = do
    let dir = "example" </> "Example"
        src = dir </> "program.S"
        obj = dir </> "program.o"
        elf = dir </> "program.elf"
        bin = dir </> "program.bin"

    srcExists <- doesFileExist src
    when srcExists $ do
        mavrAs <- findExecutable "avr-as"
        case mavrAs of
            Nothing -> do
                binExists <- doesFileExist bin
                if binExists
                    then notice normal
                             "avr-as not found; using pre-built program.bin"
                    else fail $ unlines
                             [ "avr-as not found and example/Example/program.bin is missing."
                             , "Install avr-binutils (e.g. apt install binutils-avr) and"
                             , "re-run the build, or commit a pre-built program.bin."
                             ]
            Just _ -> do
                stale <- isStale src bin
                when stale $ do
                    notice normal "Assembling example/Example/program.S ..."
                    callProcess "avr-as"
                        ["-mmcu=atmega2560", src, "-o", obj]
                    callProcess "avr-ld"
                        ["-mavr6", "-Ttext", "0", obj, "-o", elf]
                    callProcess "avr-objcopy"
                        ["-O", "binary", "--only-section=.text", elf, bin]
                    notice normal "Assembly done."

-- | True if dst is missing or older than src.
isStale :: FilePath -> FilePath -> IO Bool
isStale src dst = do
    dstExists <- doesFileExist dst
    if not dstExists
        then return True
        else do
            ts <- getModificationTime src
            td <- getModificationTime dst
            return (ts > td)
