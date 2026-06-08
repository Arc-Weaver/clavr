{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE OverloadedStrings #-}

module AVR.InstructionSet where


import Clash.Sized.Unsigned
import Clash.Prelude
   

type BitSelect = Unsigned 3

type ShortImmediate = Unsigned 6 -- for 0 to 63 
type StubImmediate = Unsigned 7 -- for 0 to 127
type WideImmediate = Unsigned 16 -- for 0 to 65535
type MidImmediate = Signed 7 -- for -64 to +63
type Immediate = Unsigned 8  -- for 0 to 255
type NibbleImmediate = Unsigned 4 -- for 0 to 15

type Register = Unsigned 5 
type UpperRegister = Unsigned 4
type LowerRegister = Unsigned 4
type LowerUpperRegister = Unsigned 3
type WideRegister = Unsigned 4
type WideUpperRegister = Unsigned 2
type WideLowerRegister = Unsigned 2
type LowerIORegister = Unsigned 5 

type CodeAddress = Unsigned 22
type RelativeCodeAddress = Signed 12

data IndirectAddressingMode = 
    XIndirect -- X
    | XIndirectPostIncrement -- X+
    | XIndirectPreDecrement -- -X
    | XOffset ShortImmediate -- X+q
    | YIndirect -- Y
    | YIndirectPostIncrement -- Y+
    | YIndirectPreDecrement -- -Y
    | YOffset ShortImmediate -- Y+q
    | ZIndirect -- Z
    | ZIndirectPostIncrement -- Z+
    | ZIndirectPreDecrement -- -Z
    | ZOffset ShortImmediate -- Z+q
    deriving (Show, Eq, Generic, NFDataX)

data Instruction = 
    Adc Register Register -- ADC Rd, Rr
    | Add Register Register -- ADD Rd, Rr
    | Adiw WideUpperRegister ShortImmediate -- ADIW Rd, K
    | And Register Register -- AND Rd, Rr
    | Andi UpperRegister Immediate -- ANDI Rd, K
    | Asr Register -- ASR Rd
    | Bclr BitSelect -- BCLR s
    | Bld Register BitSelect -- BLD Rd, s
    | Brbc BitSelect MidImmediate  -- BRBC s, k
    | Brbs BitSelect MidImmediate -- BRBS s, k
    | Brcc MidImmediate -- BRCC k
    | Brcs MidImmediate -- BRCS k
    | Break -- BREAK
    | Breq MidImmediate -- BREQ k
    | Brge MidImmediate -- BRGE k
    | Brhc MidImmediate -- BRHC k
    | Brhs MidImmediate -- BRHS k
    | Brid MidImmediate -- BRID k
    | Brie MidImmediate -- BRIE k
    | Brlo MidImmediate -- BRLO k
    | Brlt MidImmediate -- BRLT k
    | Brmi MidImmediate -- BRMI k
    | Brne MidImmediate -- BRNE k
    | Brpl MidImmediate -- BRPL k
    | Brsh MidImmediate -- BRSH k
    | Brtc MidImmediate -- BRTC k
    | Brts MidImmediate -- BRTS k
    | Brvc MidImmediate -- BRVC k
    | Brvs MidImmediate -- BRVS k
    | Bset BitSelect -- BSET s
    | Bst Register BitSelect -- BST Rd, s
    | Call CodeAddress -- CALL k
    | Cbi LowerIORegister BitSelect -- CBI A, b
    -- | Cbr UpperRegister Immediate -- CBR Rd, K (implmented by ANDI Rd, ~K)
    | Clb BitSelect -- CLB s, implements CLZ, CLN, CLS, CLT, CLV, CLC, CLH, CLI
  --  | Clr Register -- CLR Rd (implemented by EOR Rd, Rd)
    | Com Register -- COM Rd
    | Cp Register Register -- CP Rd, Rr
    | Cpc Register Register -- CPC Rd, Rr
    | Cpi UpperRegister Immediate -- CPI Rd, K
    | Cpse Register Register -- CPSE Rd, Rr
    | Dec Register -- DEC Rd
    | Des NibbleImmediate -- DES K
    | Eicall -- EICALL
    | Eijmp -- EIJMP
    | Elpm -- ELPM
    | ElpmZ Register -- ELPM Rd, Z
    | ElpmZPlus Register -- ELPM Rd, Z+
    | Eor Register Register -- EOR Rd, Rr
    | Fmul LowerUpperRegister LowerUpperRegister -- FMUL Rd, Rr
    | Fmuls LowerUpperRegister LowerUpperRegister -- FMULS Rd, Rr
    | Fmulsu LowerUpperRegister LowerUpperRegister -- FMULSU Rd, Rr
    | Icall -- ICALL
    | Ijmp -- IJMP
    | In Register ShortImmediate -- IN Rd, A
    | Inc Register -- INC Rd
    | Jmp CodeAddress -- JMP k
    | Lac Register -- LAC Rd
    | Las Register -- LAS Rd
    | Lat Register -- LAT Rd
    | Ld Register IndirectAddressingMode-- LD Rd, Z
    | Ldi UpperRegister Immediate -- LDI Rd, K
    | Lds Register WideImmediate -- LDS Rd, k
    | Lpm -- LPM
    | LpmZ Register -- LPM Rd, Z
    | LpmZPlus Register -- LPM Rd, Z+
   -- | Lsl Register -- LSL Rd (implemented by ADD Rd, Rd)
    | Lsr Register -- LSR Rd
    | Mov Register Register -- MOV Rd, Rr
    | Movw WideRegister WideRegister -- MOVW Rd, Rr
    | Mul Register Register -- MUL Rd, Rr
    | Muls UpperRegister UpperRegister -- MULS Rd, Rr
    | Mulsu LowerUpperRegister LowerUpperRegister -- MULSU Rd, Rr
    | Neg Register -- NEG Rd
    | Nop -- NOP
    | Or Register Register -- OR Rd, Rr
    | Ori UpperRegister Immediate -- ORI Rd, K
    | Out ShortImmediate Register -- OUT A, Rr
    | Pop Register -- POP Rd
    | Push Register -- PUSH Rd
    | Rcall RelativeCodeAddress -- RCALL k
    | Ret -- RET
    | Reti -- RETI
    | Rjmp RelativeCodeAddress -- RJMP k
  --  | Rol Register -- ROL Rd (implemented by ADC Rd, Rd)
    | Ror Register -- ROR Rd
    | Sbc Register Register -- SBC Rd, Rr
    | Sbci UpperRegister Immediate -- SBCI Rd, K
    | Sbi LowerIORegister BitSelect -- SBI A, b
    | Sbic LowerIORegister BitSelect -- SBIC A, b
    | Sbis LowerIORegister BitSelect -- SBIS A, b
    | Sbiw WideUpperRegister ShortImmediate -- SBIW Rd, K
    | Sbr UpperRegister Immediate -- SBR Rd, K
    | Sbrc Register BitSelect -- SBRC Rd, b
    | Sbrs Register BitSelect -- SBRS Rd, b
    | Seb BitSelect -- SEB s -- Implements SEZ, SEV, SET, SES, SEN, SEI, SEH, SEC
 ---   | Ser Register -- SER Rd (implemented by LDI Rd, 0xFF)
    | Sleep -- SLEEP
    | Spm IndirectAddressingMode -- SPM
    | St Register IndirectAddressingMode -- ST Am, Rd
    | Sts WideImmediate Register -- STS k, Rd
    | Sub Register Register -- SUB Rd, Rr
    | Subi UpperRegister Immediate -- SUBI Rd, K
    | Swap Register -- SWAP Rd
  --  | Tst Register -- TST Rd (implemented by AND Rd, Rd)
    | Wdr -- WDR
    | Xch Register -- XCH Rd
    deriving (Show, Eq, Generic, NFDataX)


instance BitPack Instruction where
    type BitSize Instruction = 32
    pack = encodeInstruction
    unpack = decodeInstruction

decodeInstruction :: BitVector 32 -> Instruction
decodeInstruction $(bitPattern "0001_11rd_dddd_rrrr_...._...._...._....") = Adc (unpack ddddd) (unpack rrrrr)
decodeInstruction $(bitPattern "0000_11rd_dddd_rrrr_...._...._...._....") = Add (unpack ddddd) (unpack rrrrr)
decodeInstruction $(bitPattern "1001_0110_kkdd_kkkk_...._...._...._....") = Adiw (unpack dd) (unpack kkkkkk)
decodeInstruction $(bitPattern "0010_00rd_dddd_rrrr_...._...._...._....") = AVR.InstructionSet.And (unpack ddddd) (unpack rrrrr)
decodeInstruction $(bitPattern "0111_kkkk_dddd_kkkk_...._...._...._....") = Andi (unpack dddd) (unpack kkkkkkkk)
decodeInstruction $(bitPattern "1001_010d_dddd_0101_...._...._...._....") = Asr (unpack ddddd)
decodeInstruction $(bitPattern "1001_0100_1sss_1000_...._...._...._....") = Bclr (unpack sss)
decodeInstruction $(bitPattern "1111_100d_dddd_0bbb_...._...._...._....") = Bld (unpack ddddd) (unpack bbb)
-- Specific branches first: Brbc/Brbs are more general and must come after
decodeInstruction $(bitPattern "1111_01kk_kkkk_k000_...._...._...._....") = Brcc (unpack kkkkkkk)
decodeInstruction $(bitPattern "1111_00kk_kkkk_k000_...._...._...._....") = Brcs (unpack kkkkkkk)
decodeInstruction $(bitPattern "1001_0101_1001_1000_...._...._...._....") = Break
decodeInstruction $(bitPattern "1111_00kk_kkkk_k001_...._...._...._....") = Breq (unpack kkkkkkk)
decodeInstruction $(bitPattern "1111_01kk_kkkk_k100_...._...._...._....") = Brge (unpack kkkkkkk)
decodeInstruction $(bitPattern "1111_01kk_kkkk_k101_...._...._...._....") = Brhc (unpack kkkkkkk)
decodeInstruction $(bitPattern "1111_00kk_kkkk_k101_...._...._...._....") = Brhs (unpack kkkkkkk)
decodeInstruction $(bitPattern "1111_01kk_kkkk_k111_...._...._...._....") = Brid (unpack kkkkkkk)
decodeInstruction $(bitPattern "1111_00kk_kkkk_k111_...._...._...._....") = Brie (unpack kkkkkkk)
decodeInstruction $(bitPattern "1111_00kk_kkkk_k100_...._...._...._....") = Brlt (unpack kkkkkkk)
decodeInstruction $(bitPattern "1111_00kk_kkkk_k010_...._...._...._....") = Brmi (unpack kkkkkkk)
decodeInstruction $(bitPattern "1111_01kk_kkkk_k001_...._...._...._....") = Brne (unpack kkkkkkk)
decodeInstruction $(bitPattern "1111_01kk_kkkk_k010_...._...._...._....") = Brpl (unpack kkkkkkk)
decodeInstruction $(bitPattern "1111_01kk_kkkk_k110_...._...._...._....") = Brtc (unpack kkkkkkk)
decodeInstruction $(bitPattern "1111_00kk_kkkk_k110_...._...._...._....") = Brts (unpack kkkkkkk)
decodeInstruction $(bitPattern "1111_01kk_kkkk_k011_...._...._...._....") = Brvc (unpack kkkkkkk)
decodeInstruction $(bitPattern "1111_00kk_kkkk_k011_...._...._...._....") = Brvs (unpack kkkkkkk)
-- Generic BRBC/BRBS: unreachable (all s values covered above) but kept for completeness
decodeInstruction $(bitPattern "1111_01kk_kkkk_ksss_...._...._...._....") = Brbc (unpack sss) (unpack kkkkkkk)
decodeInstruction $(bitPattern "1111_00kk_kkkk_ksss_...._...._...._....") = Brbs (unpack sss) (unpack kkkkkkk)
decodeInstruction $(bitPattern "1001_0100_0sss_1000_...._...._...._....") = Bset (unpack sss)
decodeInstruction $(bitPattern "1111_101d_dddd_0bbb_...._...._...._....") = Bst (unpack ddddd) (unpack bbb)
decodeInstruction $(bitPattern "1001_010k_kkkk_111k_kkkk_kkkk_kkkk_kkkk") = Call (unpack kkkkkkkkkkkkkkkkkkkkkk)
decodeInstruction $(bitPattern "1001_1000_aaaa_abbb_...._...._...._....") = Cbi (unpack aaaaa) (unpack bbb)
decodeInstruction $(bitPattern "1001_010d_dddd_0000_...._...._...._....") = Com (unpack ddddd)
decodeInstruction $(bitPattern "0001_01rd_dddd_rrrr_...._...._...._....") = Cp (unpack ddddd) (unpack rrrrr)
decodeInstruction $(bitPattern "0000_01rd_dddd_rrrr_...._...._...._....") = Cpc (unpack ddddd) (unpack rrrrr)
decodeInstruction $(bitPattern "0011_kkkk_dddd_kkkk_...._...._...._....") = Cpi (unpack dddd) (unpack kkkkkkkk)
decodeInstruction $(bitPattern "0001_00rd_dddd_rrrr_...._...._...._....") = Cpse (unpack ddddd) (unpack rrrrr)
decodeInstruction $(bitPattern "1001_010d_dddd_1010_...._...._...._....") = Dec (unpack ddddd)
decodeInstruction $(bitPattern "1001_0100_kkkk_1011_...._...._...._....") = Des (unpack kkkk)
decodeInstruction $(bitPattern "1001_0101_0001_1001_...._...._...._....") = Eicall
decodeInstruction $(bitPattern "1001_0100_0001_1001_...._...._...._....") = Eijmp
decodeInstruction $(bitPattern "1001_0101_1101_1000_...._...._...._....") = Elpm
decodeInstruction $(bitPattern "1001_000d_dddd_0110_...._...._...._....") = ElpmZ (unpack ddddd)
decodeInstruction $(bitPattern "1001_000d_dddd_0111_...._...._...._....") = ElpmZPlus (unpack ddddd)
decodeInstruction $(bitPattern "0010_01rd_dddd_rrrr_...._...._...._....") = Eor (unpack ddddd) (unpack rrrrr)
decodeInstruction $(bitPattern "0000_0011_0ddd_1rrr_...._...._...._....") = Fmul (unpack ddd) (unpack rrr)
decodeInstruction $(bitPattern "0000_0011_1ddd_0rrr_...._...._...._....") = Fmuls (unpack ddd) (unpack rrr)
decodeInstruction $(bitPattern "0000_0011_1ddd_1rrr_...._...._...._....") = Fmulsu (unpack ddd) (unpack rrr)
decodeInstruction $(bitPattern "1001_0101_0000_1001_...._...._...._....") = Icall
decodeInstruction $(bitPattern "1001_0100_0000_1001_...._...._...._....") = Ijmp
decodeInstruction $(bitPattern "1011_0aad_dddd_aaaa_...._...._...._....") = In (unpack ddddd) (unpack aaaaaa)
decodeInstruction $(bitPattern "1001_010d_dddd_0011_...._...._...._....") = Inc (unpack ddddd)
decodeInstruction $(bitPattern "1001_010k_kkkk_110k_kkkk_kkkk_kkkk_kkkk") = Jmp (unpack kkkkkkkkkkkkkkkkkkkkkk)
decodeInstruction $(bitPattern "1001_001r_rrrr_0110_...._...._...._....") = Lac (unpack rrrrr)
decodeInstruction $(bitPattern "1001_001r_rrrr_0101_...._...._...._....") = Las (unpack rrrrr)
decodeInstruction $(bitPattern "1001_001r_rrrr_0111_...._...._...._....") = Lat (unpack rrrrr)
decodeInstruction $(bitPattern "1001_000d_dddd_1100_...._...._...._....") = Ld (unpack ddddd) XIndirect
decodeInstruction $(bitPattern "1001_000d_dddd_1101_...._...._...._....") = Ld (unpack ddddd) XIndirectPostIncrement
decodeInstruction $(bitPattern "1001_000d_dddd_1110_...._...._...._....") = Ld (unpack ddddd) XIndirectPreDecrement
decodeInstruction $(bitPattern "1000_000d_dddd_1000_...._...._...._....") = Ld (unpack ddddd) YIndirect
decodeInstruction $(bitPattern "1001_000d_dddd_1001_...._...._...._....") = Ld (unpack ddddd) YIndirectPostIncrement
decodeInstruction $(bitPattern "1001_000d_dddd_1010_...._...._...._....") = Ld (unpack ddddd) YIndirectPreDecrement
decodeInstruction $(bitPattern "10q0_qq0d_dddd_1qqq_...._...._...._....") = Ld (unpack ddddd) $ YOffset (unpack qqqqqq)
decodeInstruction $(bitPattern "1000_000d_dddd_0000_...._...._...._....") = Ld (unpack ddddd) ZIndirect
decodeInstruction $(bitPattern "1001_000d_dddd_0001_...._...._...._....") = Ld (unpack ddddd) ZIndirectPostIncrement
decodeInstruction $(bitPattern "1001_000d_dddd_0010_...._...._...._....") = Ld (unpack ddddd) ZIndirectPreDecrement
decodeInstruction $(bitPattern "10q0_qq0d_dddd_0qqq_...._...._...._....") = Ld (unpack ddddd) $ ZOffset (unpack qqqqqq)
decodeInstruction $(bitPattern "1110_kkkk_dddd_kkkk_...._...._...._....") = Ldi (unpack dddd) (unpack kkkkkkkk)
decodeInstruction $(bitPattern "1001_000d_dddd_0000_kkkk_kkkk_kkkk_kkkk") = Lds (unpack ddddd) (unpack kkkkkkkkkkkkkkkk)
decodeInstruction $(bitPattern "1001_0101_1100_1000_...._...._...._....") = Lpm
decodeInstruction $(bitPattern "1001_000d_dddd_0100_...._...._...._....") = LpmZ (unpack ddddd)
decodeInstruction $(bitPattern "1001_000d_dddd_0101_...._...._...._....") = LpmZPlus (unpack ddddd)
decodeInstruction $(bitPattern "1001_010d_dddd_0110_...._...._...._....") = Lsr (unpack ddddd)
decodeInstruction $(bitPattern "0010_11rd_dddd_rrrr_...._...._...._....") = Mov (unpack ddddd) (unpack rrrrr)
decodeInstruction $(bitPattern "0000_0001_dddd_rrrr_...._...._...._....") = Movw (unpack dddd) (unpack rrrr)
decodeInstruction $(bitPattern "1001_11rd_dddd_rrrr_...._...._...._....") = Mul (unpack ddddd) (unpack rrrrr)
decodeInstruction $(bitPattern "0000_0010_dddd_rrrr_...._...._...._....") = Muls (unpack dddd) (unpack rrrr)
decodeInstruction $(bitPattern "0000_0011_0ddd_0rrr_...._...._...._....") = Mulsu (unpack ddd) (unpack rrr)
decodeInstruction $(bitPattern "1001_010d_dddd_0001_...._...._...._....") = Neg (unpack ddddd)
decodeInstruction $(bitPattern "0000_0000_0000_0000_...._...._...._....") = Nop
decodeInstruction $(bitPattern "0010_10rd_dddd_rrrr_...._...._...._....") = Or (unpack ddddd) (unpack rrrrr)
decodeInstruction $(bitPattern "0110_kkkk_dddd_kkkk_...._...._...._....") = Ori (unpack dddd) (unpack kkkkkkkk)
decodeInstruction $(bitPattern "1011_1aar_rrrr_aaaa_...._...._...._....") = Out (unpack aaaaaa) (unpack rrrrr)
decodeInstruction $(bitPattern "1001_000d_dddd_1111_...._...._...._....") = Pop (unpack ddddd)
decodeInstruction $(bitPattern "1001_001d_dddd_1111_...._...._...._....") = Push (unpack ddddd)
decodeInstruction $(bitPattern "1101_kkkk_kkkk_kkkk_...._...._...._....") = Rcall (unpack kkkkkkkkkkkk)
decodeInstruction $(bitPattern "1001_0101_0000_1000_...._...._...._....") = Ret
decodeInstruction $(bitPattern "1001_0101_0001_1000_...._...._...._....") = Reti
decodeInstruction $(bitPattern "1100_kkkk_kkkk_kkkk_...._...._...._....") = Rjmp (unpack kkkkkkkkkkkk)
decodeInstruction $(bitPattern "1001_010d_dddd_0111_...._...._...._....") = Ror (unpack ddddd)
decodeInstruction $(bitPattern "0000_10rd_dddd_rrrr_...._...._...._....") = Sbc (unpack ddddd) (unpack rrrrr)
decodeInstruction $(bitPattern "0100_kkkk_dddd_kkkk_...._...._...._....") = Sbci (unpack dddd) (unpack kkkkkkkk)
decodeInstruction $(bitPattern "1001_1010_aaaa_abbb_...._...._...._....") = Sbi (unpack aaaaa) (unpack bbb)
decodeInstruction $(bitPattern "1001_1001_aaaa_abbb_...._...._...._....") = Sbic (unpack aaaaa) (unpack bbb)
decodeInstruction $(bitPattern "1001_1011_aaaa_abbb_...._...._...._....") = Sbis (unpack aaaaa) (unpack bbb)
decodeInstruction $(bitPattern "1001_0111_kkdd_kkkk_...._...._...._....") = Sbiw (unpack dd) (unpack kkkkkk)
decodeInstruction $(bitPattern "1111_110r_rrrr_0bbb_...._...._...._....") = Sbrc (unpack rrrrr) (unpack bbb)
decodeInstruction $(bitPattern "1111_111r_rrrr_0bbb_...._...._...._....") = Sbrs (unpack rrrrr) (unpack bbb)
decodeInstruction $(bitPattern "1001_0101_1000_1000_...._...._...._....") = Sleep
decodeInstruction $(bitPattern "1001_0101_1110_1000_...._...._...._....") = Spm ZIndirect 
decodeInstruction $(bitPattern "1001_0101_1111_1000_...._...._...._....") = Spm ZIndirectPostIncrement
decodeInstruction $(bitPattern "1001_001r_rrrr_1100_...._...._...._....") = St (unpack rrrrr) XIndirect
decodeInstruction $(bitPattern "1001_001r_rrrr_1101_...._...._...._....") = St (unpack rrrrr) XIndirectPostIncrement
decodeInstruction $(bitPattern "1001_001r_rrrr_1110_...._...._...._....") = St (unpack rrrrr) XIndirectPreDecrement
decodeInstruction $(bitPattern "1000_001r_rrrr_1000_...._...._...._....") = St (unpack rrrrr) YIndirect
decodeInstruction $(bitPattern "1001_001r_rrrr_1001_...._...._...._....") = St (unpack rrrrr) YIndirectPostIncrement
decodeInstruction $(bitPattern "1001_001r_rrrr_1010_...._...._...._....") = St (unpack rrrrr) YIndirectPreDecrement
decodeInstruction $(bitPattern "10q0_qq1r_rrrr_1qqq_...._...._...._....") = St (unpack rrrrr) $ YOffset (unpack qqqqqq)
decodeInstruction $(bitPattern "1000_001r_rrrr_0000_...._...._...._....") = St (unpack rrrrr) ZIndirect
decodeInstruction $(bitPattern "1001_001r_rrrr_0001_...._...._...._....") = St (unpack rrrrr) ZIndirectPostIncrement
decodeInstruction $(bitPattern "1001_001r_rrrr_0010_...._...._...._....") = St (unpack rrrrr) ZIndirectPreDecrement
decodeInstruction $(bitPattern "10q0_qq1r_rrrr_0qqq_...._...._...._....") = St (unpack rrrrr) $ ZOffset (unpack qqqqqq)
decodeInstruction $(bitPattern "1001_001d_dddd_0000_kkkk_kkkk_kkkk_kkkk") = Sts (unpack kkkkkkkkkkkkkkkk) (unpack ddddd)
decodeInstruction $(bitPattern "0001_10rd_dddd_rrrr_...._...._...._....") = Sub (unpack ddddd) (unpack rrrrr)
decodeInstruction $(bitPattern "0101_kkkk_dddd_kkkk_...._...._...._....") = Subi (unpack dddd) (unpack kkkkkkkk)
decodeInstruction $(bitPattern "1001_010d_dddd_0010_...._...._...._....") = Swap (unpack ddddd)
decodeInstruction $(bitPattern "1001_0101_1010_1000_...._...._...._....") = Wdr
decodeInstruction $(bitPattern "1001_001r_rrrr_0100_...._...._...._....") = Xch (unpack rrrrr)
decodeInstruction _ = Nop

-- | Number of 16-bit words this instruction occupies in program memory.
--   CALL, JMP, LDS, and STS are 2-word instructions; everything else is 1.
instrWords :: Instruction -> Unsigned 2
instrWords (Call _)  = 2
instrWords (Jmp _)   = 2
instrWords (Lds _ _) = 2
instrWords (Sts _ _) = 2
instrWords _         = 1

encodeInstruction :: Instruction -> BitVector 32
-- Arithmetic / Logic
encodeInstruction (Adc   rd rr) = padInstr $ (0b000111   :: BitVector 6) ++# binaryOpPack rd rr
encodeInstruction (Add   rd rr) = padInstr $ (0b000011   :: BitVector 6) ++# binaryOpPack rd rr
encodeInstruction (Adiw  rd k)  = padInstr $ (0b10010110 :: BitVector 8) ++# iwOpPack rd k
encodeInstruction (AVR.InstructionSet.And rd rr)
                                = padInstr $ (0b001000   :: BitVector 6) ++# binaryOpPack rd rr
encodeInstruction (Andi  rd k)  = padInstr $ upperImmPack (0b0111 :: BitVector 4) rd k
encodeInstruction (Asr   rd)    = padInstr $ reg16Pack (0b1001010 :: BitVector 7) rd (0b0101 :: BitVector 4)
encodeInstruction (Com   rd)    = padInstr $ reg16Pack (0b1001010 :: BitVector 7) rd (0b0000 :: BitVector 4)
encodeInstruction (Cp    rd rr) = padInstr $ (0b000101   :: BitVector 6) ++# binaryOpPack rd rr
encodeInstruction (Cpc   rd rr) = padInstr $ (0b000001   :: BitVector 6) ++# binaryOpPack rd rr
encodeInstruction (Cpi   rd k)  = padInstr $ upperImmPack (0b0011 :: BitVector 4) rd k
encodeInstruction (Cpse  rd rr) = padInstr $ (0b000100   :: BitVector 6) ++# binaryOpPack rd rr
encodeInstruction (Dec   rd)    = padInstr $ reg16Pack (0b1001010 :: BitVector 7) rd (0b1010 :: BitVector 4)
encodeInstruction (Des   k)     = padInstr $ (0b10010100 :: BitVector 8) ++# pack k ++# (0b1011 :: BitVector 4)
encodeInstruction (Eor   rd rr) = padInstr $ (0b001001   :: BitVector 6) ++# binaryOpPack rd rr
encodeInstruction (Fmul  rd rr) = padInstr $ (0b000000110 :: BitVector 9) ++# pack rd ++# (1 :: BitVector 1) ++# pack rr
encodeInstruction (Fmuls rd rr) = padInstr $ (0b000000111 :: BitVector 9) ++# pack rd ++# (0 :: BitVector 1) ++# pack rr
encodeInstruction (Fmulsu rd rr)= padInstr $ (0b000000111 :: BitVector 9) ++# pack rd ++# (1 :: BitVector 1) ++# pack rr
encodeInstruction (Inc   rd)    = padInstr $ reg16Pack (0b1001010 :: BitVector 7) rd (0b0011 :: BitVector 4)
encodeInstruction (Lsr   rd)    = padInstr $ reg16Pack (0b1001010 :: BitVector 7) rd (0b0110 :: BitVector 4)
encodeInstruction (Mov   rd rr) = padInstr $ (0b001011   :: BitVector 6) ++# binaryOpPack rd rr
encodeInstruction (Movw  rd rr) = padInstr $ (0b00000001 :: BitVector 8) ++# pack rd ++# pack rr
encodeInstruction (Mul   rd rr) = padInstr $ (0b100111   :: BitVector 6) ++# binaryOpPack rd rr
encodeInstruction (Muls  rd rr) = padInstr $ (0b00000010 :: BitVector 8) ++# pack rd ++# pack rr
encodeInstruction (Mulsu rd rr) = padInstr $ (0b000000110 :: BitVector 9) ++# pack rd ++# (0 :: BitVector 1) ++# pack rr
encodeInstruction (Neg   rd)    = padInstr $ reg16Pack (0b1001010 :: BitVector 7) rd (0b0001 :: BitVector 4)
encodeInstruction  Nop          = padInstr (0x0000 :: BitVector 16)
encodeInstruction (Or    rd rr) = padInstr $ (0b001010   :: BitVector 6) ++# binaryOpPack rd rr
encodeInstruction (Ori   rd k)  = padInstr $ upperImmPack (0b0110 :: BitVector 4) rd k
encodeInstruction (Ror   rd)    = padInstr $ reg16Pack (0b1001010 :: BitVector 7) rd (0b0111 :: BitVector 4)
encodeInstruction (Sbc   rd rr) = padInstr $ (0b000010   :: BitVector 6) ++# binaryOpPack rd rr
encodeInstruction (Sbci  rd k)  = padInstr $ upperImmPack (0b0100 :: BitVector 4) rd k
encodeInstruction (Sbr   rd k)  = encodeInstruction (Ori rd k)
encodeInstruction (Sbiw  rd k)  = padInstr $ (0b10010111 :: BitVector 8) ++# iwOpPack rd k
encodeInstruction (Sub   rd rr) = padInstr $ (0b000110   :: BitVector 6) ++# binaryOpPack rd rr
encodeInstruction (Subi  rd k)  = padInstr $ upperImmPack (0b0101 :: BitVector 4) rd k
encodeInstruction (Swap  rd)    = padInstr $ reg16Pack (0b1001010 :: BitVector 7) rd (0b0010 :: BitVector 4)
-- SREG bit ops (Seb/Clb are aliases for Bset/Bclr)
encodeInstruction (Bset  s)     = padInstr $ (0b10010100 :: BitVector 8) ++# (0 :: BitVector 1) ++# pack s ++# (0b1000 :: BitVector 4)
encodeInstruction (Bclr  s)     = padInstr $ (0b10010100 :: BitVector 8) ++# (1 :: BitVector 1) ++# pack s ++# (0b1000 :: BitVector 4)
encodeInstruction (Seb   s)     = encodeInstruction (Bset s)
encodeInstruction (Clb   s)     = encodeInstruction (Bclr s)
-- Register bit ops
encodeInstruction (Bld   rd b)  = padInstr $ (0b1111100  :: BitVector 7) ++# regBitPack rd b
encodeInstruction (Bst   rd b)  = padInstr $ (0b1111101  :: BitVector 7) ++# regBitPack rd b
encodeInstruction (Sbrc  rr b)  = padInstr $ (0b1111110  :: BitVector 7) ++# regBitPack rr b
encodeInstruction (Sbrs  rr b)  = padInstr $ (0b1111111  :: BitVector 7) ++# regBitPack rr b
-- Branches (aliases delegate to Brbc/Brbs with the appropriate s)
encodeInstruction (Brbc  s k)   = padInstr $ branchPack (1 :: BitVector 1) s k
encodeInstruction (Brbs  s k)   = padInstr $ branchPack (0 :: BitVector 1) s k
encodeInstruction (Brcc  k)     = encodeInstruction (Brbc 0 k)
encodeInstruction (Brcs  k)     = encodeInstruction (Brbs 0 k)
encodeInstruction (Breq  k)     = encodeInstruction (Brbs 1 k)
encodeInstruction (Brge  k)     = encodeInstruction (Brbc 4 k)
encodeInstruction (Brhc  k)     = encodeInstruction (Brbc 5 k)
encodeInstruction (Brhs  k)     = encodeInstruction (Brbs 5 k)
encodeInstruction (Brid  k)     = encodeInstruction (Brbc 7 k)
encodeInstruction (Brie  k)     = encodeInstruction (Brbs 7 k)
encodeInstruction (Brlo  k)     = encodeInstruction (Brbs 0 k)
encodeInstruction (Brlt  k)     = encodeInstruction (Brbs 4 k)
encodeInstruction (Brmi  k)     = encodeInstruction (Brbs 2 k)
encodeInstruction (Brne  k)     = encodeInstruction (Brbc 1 k)
encodeInstruction (Brpl  k)     = encodeInstruction (Brbc 2 k)
encodeInstruction (Brsh  k)     = encodeInstruction (Brbc 0 k)
encodeInstruction (Brtc  k)     = encodeInstruction (Brbc 6 k)
encodeInstruction (Brts  k)     = encodeInstruction (Brbs 6 k)
encodeInstruction (Brvc  k)     = encodeInstruction (Brbc 3 k)
encodeInstruction (Brvs  k)     = encodeInstruction (Brbs 3 k)
-- IO bit ops
encodeInstruction (Cbi   a b)   = padInstr $ (0b10011000 :: BitVector 8) ++# pack a ++# pack b
encodeInstruction (Sbi   a b)   = padInstr $ (0b10011010 :: BitVector 8) ++# pack a ++# pack b
encodeInstruction (Sbic  a b)   = padInstr $ (0b10011001 :: BitVector 8) ++# pack a ++# pack b
encodeInstruction (Sbis  a b)   = padInstr $ (0b10011011 :: BitVector 8) ++# pack a ++# pack b
-- Jumps / calls
encodeInstruction (Rjmp  k)     = padInstr $ (0b1100 :: BitVector 4) ++# pack k
encodeInstruction (Rcall k)     = padInstr $ (0b1101 :: BitVector 4) ++# pack k
encodeInstruction  Ijmp         = padInstr (0x9409 :: BitVector 16)
encodeInstruction  Icall        = padInstr (0x9509 :: BitVector 16)
encodeInstruction  Eijmp        = padInstr (0x9419 :: BitVector 16)
encodeInstruction  Eicall       = padInstr (0x9519 :: BitVector 16)
encodeInstruction (Jmp   k)     = callJmpPack False k
encodeInstruction (Call  k)     = callJmpPack True  k
encodeInstruction  Ret          = padInstr (0x9508 :: BitVector 16)
encodeInstruction  Reti         = padInstr (0x9518 :: BitVector 16)
-- Data transfer
encodeInstruction (Ldi   rd k)  = padInstr $ upperImmPack (0b1110 :: BitVector 4) rd k
encodeInstruction (Lds   rd k)  = ldsPack rd k
encodeInstruction (Sts   k rr)  = stsPack k rr
encodeInstruction (Ld    rd m)  = padInstr $ ldModePack rd m
encodeInstruction (St    rr m)  = padInstr $ stModePack rr m
encodeInstruction (In    rd a)  = padInstr $ inPack rd a
encodeInstruction (Out   a rr)  = padInstr $ outPack a rr
encodeInstruction (Pop   rd)    = padInstr $ reg16Pack (0b1001000 :: BitVector 7) rd (0b1111 :: BitVector 4)
encodeInstruction (Push  rr)    = padInstr $ reg16Pack (0b1001001 :: BitVector 7) rr (0b1111 :: BitVector 4)
-- Program memory
encodeInstruction  Lpm          = padInstr (0x95C8 :: BitVector 16)
encodeInstruction (LpmZ   rd)   = padInstr $ reg16Pack (0b1001000 :: BitVector 7) rd (0b0100 :: BitVector 4)
encodeInstruction (LpmZPlus rd) = padInstr $ reg16Pack (0b1001000 :: BitVector 7) rd (0b0101 :: BitVector 4)
encodeInstruction  Elpm         = padInstr (0x95D8 :: BitVector 16)
encodeInstruction (ElpmZ   rd)  = padInstr $ reg16Pack (0b1001000 :: BitVector 7) rd (0b0110 :: BitVector 4)
encodeInstruction (ElpmZPlus rd)= padInstr $ reg16Pack (0b1001000 :: BitVector 7) rd (0b0111 :: BitVector 4)
encodeInstruction (Spm ZIndirect)             = padInstr (0x95E8 :: BitVector 16)
encodeInstruction (Spm ZIndirectPostIncrement)= padInstr (0x95F8 :: BitVector 16)
encodeInstruction (Spm _)       = padInstr (0x95E8 :: BitVector 16)  -- invalid mode, fallback
-- Atomic / RMW (AVRxm)
encodeInstruction (Xch  rd)     = padInstr $ reg16Pack (0b1001001 :: BitVector 7) rd (0b0100 :: BitVector 4)
encodeInstruction (Las  rd)     = padInstr $ reg16Pack (0b1001001 :: BitVector 7) rd (0b0101 :: BitVector 4)
encodeInstruction (Lac  rd)     = padInstr $ reg16Pack (0b1001001 :: BitVector 7) rd (0b0110 :: BitVector 4)
encodeInstruction (Lat  rd)     = padInstr $ reg16Pack (0b1001001 :: BitVector 7) rd (0b0111 :: BitVector 4)
-- MCU control
encodeInstruction  Break        = padInstr (0x9598 :: BitVector 16)
encodeInstruction  Sleep        = padInstr (0x9588 :: BitVector 16)
encodeInstruction  Wdr          = padInstr (0x95A8 :: BitVector 16)

-- ---------------------------------------------------------------------------
-- Encoding helpers
-- ---------------------------------------------------------------------------

-- | rd rrrr 10-bit field used by binary-register instructions.
--   Opcode format: OOOOOO rr[4] rd[4] rd[3:0] rr[3:0]
--   (bit 9 = rr high bit, bit 8 = rd high bit)
binaryOpPack :: Register -> Register -> BitVector 10
binaryOpPack rd rr =
    let rdb = pack rd :: BitVector 5
        rrb = pack rr :: BitVector 5
    in slice d4 d4 rrb ++# slice d4 d4 rdb ++# slice d3 d0 rdb ++# slice d3 d0 rrb

-- | KKdd KKKK field used by ADIW / SBIW.
iwOpPack :: WideUpperRegister -> ShortImmediate -> BitVector 8
iwOpPack rd k =
    let kbits = pack k :: BitVector 6
    in slice d5 d4 kbits ++# pack rd ++# slice d3 d0 kbits

-- | Zero-pad a 16-bit opcode to 32 bits (single-word instruction).
padInstr :: BitVector 16 -> BitVector 32
padInstr instr = instr ++# (0x0000 :: BitVector 16)

-- | OOOO KKKK dddd KKKK — upper-register (d∈16..31) with 8-bit immediate.
upperImmPack :: BitVector 4 -> UpperRegister -> Immediate -> BitVector 16
upperImmPack op rd k =
    let kb = pack k :: BitVector 8
    in op ++# slice d7 d4 kb ++# pack rd ++# slice d3 d0 kb

-- | 7-bit prefix + register (5-bit) + 4-bit suffix — covers most single-reg ops,
--   LD/ST fixed modes, LPM, ELPM, POP, PUSH, LAC, LAS, LAT, XCH.
reg16Pack :: BitVector 7 -> Register -> BitVector 4 -> BitVector 16
reg16Pack prefix rd suffix =
    let rb = pack rd :: BitVector 5
    in prefix ++# slice d4 d4 rb ++# slice d3 d0 rb ++# suffix

-- | Register + bit-select field: rd[4] rd[3:0] 0 bbb (9 bits).
--   Used by BLD, BST, SBRC, SBRS.
regBitPack :: Register -> BitSelect -> BitVector 9
regBitPack r b =
    let rb = pack r :: BitVector 5
    in slice d4 d4 rb ++# slice d3 d0 rb ++# (0 :: BitVector 1) ++# pack b

-- | 1111 0x kkkkkkk sss — conditional branch.
branchPack :: BitVector 1 -> BitSelect -> MidImmediate -> BitVector 16
branchPack x s k =
    (0b11110 :: BitVector 5) ++# x ++# pack k ++# pack s

-- | IN Rd, A: 1011 0 A[5:4] rd[4] rd[3:0] A[3:0]
inPack :: Register -> ShortImmediate -> BitVector 16
inPack rd a =
    let ab = pack a :: BitVector 6
        rb = pack rd :: BitVector 5
    in (0b10110 :: BitVector 5) ++# slice d5 d4 ab ++# slice d4 d4 rb ++# slice d3 d0 rb ++# slice d3 d0 ab

-- | OUT A, Rr: 1011 1 A[5:4] rr[4] rr[3:0] A[3:0]
outPack :: ShortImmediate -> Register -> BitVector 16
outPack a rr =
    let ab = pack a :: BitVector 6
        rb = pack rr :: BitVector 5
    in (0b10111 :: BitVector 5) ++# slice d5 d4 ab ++# slice d4 d4 rb ++# slice d3 d0 rb ++# slice d3 d0 ab

-- | CALL / JMP: 32-bit, 22-bit word address split across both words.
--   word0: 1001010 k[21] k[20:17] 111|110 k[16]
--   word1: k[15:0]
callJmpPack :: Bool -> CodeAddress -> BitVector 32
callJmpPack isCall k =
    let kb     = pack k :: BitVector 22
        suffix = if isCall then (0b111 :: BitVector 3) else (0b110 :: BitVector 3)
        word0  = (0b1001010 :: BitVector 7)
              ++# slice d21 d21 kb
              ++# slice d20 d17 kb
              ++# suffix
              ++# slice d16 d16 kb
    in word0 ++# slice d15 d0 kb

-- | LDS Rd, k: word0 = 1001000 rd[4] rd[3:0] 0000, word1 = k
ldsPack :: Register -> WideImmediate -> BitVector 32
ldsPack rd k =
    let rb = pack rd :: BitVector 5
    in (0b1001000 :: BitVector 7) ++# slice d4 d4 rb ++# slice d3 d0 rb ++# (0b0000 :: BitVector 4) ++# pack k

-- | STS k, Rr: word0 = 1001001 rr[4] rr[3:0] 0000, word1 = k
stsPack :: WideImmediate -> Register -> BitVector 32
stsPack k rr =
    let rb = pack rr :: BitVector 5
    in (0b1001001 :: BitVector 7) ++# slice d4 d4 rb ++# slice d3 d0 rb ++# (0b0000 :: BitVector 4) ++# pack k

-- | LD Rd, <mode>
ldModePack :: Register -> IndirectAddressingMode -> BitVector 16
ldModePack rd XIndirect              = reg16Pack (0b1001000 :: BitVector 7) rd (0b1100 :: BitVector 4)
ldModePack rd XIndirectPostIncrement = reg16Pack (0b1001000 :: BitVector 7) rd (0b1101 :: BitVector 4)
ldModePack rd XIndirectPreDecrement  = reg16Pack (0b1001000 :: BitVector 7) rd (0b1110 :: BitVector 4)
ldModePack rd YIndirect              = reg16Pack (0b1000000 :: BitVector 7) rd (0b1000 :: BitVector 4)
ldModePack rd YIndirectPostIncrement = reg16Pack (0b1001000 :: BitVector 7) rd (0b1001 :: BitVector 4)
ldModePack rd YIndirectPreDecrement  = reg16Pack (0b1001000 :: BitVector 7) rd (0b1010 :: BitVector 4)
ldModePack rd (YOffset q)            = ldOffsetPack rd (1 :: BitVector 1) q
ldModePack rd ZIndirect              = reg16Pack (0b1000000 :: BitVector 7) rd (0b0000 :: BitVector 4)
ldModePack rd ZIndirectPostIncrement = reg16Pack (0b1001000 :: BitVector 7) rd (0b0001 :: BitVector 4)
ldModePack rd ZIndirectPreDecrement  = reg16Pack (0b1001000 :: BitVector 7) rd (0b0010 :: BitVector 4)
ldModePack rd (ZOffset q)            = ldOffsetPack rd (0 :: BitVector 1) q
ldModePack rd (XOffset _)            = reg16Pack (0b1001000 :: BitVector 7) rd (0b1100 :: BitVector 4)

-- | LD Rd, Y+q / Z+q: 1 q[5] 0 q[4:3] 0 rd[4] rd[3:0] base q[2:0]
-- | 10q0_qq0d_dddd_Xqqq  (X=1 for Y base, X=0 for Z base)
ldOffsetPack :: Register -> BitVector 1 -> ShortImmediate -> BitVector 16
ldOffsetPack rd base q =
    let rb = pack rd :: BitVector 5
        qb = pack q  :: BitVector 6
    in (1 :: BitVector 1) ++# (0 :: BitVector 1) ++# slice d5 d5 qb ++# (0 :: BitVector 1)
    ++# slice d4 d3 qb ++# (0 :: BitVector 1) ++# slice d4 d4 rb ++# slice d3 d0 rb
    ++# base ++# slice d2 d0 qb

-- | ST <mode>, Rr
stModePack :: Register -> IndirectAddressingMode -> BitVector 16
stModePack rr XIndirect              = reg16Pack (0b1001001 :: BitVector 7) rr (0b1100 :: BitVector 4)
stModePack rr XIndirectPostIncrement = reg16Pack (0b1001001 :: BitVector 7) rr (0b1101 :: BitVector 4)
stModePack rr XIndirectPreDecrement  = reg16Pack (0b1001001 :: BitVector 7) rr (0b1110 :: BitVector 4)
stModePack rr YIndirect              = reg16Pack (0b1000001 :: BitVector 7) rr (0b1000 :: BitVector 4)
stModePack rr YIndirectPostIncrement = reg16Pack (0b1001001 :: BitVector 7) rr (0b1001 :: BitVector 4)
stModePack rr YIndirectPreDecrement  = reg16Pack (0b1001001 :: BitVector 7) rr (0b1010 :: BitVector 4)
stModePack rr (YOffset q)            = stOffsetPack rr (1 :: BitVector 1) q
stModePack rr ZIndirect              = reg16Pack (0b1000001 :: BitVector 7) rr (0b0000 :: BitVector 4)
stModePack rr ZIndirectPostIncrement = reg16Pack (0b1001001 :: BitVector 7) rr (0b0001 :: BitVector 4)
stModePack rr ZIndirectPreDecrement  = reg16Pack (0b1001001 :: BitVector 7) rr (0b0010 :: BitVector 4)
stModePack rr (ZOffset q)            = stOffsetPack rr (0 :: BitVector 1) q
stModePack rr (XOffset _)            = reg16Pack (0b1001001 :: BitVector 7) rr (0b1100 :: BitVector 4)

-- | 10q0_qq1r_rrrr_Xqqq  (bit 9 = 1 distinguishes store from load)
stOffsetPack :: Register -> BitVector 1 -> ShortImmediate -> BitVector 16
stOffsetPack rr base q =
    let rb = pack rr :: BitVector 5
        qb = pack q  :: BitVector 6
    in (1 :: BitVector 1) ++# (0 :: BitVector 1) ++# slice d5 d5 qb ++# (0 :: BitVector 1)
    ++# slice d4 d3 qb ++# (1 :: BitVector 1) ++# slice d4 d4 rb ++# slice d3 d0 rb
    ++# base ++# slice d2 d0 qb