module Tests.AVR.InstructionSet where

import Prelude

import Test.Tasty
import Test.Tasty.TH
import Test.Tasty.Hedgehog
import qualified Hedgehog as H
import qualified Hedgehog.Gen as Gen
import qualified Hedgehog.Range as Range

import Clash.Prelude (BitVector)

import AVR.InstructionSet

-- ---------------------------------------------------------------------------
-- Generators
-- ---------------------------------------------------------------------------

genReg :: H.Gen Register
genReg = Gen.integral (Range.linear 0 31)

genUpperReg :: H.Gen UpperRegister
genUpperReg = Gen.integral (Range.linear 0 15)

genLowerUpperReg :: H.Gen LowerUpperRegister
genLowerUpperReg = Gen.integral (Range.linear 0 7)

genWideUpperReg :: H.Gen WideUpperRegister
genWideUpperReg = Gen.integral (Range.linear 0 3)

genWideReg :: H.Gen WideRegister
genWideReg = Gen.integral (Range.linear 0 15)

genBitSelect :: H.Gen BitSelect
genBitSelect = Gen.integral (Range.linear 0 7)

genImmediate :: H.Gen Immediate
genImmediate = Gen.integral (Range.linear 0 255)

genNibble :: H.Gen NibbleImmediate
genNibble = Gen.integral (Range.linear 0 15)

genShortImm :: H.Gen ShortImmediate
genShortImm = Gen.integral (Range.linear 0 63)

genWideImm :: H.Gen WideImmediate
genWideImm = Gen.integral (Range.linear 0 65535)

genMidImm :: H.Gen MidImmediate
genMidImm = Gen.integral (Range.linear (-64) 63)

genLowerIOReg :: H.Gen LowerIORegister
genLowerIOReg = Gen.integral (Range.linear 0 31)

genCodeAddr :: H.Gen CodeAddress
genCodeAddr = Gen.integral (Range.linear 0 4194303)

genRelCodeAddr :: H.Gen RelativeCodeAddress
genRelCodeAddr = Gen.integral (Range.linear (-2048) 2047)

-- | Indirect addressing modes.  XOffset is excluded: the AVR has no X+q
--   displacement mode and the encoder falls back to XIndirect for it.
genIndirectMode :: H.Gen IndirectAddressingMode
genIndirectMode = Gen.choice
    [ pure XIndirect
    , pure XIndirectPostIncrement
    , pure XIndirectPreDecrement
    , pure YIndirect
    , pure YIndirectPostIncrement
    , pure YIndirectPreDecrement
    , YOffset <$> genShortImm
    , pure ZIndirect
    , pure ZIndirectPostIncrement
    , pure ZIndirectPreDecrement
    , ZOffset <$> genShortImm
    ]

-- | SPM only supports these two modes.
genSpmMode :: H.Gen IndirectAddressingMode
genSpmMode = Gen.element [ZIndirect, ZIndirectPostIncrement]

