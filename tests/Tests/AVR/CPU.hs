module Tests.AVR.CPU where

import Prelude

import Test.Tasty
import Test.Tasty.TH
import Test.Tasty.Hedgehog
import qualified Hedgehog as H

import Clash.Prelude (BitVector, Bit, Unsigned)

import AVR.Core  (zeroState, CoreData(..), StatusRegister(..))
import AVR.ALU   (getReg)
import AVR.Exec  (runLinear, runWithPC)
import AVR.CPU   (CPUState(..), cpuStep, Stage(..))

-- ---------------------------------------------------------------------------
-- Linear ALU test
-- Source: tests/fixtures/basic.S   assembled with avr-as -mmcu=atmega2560
-- ---------------------------------------------------------------------------

basicProgram :: [BitVector 16]
basicProgram =
    [ 0xE005  -- ldi  r16, 0x05
    , 0xE013  -- ldi  r17, 0x03
    , 0x0F01  -- add  r16, r17
    , 0xE02A  -- ldi  r18, 0x0A
    , 0x1B21  -- sub  r18, r17
    , 0xEF3F  -- ldi  r19, 0xFF
    , 0xE04F  -- ldi  r20, 0x0F
    , 0x2334  -- and  r19, r20
    , 0xEF50  -- ldi  r21, 0xF0
    , 0xE06F  -- ldi  r22, 0x0F
    , 0x2B56  -- or   r21, r22
    , 0xEA7A  -- ldi  r23, 0xAA
    , 0xE585  -- ldi  r24, 0x55
    , 0x2778  -- eor  r23, r24
    , 0xE79F  -- ldi  r25, 0x7F
    , 0x9593  -- inc  r25
    , 0xE8A0  -- ldi  r26, 0x80
    , 0x95A6  -- lsr  r26
    , 0xE0B1  -- ldi  r27, 0x01
    , 0x95B1  -- neg  r27
    , 0xEACA  -- ldi  r28, 0xAA
    , 0x95C0  -- com  r28
    , 0x2FD0  -- mov  r29, r16
    , 0x01F8  -- movw r30, r16   (r31:r30 ← r17:r16)
    , 0x0000  -- nop
    ]

prop_basicProgram :: H.Property
prop_basicProgram = H.withTests 1 . H.property $ do
    let final = runLinear basicProgram (zeroState :: CoreData 22)
    let r n = getReg final n
    r 16 H.=== 0x08   -- 5 + 3
    r 17 H.=== 0x03
    r 18 H.=== 0x07   -- 10 - 3
    r 19 H.=== 0x0F   -- 0xFF & 0x0F
    r 20 H.=== 0x0F
    r 21 H.=== 0xFF   -- 0xF0 | 0x0F
    r 22 H.=== 0x0F
    r 23 H.=== 0xFF   -- 0xAA ^ 0x55
    r 24 H.=== 0x55
    r 25 H.=== 0x80   -- 0x7F + 1
    r 26 H.=== 0x40   -- 0x80 >> 1
    r 27 H.=== 0xFF   -- neg 0x01
    r 28 H.=== 0x55   -- com 0xAA
    r 29 H.=== 0x08   -- mov r29, r16
    r 30 H.=== 0x08   -- movw: low  (r16)
    r 31 H.=== 0x03   -- movw: high (r17)

-- ---------------------------------------------------------------------------
-- Jump / branch test
-- Source: tests/fixtures/jump_test.S
--   assembled: avr-as -mmcu=atmega2560 jump_test.S -o jump_test.o
--   linked:    avr-ld -mavr6 -Ttext 0 jump_test.o -o jump_test.elf
--
-- Program:
--   ldi r16,5 ; ldi r17,0 ; ldi r18,0xFF
--   rjmp loop            ; k=1, skips the ldi r18,0x00 below
--   ldi r18,0x00         ; SKIPPED
-- loop:
--   add r17,r16 ; dec r16 ; brne loop   ; k=-3
--   nop
--
-- Expected: R16=0, R17=0x0F (5+4+3+2+1=15), R18=0xFF (skip preserved it)
-- ---------------------------------------------------------------------------

jumpProgram :: [BitVector 16]
jumpProgram =
    [ 0xE005  -- word 0: ldi  r16, 5
    , 0xE010  -- word 1: ldi  r17, 0
    , 0xEF2F  -- word 2: ldi  r18, 0xFF
    , 0xC001  -- word 3: rjmp .+2  (k=1, jumps to word 5 = loop)
    , 0xE020  -- word 4: ldi  r18, 0x00  (skipped by rjmp)
    , 0x0F10  -- word 5: add  r17, r16   (loop:)
    , 0x950A  -- word 6: dec  r16
    , 0xF7E9  -- word 7: brne .-6  (k=-3, loops back to word 5)
    , 0x0000  -- word 8: nop
    ]

prop_jumpProgram :: H.Property
prop_jumpProgram = H.withTests 1 . H.property $ do
    let prog  = jumpProgram
        final = runWithPC prog (fromIntegral (length prog)) (zeroState :: CoreData 22)
    let r n = getReg final n
    r 16 H.=== 0x00   -- counter decremented to zero
    r 17 H.=== 0x0F   -- sum 5+4+3+2+1 = 15
    r 18 H.=== 0xFF   -- skipped ldi 0x00; original value preserved

-- ---------------------------------------------------------------------------
-- Interrupt tests
-- ---------------------------------------------------------------------------

-- | When SREG.I=1 and an interrupt vector arrives, the CPU should:
--     1. Clear SREG.I immediately (in the same step that accepts the interrupt)
--     2. Push the current PC onto the stack and jump to the vector
--        (two pipeline steps total: SFetch1 → SCallPush2 → SFetch1@vector)
prop_interruptAccepted :: H.Property
prop_interruptAccepted = H.withTests 1 . H.property $ do
    let base  = zeroState :: CoreData 16
        iCore = base { status = (status base) { interrupt_flag = 1 } }
        s0    = CPUState iCore SFetch1
    -- Step 1: vector 0x0010 asserted while I=1 → CPU accepts, I-bit cleared
    let (s1, _) = cpuStep s0 (0x0000, 0x00, Just (0x0010 :: Unsigned 16))
    interrupt_flag (status (cpuCore s1)) H.=== (0 :: Bit)
    -- Step 2: second push completes → PC = vector, back to SFetch1
    let (s2, _) = cpuStep s1 (0x0000, 0x00, Nothing)
    cpuStage s2          H.=== SFetch1
    pc (cpuCore s2)      H.=== (0x0010 :: Unsigned 16)

-- | RETI must re-enable the global interrupt flag.
--   Tested via the software-level simulator (ALU path) since the pipeline
--   path's SREG.I restore is already exercised by SRetRead2 in avrCore.
prop_retiRestoresI :: H.Property
prop_retiRestoresI = H.withTests 1 . H.property $ do
    let base      = zeroState :: CoreData 16
        disabledI = base { status = (status base) { interrupt_flag = 0 } }
        finalCore = runWithPC [0x9518] 1 disabledI   -- 0x9518 = RETI
    interrupt_flag (status finalCore) H.=== (1 :: Bit)

cpuTests :: TestTree
cpuTests = $(testGroupGenerator)
