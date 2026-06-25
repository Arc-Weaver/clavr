{-# LANGUAGE DataKinds #-}
module AVR.ISA
    ( module AVR.ISA.Types
    , module AVR.ISA.Arith
    , module AVR.ISA.Branch
    , module AVR.ISA.BitOps
    , module AVR.ISA.Mem
    , avrCoreInstrs
    , avrMulInstrs
    , avrExtInstrs
    , avrISAWith
    , avrATtinyISA
    , avrATmegaISA
    , avrATxmegaISA
    ) where

import Prelude hiding (Word)

import Hdl.Bits
import Isacle.ISA
import AVR.ISA.Types
import AVR.ISA.Arith
import AVR.ISA.Branch
import AVR.ISA.BitOps
import AVR.ISA.Mem

-- ---------------------------------------------------------------------------
-- Instruction groups
-- ---------------------------------------------------------------------------

-- | 16-bit instructions present on all AVR devices.
avrCoreInstrs :: AVR m pcW => [m ()]
avrCoreInstrs =
    [ instrNOP
    , instrMOVW
    , instrADD, instrADC, instrSUB, instrSBC
    , instrAND, instrOR,  instrEOR, instrMOV
    , instrCP,  instrCPC, instrCPSE
    , instrLDI, instrSUBI, instrSBCI, instrANDI, instrORI, instrCPI
    , instrINC, instrDEC, instrCOM, instrNEG, instrASR, instrLSR, instrROR, instrSWAP
    , instrADIW, instrSBIW
    , instrPUSH, instrPOP
    , instrRJMP, instrRCALL, instrRET, instrRETI
    , instrBRBS, instrBRBC
    , instrBSET, instrBCLR, instrBST, instrBLD
    , instrSBRC, instrSBRS
    , instrCBI,  instrSBI, instrSBIC, instrSBIS
    , instrIN,   instrOUT
    , instrLD_Z,  instrLD_Zplus,  instrLD_Zminus
    , instrLD_Y,  instrLD_Yplus,  instrLD_Yminus
    , instrLD_X,  instrLD_Xplus,  instrLD_Xminus
    , instrST_Z,  instrST_Zplus,  instrST_Zminus
    , instrST_Y,  instrST_Yplus,  instrST_Yminus
    , instrST_X,  instrST_Xplus,  instrST_Xminus
    , instrIJMP, instrICALL
    ]

-- | Hardware multiply instructions (absent on most ATtiny devices).
avrMulInstrs :: AVR m pcW => [m ()]
avrMulInstrs = [ instrMUL, instrMULS ]

-- | 32-bit (two-word) instructions — JMP, CALL, LDS, STS.
avrExtInstrs :: AVR m pcW => [m ()]
avrExtInstrs = [ instrJMP, instrCALL, instrLDS, instrSTS ]

-- ---------------------------------------------------------------------------
-- ISADef builder and per-variant ISA definitions
-- ---------------------------------------------------------------------------

-- | Assemble an ISADef from a caller-supplied instruction list.
avrISAWith :: AVR m pcW => [m ()] -> ISADef m
avrISAWith instrs = defineISA ISADef
    { isaPc           = SomeCPURegister <$> cpu avrPC
    , isaInterruptEn  = cpu avrFlagI
    , isaInterruptVec = SomeCPURegister <$> cpu avrPC
    , isaContextSave  = [ saveWordReg avrPC, saveWordReg avrSP ]
    , isaSupervisor   = Nothing
    , isaReset        = do
        resetReg  avrPC 0x0000
        resetReg  avrSP 0x09FF  -- top of 2 KB SRAM (0x0200–0x09FF)
        resetFlag avrFlagC Lo
        resetFlag avrFlagZ Lo
        resetFlag avrFlagN Lo
        resetFlag avrFlagV Lo
        resetFlag avrFlagS Lo
        resetFlag avrFlagH Lo
        resetFlag avrFlagT Lo
        resetFlag avrFlagI Lo
    , isaInstrs       = instrs
    }

-- | ATtiny — 16-bit PC, core instructions only (no multiply, no 32-bit ops).
avrATtinyISA :: AVR m 16 => ISADef m
avrATtinyISA = avrISAWith avrCoreInstrs

-- | ATmega — 16-bit PC, full instruction set including multiply and 32-bit ops.
avrATmegaISA :: AVR m 16 => ISADef m
avrATmegaISA = avrISAWith (avrCoreInstrs ++ avrMulInstrs ++ avrExtInstrs)

-- | ATxmega / large AVR — 22-bit PC, full instruction set.
avrATxmegaISA :: AVR m 22 => ISADef m
avrATxmegaISA = avrISAWith (avrCoreInstrs ++ avrMulInstrs ++ avrExtInstrs)