-- | Canonical instructions: the subset of constructors whose encode→decode
--   round-trip is identity.
--
--   Excluded:
--     Brbc, Brbs  — these are never the first match in decodeInstruction;
--                   they always decode to a specific Brxx constructor instead.
--     Brlo, Brsh  — aliases for Brcs/Brcc (same opcode, decode gives Brcs/Brcc).
--     Sbr         — alias for Ori.
--     Seb, Clb    — aliases for Bset/Bclr.
genInstruction :: H.Gen Instruction
genInstruction = Gen.choice
    [ Adc     <$> genReg         <*> genReg
    , Add     <$> genReg         <*> genReg
    , Adiw    <$> genWideUpperReg <*> genShortImm
    , And     <$> genReg         <*> genReg
    , Andi    <$> genUpperReg    <*> genImmediate
    , Asr     <$> genReg
    , Bclr    <$> genBitSelect
    , Bld     <$> genReg         <*> genBitSelect
    , Brcc    <$> genMidImm
    , Brcs    <$> genMidImm
    , pure Break
    , Breq    <$> genMidImm
    , Brge    <$> genMidImm
    , Brhc    <$> genMidImm
    , Brhs    <$> genMidImm
    , Brid    <$> genMidImm
    , Brie    <$> genMidImm
    , Brlt    <$> genMidImm
    , Brmi    <$> genMidImm
    , Brne    <$> genMidImm
    , Brpl    <$> genMidImm
    , Brtc    <$> genMidImm
    , Brts    <$> genMidImm
    , Brvc    <$> genMidImm
    , Brvs    <$> genMidImm
    , Bset    <$> genBitSelect
    , Bst     <$> genReg         <*> genBitSelect
    , Call    <$> genCodeAddr
    , Cbi     <$> genLowerIOReg  <*> genBitSelect
    , Com     <$> genReg
    , Cp      <$> genReg         <*> genReg
    , Cpc     <$> genReg         <*> genReg
    , Cpi     <$> genUpperReg    <*> genImmediate
    , Cpse    <$> genReg         <*> genReg
    , Dec     <$> genReg
    , Des     <$> genNibble
    , pure Eicall
    , pure Eijmp
    , pure Elpm
    , ElpmZ   <$> genReg
    , ElpmZPlus <$> genReg
    , Eor     <$> genReg         <*> genReg
    , Fmul    <$> genLowerUpperReg <*> genLowerUpperReg
    , Fmuls   <$> genLowerUpperReg <*> genLowerUpperReg
    , Fmulsu  <$> genLowerUpperReg <*> genLowerUpperReg
    , pure Icall
    , pure Ijmp
    , In      <$> genReg         <*> genShortImm
    , Inc     <$> genReg
    , Jmp     <$> genCodeAddr
    , Lac     <$> genReg
    , Las     <$> genReg
    , Lat     <$> genReg
    , Ld      <$> genReg         <*> genIndirectMode
    , Ldi     <$> genUpperReg    <*> genImmediate
    , Lds     <$> genReg         <*> genWideImm
    , pure Lpm
    , LpmZ    <$> genReg
    , LpmZPlus <$> genReg
    , Lsr     <$> genReg
    , Mov     <$> genReg         <*> genReg
    , Movw    <$> genWideReg     <*> genWideReg
    , Mul     <$> genReg         <*> genReg
    , Muls    <$> genUpperReg    <*> genUpperReg
    , Mulsu   <$> genLowerUpperReg <*> genLowerUpperReg
    , Neg     <$> genReg
    , pure Nop
    , Or      <$> genReg         <*> genReg
    , Ori     <$> genUpperReg    <*> genImmediate
    , Out     <$> genShortImm    <*> genReg
    , Pop     <$> genReg
    , Push    <$> genReg
    , Rcall   <$> genRelCodeAddr
    , pure Ret
    , pure Reti
    , Rjmp    <$> genRelCodeAddr
    , Ror     <$> genReg
    , Sbc     <$> genReg         <*> genReg
    , Sbci    <$> genUpperReg    <*> genImmediate
    , Sbi     <$> genLowerIOReg  <*> genBitSelect
    , Sbic    <$> genLowerIOReg  <*> genBitSelect
    , Sbis    <$> genLowerIOReg  <*> genBitSelect
    , Sbiw    <$> genWideUpperReg <*> genShortImm
    , Sbrc    <$> genReg         <*> genBitSelect
    , Sbrs    <$> genReg         <*> genBitSelect
    , pure Sleep
    , Spm     <$> genSpmMode
    , St      <$> genReg         <*> genIndirectMode
    , Sts     <$> genWideImm     <*> genReg
    , Sub     <$> genReg         <*> genReg
    , Subi    <$> genUpperReg    <*> genImmediate
    , Swap    <$> genReg
    , pure Wdr
    , Xch     <$> genReg
    ]

-- ---------------------------------------------------------------------------
-- Properties
-- ---------------------------------------------------------------------------

-- | encode then decode recovers the original instruction for all canonical
--   constructors.
prop_roundTrip :: H.Property
prop_roundTrip = H.property $ do
    instr <- H.forAll genInstruction
    decodeInstruction (encodeInstruction instr) H.=== instr

-- | Two-word instructions report instrWords == 2; all others report 1.
prop_instrWordsConsistent :: H.Property
prop_instrWordsConsistent = H.property $ do
    instr <- H.forAll genInstruction
    let w = instrWords instr
    case instr of
        Call _ -> w H.=== 2
        Jmp  _ -> w H.=== 2
        Lds  _ _ -> w H.=== 2
        Sts  _ _ -> w H.=== 2
        _        -> w H.=== 1

-- | Aliases encode to the same opcode as their canonical counterpart.
prop_aliasesMatchCanonical :: H.Property
prop_aliasesMatchCanonical = H.property $ do
    rd <- H.forAll genUpperReg
    k  <- H.forAll genImmediate
    s  <- H.forAll genBitSelect
    kk <- H.forAll genMidImm
    encodeInstruction (Sbr rd k) H.=== encodeInstruction (Ori rd k)
    encodeInstruction (Seb s)    H.=== encodeInstruction (Bset s)
    encodeInstruction (Clb s)    H.=== encodeInstruction (Bclr s)
    encodeInstruction (Brlo kk)  H.=== encodeInstruction (Brcs kk)
    encodeInstruction (Brsh kk)  H.=== encodeInstruction (Brcc kk)

-- ---------------------------------------------------------------------------
-- Known encodings (verified against AVR datasheet opcode tables)
-- ---------------------------------------------------------------------------

-- | Test that specific instructions encode to the expected 32-bit value
--   (upper 16 bits = opcode, lower 16 bits = second word or 0x0000).
prop_knownEncodings :: H.Property
prop_knownEncodings = H.withTests 1 . H.property $ do
    let check expected instr =
            H.annotateShow instr >>
            encodeInstruction instr H.=== (expected :: BitVector 32)

    -- Fixed-opcode instructions
    check 0x00000000 Nop
    check 0x95080000 Ret
    check 0x95180000 Reti
    check 0x95980000 Break
    check 0x95880000 Sleep
    check 0x95A80000 Wdr
    check 0x95C80000 Lpm
    check 0x95D80000 Elpm
    check 0x94090000 Ijmp
    check 0x95090000 Icall
    check 0x94190000 Eijmp
    check 0x95190000 Eicall
    check 0x95E80000 (Spm ZIndirect)
    check 0x95F80000 (Spm ZIndirectPostIncrement)

    -- Binary register ops: ADD Rd, Rr = 0000 11 rr[4] rd[4] rd[3:0] rr[3:0]
    check 0x0C000000 (Add 0 0)    -- R0 + R0
    check 0x0C120000 (Add 1 2)    -- R1 + R2:  r[4]=0 d[4]=0 d=0001 r=0010
    check 0x0F010000 (Add 16 17)  -- R16+R17:  r[4]=1 d[4]=1 d=0000 r=0001

    -- ADC same structure, prefix 0001 11
    check 0x1C000000 (Adc 0 0)
    check 0x1F010000 (Adc 16 17)

    -- Upper-reg + immediate: LDI Rd, K = 1110 K[7:4] d[3:0] K[3:0]
    check 0xE0000000 (Ldi 0 0)      -- LDI R16, 0
    check 0xEF0F0000 (Ldi 0 0xFF)   -- LDI R16, 255
    check 0xE5330000 (Ldi 3 0x53)   -- LDI R19, 0x53: d=3 k=0x53=0101 0011

    -- RJMP k = 1100 kkkk kkkk kkkk
    check 0xC0000000 (Rjmp 0)
    check 0xCFFF0000 (Rjmp (-1))
    check 0xC0010000 (Rjmp 1)

    -- BRNE k (s=1, x=1) = 1111 01 k[6:5] k[4:0] 001
    check 0xF4010000 (Brne 0)    -- k=0: 1111 0100 0000 0001 = 0xF401
    check 0xF4110000 (Brne 2)    -- k=2=0b0000010: 1111 0100 0001 0001 = 0xF411

    -- BSET/BCLR s = 1001 0100 0/1 sss 1000
    check 0x94080000 (Bset 0)   -- SEC:  1001 0100 0000 1000
    check 0x94180000 (Bset 1)   -- SEZ
    check 0x94880000 (Bclr 0)   -- CLC:  1001 0100 1000 1000
    check 0x94980000 (Bclr 1)   -- CLZ

    -- IN/OUT: 1011 0/1 A[5:4] r[4] r[3:0] A[3:0]
    check 0xB0000000 (In 0 0)     -- IN R0, 0x00
    check 0xB60F0000 (In 0 63)    -- IN R0, 0x3F: A=63=111111 ahi=11 alo=1111

    -- ADIW Rd, K = 1001 0110 K[5:4] dd K[3:0]
    check 0x96000000 (Adiw 0 0)   -- ADIW R24, 0
    check 0x96DF0000 (Adiw 1 63)  -- ADIW R26, 63: dd=01 K=63=111111

    -- JMP k (2 words): word0=1001 010 k[21] k[20:17] 110 k[16], word1=k[15:0]
    check 0x940C0000 (Jmp 0)
    check 0x940C0001 (Jmp 1)       -- k=1: k[16:0]=0..01, k[15:0]=0x0001
    check 0x940E0001 (Call 1)      -- CALL 1: same but 111 suffix

    -- LDS/STS (2 words)
    check 0x90000000 (Lds 0 0)     -- LDS R0, 0x0000
    check 0x90001234 (Lds 0 0x1234)
    check 0x92001234 (Sts 0x1234 0) -- STS 0x1234, R0

instrTests :: TestTree
instrTests = $(testGroupGenerator)
