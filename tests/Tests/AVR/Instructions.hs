module Tests.AVR.Instructions where

import Prelude

import Test.Tasty
import Test.Tasty.TH
import Test.Tasty.Hedgehog
import qualified Hedgehog as H

import Clash.Prelude (Bit, Unsigned)

import AVR.Core
import AVR.ALU
import AVR.InstructionSet

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

type C = CoreData 16

base :: C
base = zeroState

-- Run one instruction with no memory operand.
exec :: Instruction -> C -> C
exec i = avrCompute i Nothing

-- Run one instruction with a memory-loaded value (LD/POP result).
load :: Instruction -> AVRWord -> C -> C
load i v = avrCompute i (Just v)

-- Set a register.
withR :: Register -> AVRWord -> C -> C
withR n v c = setReg c n v

-- Set pointer registers.
withX, withY, withZ :: Unsigned 16 -> C -> C
withX v c = setX c v
withY v c = setY c v
withZ v c = setZ c v

-- Set SP.
withSP :: AVRAddr -> C -> C
withSP v c = c { sp = v }

-- Preset individual SREG flags.
withPC :: Unsigned 16 -> C -> C
withPC v c = c { pc = v }

withC, withZ_flag, withN, withV, withH, withT, withI :: Bit -> C -> C
withC b c = c { status = (status c) { carry_flag     = b } }
withZ_flag b c = c { status = (status c) { zero_flag  = b } }
withN b c = c { status = (status c) { negative_flag  = b } }
withV b c = c { status = (status c) { overflow_flag  = b } }
withH b c = c { status = (status c) { half_carry     = b } }
withT b c = c { status = (status c) { bit_copy       = b } }
withI b c = c { status = (status c) { interrupt_flag = b } }

-- Flag accessors (short names for assertions).
c_flag, z_flag, n_flag, v_flag, h_flag, s_flag, t_flag, i_flag :: C -> Bit
c_flag = carry_flag    . status
z_flag = zero_flag     . status
n_flag = negative_flag . status
v_flag = overflow_flag . status
h_flag = half_carry    . status
s_flag = sign_flag     . status
t_flag = bit_copy      . status
i_flag = interrupt_flag . status

-- Checked property: withTests 1 (all tests are deterministic).
det :: H.PropertyT IO () -> H.Property
det = H.withTests 1 . H.property

-- ---------------------------------------------------------------------------
-- ADD / ADC
-- ---------------------------------------------------------------------------

-- 5 + 3 = 8, no flags set.
prop_add_basic :: H.Property
prop_add_basic = det $ do
    let c = exec (Add 16 17) $ withR 16 5 $ withR 17 3 base
    getReg c 16 H.=== 8
    c_flag c H.=== 0; z_flag c H.=== 0; n_flag c H.=== 0

-- 0xFF + 0x01 = 0x00: carry out, zero result.
prop_add_carry_out :: H.Property
prop_add_carry_out = det $ do
    let c = exec (Add 16 17) $ withR 16 0xFF $ withR 17 0x01 base
    getReg c 16 H.=== 0
    c_flag c H.=== 1; z_flag c H.=== 1; n_flag c H.=== 0; v_flag c H.=== 0

-- 0x0F + 0x01 = 0x10: half-carry set (lower nibble overflows into upper).
prop_add_half_carry :: H.Property
prop_add_half_carry = det $ do
    let c = exec (Add 16 17) $ withR 16 0x0F $ withR 17 0x01 base
    getReg c 16 H.=== 0x10
    h_flag c H.=== 1; c_flag c H.=== 0

-- 0x7F + 0x01 = 0x80: signed overflow (positive + positive = negative).
prop_add_signed_overflow :: H.Property
prop_add_signed_overflow = det $ do
    let c = exec (Add 16 17) $ withR 16 0x7F $ withR 17 0x01 base
    getReg c 16 H.=== 0x80
    v_flag c H.=== 1; n_flag c H.=== 1; s_flag c H.=== 0; c_flag c H.=== 0

-- ADC uses the incoming carry bit: 5 + 3 + C(1) = 9.
prop_adc_uses_carry :: H.Property
prop_adc_uses_carry = det $ do
    let c = exec (Adc 16 17) $ withR 16 5 $ withR 17 3 $ withC 1 base
    getReg c 16 H.=== 9

-- ADC with C=0 behaves like ADD.
prop_adc_no_carry :: H.Property
prop_adc_no_carry = det $ do
    let c = exec (Adc 16 17) $ withR 16 5 $ withR 17 3 $ withC 0 base
    getReg c 16 H.=== 8

-- ---------------------------------------------------------------------------
-- ADIW / SBIW
-- ---------------------------------------------------------------------------

-- ADIW R24, 5: R25:R24 = 0 + 5 = 5 (wideBase 0 = R24).
prop_adiw_basic :: H.Property
prop_adiw_basic = det $ do
    let c = exec (Adiw 0 5) base
    getRegPair c 24 H.=== 5
    z_flag c H.=== 0; c_flag c H.=== 0

-- ADIW wraps 0xFFFF + 1 = 0x0000: Z=1, C=1.
prop_adiw_wrap :: H.Property
prop_adiw_wrap = det $ do
    let c = exec (Adiw 0 1) $ withR 24 0xFF $ withR 25 0xFF base
    getRegPair c 24 H.=== 0
    z_flag c H.=== 1; c_flag c H.=== 1

-- SBIW R24, 3: R25:R24 = 10 - 3 = 7.
prop_sbiw_basic :: H.Property
prop_sbiw_basic = det $ do
    let c = exec (Sbiw 0 3) $ withR 24 10 $ withR 25 0 base
    getRegPair c 24 H.=== 7
    c_flag c H.=== 0; z_flag c H.=== 0

-- SBIW borrows: R25:R24 = 5 - 10 wraps, C=1.
prop_sbiw_borrow :: H.Property
prop_sbiw_borrow = det $ do
    let c = exec (Sbiw 0 10) $ withR 24 5 $ withR 25 0 base
    c_flag c H.=== 1; z_flag c H.=== 0

-- ---------------------------------------------------------------------------
-- SUB / SUBI / SBC / SBCI
-- ---------------------------------------------------------------------------

-- SUB: 10 - 3 = 7.
prop_sub_basic :: H.Property
prop_sub_basic = det $ do
    let c = exec (Sub 16 17) $ withR 16 10 $ withR 17 3 base
    getReg c 16 H.=== 7
    c_flag c H.=== 0; z_flag c H.=== 0

-- SUB borrows: 3 - 10 wraps, C=1 (borrow), N=1.
prop_sub_borrow :: H.Property
prop_sub_borrow = det $ do
    let c = exec (Sub 16 17) $ withR 16 3 $ withR 17 10 base
    getReg c 16 H.=== 0xF9  -- -7 in two's complement
    c_flag c H.=== 1; n_flag c H.=== 1

-- SUB with equal operands: result 0, Z=1, C=0.
prop_sub_zero_result :: H.Property
prop_sub_zero_result = det $ do
    let c = exec (Sub 16 17) $ withR 16 7 $ withR 17 7 base
    getReg c 16 H.=== 0
    z_flag c H.=== 1; c_flag c H.=== 0

-- SUBI (UpperRegister 0 = R16): R16 - 5 = 10 - 5 = 5.
prop_subi_basic :: H.Property
prop_subi_basic = det $ do
    let c = exec (Subi 0 5) $ withR 16 10 base
    getReg c 16 H.=== 5
    c_flag c H.=== 0; z_flag c H.=== 0

-- SBC with carry in: Rd - Rr - C.  10 - 3 - 1 = 6.
prop_sbc_carry_in :: H.Property
prop_sbc_carry_in = det $ do
    let c = exec (Sbc 16 17) $ withR 16 10 $ withR 17 3 $ withC 1 base
    getReg c 16 H.=== 6

-- SBCI Z is ANDed with prior Z (for multi-byte subtraction chains).
-- result=0 AND prior_Z=0 → new Z=0, even though this byte subtracted to zero.
prop_sbci_z_not_preserved_when_prior_z_clear :: H.Property
prop_sbci_z_not_preserved_when_prior_z_clear = det $ do
    let c = exec (Sbci 0 5) $ withR 16 5 $ withZ_flag 0 base
    getReg c 16 H.=== 0
    z_flag c H.=== 0  -- prior Z=0 AND'ed with bb(r==0)=1 → stays 0

-- SBCI Z-preserve: when result /= 0 but prior Z was 1, new Z = 0.
prop_sbci_z_cleared_when_nonzero_result :: H.Property
prop_sbci_z_cleared_when_nonzero_result = det $ do
    let c = exec (Sbci 0 3) $ withR 16 5 $ withZ_flag 1 base
    getReg c 16 H.=== 2
    z_flag c H.=== 0  -- result /= 0 → Z cleared even if prior Z was 1

-- ---------------------------------------------------------------------------
-- COM / NEG
-- ---------------------------------------------------------------------------

-- COM 0x0F = 0xF0: C always 1, V always 0, N=1.
prop_com_basic :: H.Property
prop_com_basic = det $ do
    let c = exec (Com 16) $ withR 16 0x0F base
    getReg c 16 H.=== 0xF0
    c_flag c H.=== 1; v_flag c H.=== 0; n_flag c H.=== 1

-- COM 0xFF = 0x00: Z=1, C=1.
prop_com_zero_result :: H.Property
prop_com_zero_result = det $ do
    let c = exec (Com 16) $ withR 16 0xFF base
    getReg c 16 H.=== 0
    z_flag c H.=== 1; c_flag c H.=== 1

-- NEG 0x01 = 0xFF: C=1, N=1.
prop_neg_basic :: H.Property
prop_neg_basic = det $ do
    let c = exec (Neg 16) $ withR 16 0x01 base
    getReg c 16 H.=== 0xFF
    c_flag c H.=== 1; n_flag c H.=== 1; z_flag c H.=== 0

-- NEG 0x00 = 0x00: Z=1, C=0.
prop_neg_zero :: H.Property
prop_neg_zero = det $ do
    let c = exec (Neg 16) $ withR 16 0x00 base
    getReg c 16 H.=== 0
    z_flag c H.=== 1; c_flag c H.=== 0

-- NEG 0x80 = 0x80: V=1 (the only value where NEG produces overflow).
prop_neg_min_signed :: H.Property
prop_neg_min_signed = det $ do
    let c = exec (Neg 16) $ withR 16 0x80 base
    getReg c 16 H.=== 0x80
    v_flag c H.=== 1; c_flag c H.=== 1; s_flag c H.=== 0

-- ---------------------------------------------------------------------------
-- INC / DEC
-- ---------------------------------------------------------------------------

prop_inc_basic :: H.Property
prop_inc_basic = det $ do
    let c = exec (Inc 16) $ withR 16 5 base
    getReg c 16 H.=== 6
    v_flag c H.=== 0; z_flag c H.=== 0

-- INC 0x7F = 0x80: signed overflow, V=1, N=1, S=0 (N XOR V).
prop_inc_signed_overflow :: H.Property
prop_inc_signed_overflow = det $ do
    let c = exec (Inc 16) $ withR 16 0x7F base
    getReg c 16 H.=== 0x80
    v_flag c H.=== 1; n_flag c H.=== 1; s_flag c H.=== 0

-- INC 0xFF = 0x00: wraps, Z=1 (C unchanged by INC).
prop_inc_wraps :: H.Property
prop_inc_wraps = det $ do
    let c = exec (Inc 16) $ withR 16 0xFF $ withC 1 base
    getReg c 16 H.=== 0
    z_flag c H.=== 1; c_flag c H.=== 1  -- INC does not change C

prop_dec_basic :: H.Property
prop_dec_basic = det $ do
    let c = exec (Dec 16) $ withR 16 5 base
    getReg c 16 H.=== 4
    v_flag c H.=== 0; z_flag c H.=== 0

-- DEC 0x80 = 0x7F: V=1, N=0, S=1 (N XOR V = 0 XOR 1).
prop_dec_signed_overflow :: H.Property
prop_dec_signed_overflow = det $ do
    let c = exec (Dec 16) $ withR 16 0x80 base
    getReg c 16 H.=== 0x7F
    v_flag c H.=== 1; n_flag c H.=== 0; s_flag c H.=== 1

-- DEC 0x01 = 0x00: Z=1.
prop_dec_zero_result :: H.Property
prop_dec_zero_result = det $ do
    let c = exec (Dec 16) $ withR 16 0x01 base
    getReg c 16 H.=== 0
    z_flag c H.=== 1

-- ---------------------------------------------------------------------------
-- AND / ANDI / OR / ORI / EOR
-- ---------------------------------------------------------------------------

-- AND 0xFF & 0x0F = 0x0F: V=0 always, N=0, Z=0.
prop_and_basic :: H.Property
prop_and_basic = det $ do
    let c = exec (AVR.InstructionSet.And 16 17) $ withR 16 0xFF $ withR 17 0x0F base
    getReg c 16 H.=== 0x0F
    v_flag c H.=== 0; n_flag c H.=== 0; z_flag c H.=== 0

-- AND 0xAA & 0x55 = 0x00: Z=1.
prop_and_zero_result :: H.Property
prop_and_zero_result = det $ do
    let c = exec (AVR.InstructionSet.And 16 17) $ withR 16 0xAA $ withR 17 0x55 base
    getReg c 16 H.=== 0
    z_flag c H.=== 1; v_flag c H.=== 0

-- AND produces negative result: 0xF0 & 0xF0 = 0xF0, N=1.
prop_and_negative_result :: H.Property
prop_and_negative_result = det $ do
    let c = exec (AVR.InstructionSet.And 16 17) $ withR 16 0xF0 $ withR 17 0xF0 base
    getReg c 16 H.=== 0xF0
    n_flag c H.=== 1; v_flag c H.=== 0

-- ANDI R16, 0x0F: masks lower nibble.
prop_andi_mask :: H.Property
prop_andi_mask = det $ do
    let c = exec (Andi 0 0x0F) $ withR 16 0xAB base
    getReg c 16 H.=== 0x0B

-- OR 0xF0 | 0x0F = 0xFF: N=1.
prop_or_basic :: H.Property
prop_or_basic = det $ do
    let c = exec (Or 16 17) $ withR 16 0xF0 $ withR 17 0x0F base
    getReg c 16 H.=== 0xFF
    n_flag c H.=== 1; v_flag c H.=== 0; z_flag c H.=== 0

-- OR 0 | 0 = 0: Z=1.
prop_or_zero_result :: H.Property
prop_or_zero_result = det $ do
    let c = exec (Or 16 17) $ withR 16 0 $ withR 17 0 base
    z_flag c H.=== 1

-- ORI R16, 0xF0: sets upper nibble.
prop_ori_basic :: H.Property
prop_ori_basic = det $ do
    let c = exec (Ori 0 0xF0) $ withR 16 0x0F base
    getReg c 16 H.=== 0xFF

-- EOR self-cancel: R16 ^ R16 = 0x00, Z=1.
prop_eor_cancel :: H.Property
prop_eor_cancel = det $ do
    let c = exec (Eor 16 16) $ withR 16 0xAB base
    getReg c 16 H.=== 0
    z_flag c H.=== 1; v_flag c H.=== 0

-- EOR 0xAA ^ 0x55 = 0xFF: N=1.
prop_eor_complement :: H.Property
prop_eor_complement = det $ do
    let c = exec (Eor 16 17) $ withR 16 0xAA $ withR 17 0x55 base
    getReg c 16 H.=== 0xFF
    n_flag c H.=== 1; v_flag c H.=== 0

-- ---------------------------------------------------------------------------
-- MUL / MULS / MULSU / FMUL
-- ---------------------------------------------------------------------------

-- MUL: R0:R1 = 10 * 12 = 120.  Result fits in 8 bits so R1 = 0.
prop_mul_basic :: H.Property
prop_mul_basic = det $ do
    let c = exec (Mul 16 17) $ withR 16 10 $ withR 17 12 base
    getReg c 0 H.=== 120; getReg c 1 H.=== 0
    z_flag c H.=== 0; c_flag c H.=== 0

-- MUL with overflow into high byte: 200 * 200 = 40000 = 0x9C40.
prop_mul_high_byte :: H.Property
prop_mul_high_byte = det $ do
    let c = exec (Mul 16 17) $ withR 16 200 $ withR 17 200 base
    getReg c 0 H.=== 0x40; getReg c 1 H.=== 0x9C

-- MUL by zero: Z=1.
prop_mul_zero :: H.Property
prop_mul_zero = det $ do
    let c = exec (Mul 16 17) $ withR 16 42 $ withR 17 0 base
    getReg c 0 H.=== 0; getReg c 1 H.=== 0
    z_flag c H.=== 1

-- MULS: signed 16 * (-4) = -64 = 0xFFC0 in two's complement.
-- MULS uses UpperRegister so operands are R16 and R17.
prop_muls_basic :: H.Property
prop_muls_basic = det $ do
    let c = exec (Muls 0 1) $ withR 16 16 $ withR 17 0xFC base  -- 0xFC = -4 signed
    getReg c 0 H.=== 0xC0; getReg c 1 H.=== 0xFF  -- -64 = 0xFFC0

-- MULSU: signed * unsigned.  (-2) * 3 = -6 = 0xFFFA.
-- MULSU uses LowerUpperRegister: operand registers are 16 + lur.
-- LowerUpperReg 0 = R16, LowerUpperReg 1 = R17.
prop_mulsu_basic :: H.Property
prop_mulsu_basic = det $ do
    let c = exec (Mulsu 0 1) $ withR 16 0xFE $ withR 17 3 base  -- 0xFE = -2 signed
    getReg c 0 H.=== 0xFA; getReg c 1 H.=== 0xFF  -- -6 = 0xFFFA

-- FMUL: unsigned fractional multiply left-shifted by 1.  0x40 * 0x40 = 0x1000, shifted = 0x2000.
prop_fmul_basic :: H.Property
prop_fmul_basic = det $ do
    let c = exec (Fmul 0 1) $ withR 16 0x40 $ withR 17 0x40 base
    -- 0x40 * 0x40 = 0x1000; <<1 = 0x2000
    getReg c 0 H.=== 0x00; getReg c 1 H.=== 0x20

-- ---------------------------------------------------------------------------
-- ASR / LSR / ROR
-- ---------------------------------------------------------------------------

-- ASR 0x80 = 0xC0: sign bit replicated (arithmetic right shift).
prop_asr_negative :: H.Property
prop_asr_negative = det $ do
    let c = exec (Asr 16) $ withR 16 0x80 base
    getReg c 16 H.=== 0xC0
    c_flag c H.=== 0; n_flag c H.=== 1

-- ASR 0x01 = 0x00: C=1 (bit 0 shifted out), Z=1.
prop_asr_carry_out :: H.Property
prop_asr_carry_out = det $ do
    let c = exec (Asr 16) $ withR 16 0x01 base
    getReg c 16 H.=== 0x00
    c_flag c H.=== 1; z_flag c H.=== 1

-- LSR 0x80 = 0x40: zero filled from MSB, N always 0.
prop_lsr_basic :: H.Property
prop_lsr_basic = det $ do
    let c = exec (Lsr 16) $ withR 16 0x80 base
    getReg c 16 H.=== 0x40
    c_flag c H.=== 0; n_flag c H.=== 0

-- LSR 0x01 = 0x00: C=1, Z=1.
prop_lsr_carry_out :: H.Property
prop_lsr_carry_out = det $ do
    let c = exec (Lsr 16) $ withR 16 0x01 base
    getReg c 16 H.=== 0x00
    c_flag c H.=== 1; z_flag c H.=== 1

-- ROR 0x80 with C=1: 1 rotated into MSB → 0xC0.
prop_ror_carry_in :: H.Property
prop_ror_carry_in = det $ do
    let c = exec (Ror 16) $ withR 16 0x80 $ withC 1 base
    getReg c 16 H.=== 0xC0
    c_flag c H.=== 0  -- bit 0 of 0x80 = 0, so carry out = 0

-- ROR 0x01 with C=0: bit 0 shifts into C, result 0x00.
prop_ror_carry_out :: H.Property
prop_ror_carry_out = det $ do
    let c = exec (Ror 16) $ withR 16 0x01 $ withC 0 base
    getReg c 16 H.=== 0x00
    c_flag c H.=== 1; z_flag c H.=== 1

-- ---------------------------------------------------------------------------
-- MOV / MOVW / LDI / SWAP
-- ---------------------------------------------------------------------------

-- MOV r16, r17: R16 ← R17 (no flags affected).
prop_mov_copies_register :: H.Property
prop_mov_copies_register = det $ do
    let c = exec (Mov 16 17) $ withR 17 0xAB base
    getReg c 16 H.=== 0xAB

-- MOV does not affect source or SREG.
prop_mov_no_side_effects :: H.Property
prop_mov_no_side_effects = det $ do
    let c = exec (Mov 16 17) $ withR 16 0x11 $ withR 17 0xAB $ withC 1 base
    getReg c 17 H.=== 0xAB  -- source unchanged
    c_flag c H.=== 1         -- flags unchanged

-- MOVW 2 4: copy R9:R8 to R5:R4  (rd=2 → regs 4,5; rr=4 → regs 8,9).
prop_movw_copies_pair :: H.Property
prop_movw_copies_pair = det $ do
    let c = exec (Movw 2 4) $ withR 8 0x34 $ withR 9 0x12 base
    getReg c 4 H.=== 0x34; getReg c 5 H.=== 0x12

-- LDI: UpperRegister 0 = R16.  LDI 0 0xAB → R16 = 0xAB.
prop_ldi_basic :: H.Property
prop_ldi_basic = det $ do
    let c = exec (Ldi 0 0xAB) base
    getReg c 16 H.=== 0xAB

-- SWAP 0xA5 = 0x5A.
prop_swap_nibbles :: H.Property
prop_swap_nibbles = det $ do
    let c = exec (Swap 16) $ withR 16 0xA5 base
    getReg c 16 H.=== 0x5A

-- ---------------------------------------------------------------------------
-- CP / CPC / CPI
-- ---------------------------------------------------------------------------

-- CP: equal operands → Z=1, C=0, no register written.
prop_cp_equal :: H.Property
prop_cp_equal = det $ do
    let c = exec (Cp 16 17) $ withR 16 7 $ withR 17 7 base
    z_flag c H.=== 1; c_flag c H.=== 0
    getReg c 16 H.=== 7  -- destination not changed by CP

-- CP: Rd < Rr → C=1 (borrow), N=1.
prop_cp_less_than :: H.Property
prop_cp_less_than = det $ do
    let c = exec (Cp 16 17) $ withR 16 3 $ withR 17 10 base
    c_flag c H.=== 1; n_flag c H.=== 1

-- CPC: carries the carry flag into the subtraction.
prop_cpc_with_carry :: H.Property
prop_cpc_with_carry = det $ do
    let c = exec (Cpc 16 17) $ withR 16 10 $ withR 17 3 $ withC 1 base
    -- 10 - 3 - 1 = 6; result not written, but flags updated
    c_flag c H.=== 0; z_flag c H.=== 0

-- CPI: UpperRegister 0 = R16.  R16 == 5 → Z=1.
prop_cpi_equal :: H.Property
prop_cpi_equal = det $ do
    let c = exec (Cpi 0 5) $ withR 16 5 base
    z_flag c H.=== 1; c_flag c H.=== 0

-- ---------------------------------------------------------------------------
-- BSET / BCLR / BST / BLD
-- ---------------------------------------------------------------------------

-- BSET 0 sets carry (SREG bit 0).
prop_bset_carry :: H.Property
prop_bset_carry = det $ do
    let c = exec (Bset 0) base
    c_flag c H.=== 1

-- BSET 7 sets global interrupt enable (SREG bit 7).
prop_bset_interrupt :: H.Property
prop_bset_interrupt = det $ do
    let c = exec (Bset 7) base
    i_flag c H.=== 1

-- BCLR 0 clears carry.
prop_bclr_carry :: H.Property
prop_bclr_carry = det $ do
    let c = exec (Bclr 0) $ withC 1 base
    c_flag c H.=== 0

-- BCLR 7 clears global interrupt enable.
prop_bclr_interrupt :: H.Property
prop_bclr_interrupt = det $ do
    let c = exec (Bclr 7) $ withI 1 base
    i_flag c H.=== 0

-- BST then BLD: bit 3 of R16 round-trips through T to R17 bit 5.
prop_bst_bld_roundtrip :: H.Property
prop_bst_bld_roundtrip = det $ do
    let c0 = withR 16 0x08 base          -- bit 3 of R16 = 1
        c1 = exec (Bst 16 3) c0          -- T ← bit 3 of R16 = 1
        c2 = exec (Bld 17 5) c1          -- bit 5 of R17 ← T
    t_flag c1 H.=== 1
    getReg c2 17 H.=== 0x20              -- bit 5 set = 0x20

-- BST clears T when the source bit is 0.
prop_bst_clears_t :: H.Property
prop_bst_clears_t = det $ do
    let c = exec (Bst 16 0) $ withR 16 0xFE $ withT 1 base  -- bit 0 = 0
    t_flag c H.=== 0

-- ---------------------------------------------------------------------------
-- IN / OUT / CBI / SBI
-- ---------------------------------------------------------------------------

-- OUT 0x3F (SREG I/O address) writes R16 to SREG; read back via IN.
prop_out_in_sreg :: H.Property
prop_out_in_sreg = det $ do
    let c0 = withR 16 0x80 base              -- bit 7 = I flag
        c1 = exec (Out 0x3F 16) c0           -- SREG ← 0x80
    i_flag c1 H.=== 1                        -- interrupt bit set
    let c2 = exec (In 17 0x3F) c1           -- R17 ← SREG
    getReg c2 17 H.=== 0x80

-- OUT 0x3D (SPL I/O address) writes R16 to SPL (low byte of SP).
-- Starting SP=0, writeInternal gives SP = 0x0000 | 0xAB = 0x00AB.
prop_out_spl :: H.Property
prop_out_spl = det $ do
    let c = exec (Out 0x3D 16) $ withR 16 0xAB base
    sp c H.=== 0x00AB

-- SBI A, b: LowerIORegister is Unsigned 5 (max I/O addr 31 = data addr 0x3F).
-- writeInternal handles 0x00–0x1F and 0x58–0x5F; 0x20–0x57 is a gap.
-- Addresses reachable by SBI/CBI fall in 0x20–0x3F (the unmapped gap), so
-- they leave the state unchanged.  Verify the no-corruption guarantee.
prop_sbi_no_corruption :: H.Property
prop_sbi_no_corruption = det $ do
    let c = exec (Sbi 0 0) $ withR 16 0xAB $ withC 1 base
    getReg c 16 H.=== 0xAB   -- register unchanged
    c_flag c H.=== 1          -- flags unchanged

prop_cbi_no_corruption :: H.Property
prop_cbi_no_corruption = det $ do
    let c = exec (Cbi 0 0) $ withR 16 0xAB $ withC 1 base
    getReg c 16 H.=== 0xAB
    c_flag c H.=== 1

-- ---------------------------------------------------------------------------
-- PUSH / POP
-- ---------------------------------------------------------------------------

-- PUSH decrements SP by 1.
prop_push_decrements_sp :: H.Property
prop_push_decrements_sp = det $ do
    let c = exec (Push 16) $ withSP 0x0200 base
    sp c H.=== 0x01FF

-- POP increments SP by 1 and loads the mval into the destination register.
prop_pop_loads_register :: H.Property
prop_pop_loads_register = det $ do
    let c = load (Pop 16) 0xAB $ withSP 0x01FF base
    sp c H.=== 0x0200
    getReg c 16 H.=== 0xAB

-- ---------------------------------------------------------------------------
-- LD (indirect load): pointer update side-effects
-- ---------------------------------------------------------------------------

-- LD Rd, X: register gets mval; X unchanged.
prop_ld_x_indirect :: H.Property
prop_ld_x_indirect = det $ do
    let c = load (Ld 16 XIndirect) 0xAB $ withX 0x0300 base
    getReg c 16 H.=== 0xAB
    getX c H.=== 0x0300

-- LD Rd, X+: register gets mval; X incremented.
prop_ld_x_post_increment :: H.Property
prop_ld_x_post_increment = det $ do
    let c = load (Ld 16 XIndirectPostIncrement) 0xAB $ withX 0x0300 base
    getReg c 16 H.=== 0xAB
    getX c H.=== 0x0301

-- LD Rd, -X: X decremented; register gets mval.
prop_ld_x_pre_decrement :: H.Property
prop_ld_x_pre_decrement = det $ do
    let c = load (Ld 16 XIndirectPreDecrement) 0xAB $ withX 0x0301 base
    getReg c 16 H.=== 0xAB
    getX c H.=== 0x0300

-- LD Rd, Y+q: register gets mval; Y unchanged.
prop_ld_y_offset :: H.Property
prop_ld_y_offset = det $ do
    let c = load (Ld 16 (YOffset 4)) 0xAB $ withY 0x0300 base
    getReg c 16 H.=== 0xAB
    getY c H.=== 0x0300

-- LD Rd, Z+: register gets mval; Z incremented.
prop_ld_z_post_increment :: H.Property
prop_ld_z_post_increment = det $ do
    let c = load (Ld 16 ZIndirectPostIncrement) 0xAB $ withZ 0x0300 base
    getReg c 16 H.=== 0xAB
    getZ c H.=== 0x0301

-- LD Rd, -Z: Z decremented; register gets mval.
prop_ld_z_pre_decrement :: H.Property
prop_ld_z_pre_decrement = det $ do
    let c = load (Ld 16 ZIndirectPreDecrement) 0xAB $ withZ 0x0301 base
    getReg c 16 H.=== 0xAB
    getZ c H.=== 0x0300

-- LDS: load from direct address via mval.
prop_lds_loads_value :: H.Property
prop_lds_loads_value = det $ do
    let c = load (Lds 16 0x0200) 0xAB base
    getReg c 16 H.=== 0xAB

-- LPM Rd, Z+: loads mval into Rd, Z incremented.
prop_lpm_z_post_increment :: H.Property
prop_lpm_z_post_increment = det $ do
    let c = load (LpmZPlus 16) 0xAB $ withZ 0x0300 base
    getReg c 16 H.=== 0xAB
    getZ c H.=== 0x0301

-- ---------------------------------------------------------------------------
-- ST (indirect store): pointer update and write spec
-- ---------------------------------------------------------------------------

-- ST X, Rr: avrXWrite gives (X, Rr_val).
prop_st_x_write_spec :: H.Property
prop_st_x_write_spec = det $ do
    let c  = withR 16 0xAB $ withX 0x0300 base
    avrXWrite (St 16 XIndirect) c H.=== Just (0x0300, 0xAB)

-- ST X+, Rr: X incremented after store.
prop_st_x_post_increment :: H.Property
prop_st_x_post_increment = det $ do
    let c  = withR 16 0xAB $ withX 0x0300 base
        c' = exec (St 16 XIndirectPostIncrement) c
    getX c' H.=== 0x0301
    avrXWrite (St 16 XIndirectPostIncrement) c H.=== Just (0x0300, 0xAB)

-- ST -X, Rr: X decremented before store (write to old X - 1).
prop_st_x_pre_decrement :: H.Property
prop_st_x_pre_decrement = det $ do
    let c  = withR 16 0xAB $ withX 0x0301 base
        c' = exec (St 16 XIndirectPreDecrement) c
    getX c' H.=== 0x0300
    avrXWrite (St 16 XIndirectPreDecrement) c H.=== Just (0x0300, 0xAB)

-- ST Y+q, Rr: avrXWrite gives (Y+q, Rr_val), Y unchanged.
prop_st_y_offset_write_spec :: H.Property
prop_st_y_offset_write_spec = det $ do
    let c = withR 16 0xAB $ withY 0x0300 base
    avrXWrite (St 16 (YOffset 4)) c H.=== Just (0x0304, 0xAB)

-- ST Z+, Rr: Z incremented after store.
prop_st_z_post_increment :: H.Property
prop_st_z_post_increment = det $ do
    let c  = withR 16 0xAB $ withZ 0x0300 base
        c' = exec (St 16 ZIndirectPostIncrement) c
    getZ c' H.=== 0x0301
    avrXWrite (St 16 ZIndirectPostIncrement) c H.=== Just (0x0300, 0xAB)

-- STS: avrXWrite gives (direct_addr, Rr_val).
prop_sts_write_spec :: H.Property
prop_sts_write_spec = det $ do
    let c = withR 16 0xAB base
    avrXWrite (Sts 0x0200 16) c H.=== Just (0x0200, 0xAB)

-- ---------------------------------------------------------------------------
-- Branches (avrJump)
-- ---------------------------------------------------------------------------

-- RJMP always jumps: new PC = pc + 1 + k.
prop_rjmp_taken :: H.Property
prop_rjmp_taken = det $ do
    let c = withPC 10 base
    avrJump (Rjmp 5) c H.=== Just 16  -- 10 + 1 + 5

prop_rjmp_backward :: H.Property
prop_rjmp_backward = det $ do
    let c = withPC 10 base
    avrJump (Rjmp (-3)) c H.=== Just 8  -- 10 + 1 - 3

-- BRCC: jumps when C=0; stays when C=1.
prop_brcc_taken :: H.Property
prop_brcc_taken = det $ do
    let c = withC 0 (withPC 4 base)
    avrJump (Brcc 2) c H.=== Just 7

prop_brcc_not_taken :: H.Property
prop_brcc_not_taken = det $ do
    let c = withC 1 (withPC 4 base)
    avrJump (Brcc 2) c H.=== Nothing

-- BRCS: jumps when C=1.
prop_brcs_taken :: H.Property
prop_brcs_taken = det $ do
    let c = withC 1 (withPC 4 base)
    avrJump (Brcs 2) c H.=== Just 7

-- BREQ: jumps when Z=1.
prop_breq_taken :: H.Property
prop_breq_taken = det $ do
    let c = withZ_flag 1 (withPC 4 base)
    avrJump (Breq 2) c H.=== Just 7

prop_breq_not_taken :: H.Property
prop_breq_not_taken = det $ do
    let c = withZ_flag 0 (withPC 4 base)
    avrJump (Breq 2) c H.=== Nothing

-- BRNE: jumps when Z=0.
prop_brne_taken :: H.Property
prop_brne_taken = det $ do
    let c = withZ_flag 0 (withPC 4 base)
    avrJump (Brne (-2)) c H.=== Just 3

-- BRGE: jumps when S=0 (N XOR V = 0, signed >=).
prop_brge_taken :: H.Property
prop_brge_taken = det $ do
    let c = withPC 4 base  -- S=0 by default in zeroState
    avrJump (Brge 2) c H.=== Just 7

-- BRLT: jumps when S=1 (signed <).
prop_brlt_taken :: H.Property
prop_brlt_taken = det $ do
    let c = withPC 4 $ base { status = (status base) { sign_flag = 1 } }
    avrJump (Brlt 2) c H.=== Just 7

-- BRMI: jumps when N=1.
prop_brmi_taken :: H.Property
prop_brmi_taken = det $ do
    let c = withN 1 (withPC 4 base)
    avrJump (Brmi 2) c H.=== Just 7

-- BRPL: jumps when N=0.
prop_brpl_taken :: H.Property
prop_brpl_taken = det $ do
    let c = withN 0 (withPC 4 base)
    avrJump (Brpl 2) c H.=== Just 7

-- BRVS: jumps when V=1.
prop_brvs_taken :: H.Property
prop_brvs_taken = det $ do
    let c = withV 1 (withPC 4 base)
    avrJump (Brvs 2) c H.=== Just 7

-- BRVC: jumps when V=0.
prop_brvc_taken :: H.Property
prop_brvc_taken = det $ do
    let c = withV 0 (withPC 4 base)
    avrJump (Brvc 2) c H.=== Just 7

-- BRHS: jumps when H=1.
prop_brhs_taken :: H.Property
prop_brhs_taken = det $ do
    let c = withH 1 (withPC 4 base)
    avrJump (Brhs 2) c H.=== Just 7

-- BRHC: jumps when H=0.
prop_brhc_taken :: H.Property
prop_brhc_taken = det $ do
    let c = withH 0 (withPC 4 base)
    avrJump (Brhc 2) c H.=== Just 7

-- BRTS: jumps when T=1.
prop_brts_taken :: H.Property
prop_brts_taken = det $ do
    let c = withT 1 (withPC 4 base)
    avrJump (Brts 2) c H.=== Just 7

-- BRTC: jumps when T=0.
prop_brtc_taken :: H.Property
prop_brtc_taken = det $ do
    let c = withT 0 (withPC 4 base)
    avrJump (Brtc 2) c H.=== Just 7

-- BRIE: jumps when I=1.
prop_brie_taken :: H.Property
prop_brie_taken = det $ do
    let c = withI 1 (withPC 4 base)
    avrJump (Brie 2) c H.=== Just 7

-- BRID: jumps when I=0.
prop_brid_taken :: H.Property
prop_brid_taken = det $ do
    let c = withI 0 (withPC 4 base)
    avrJump (Brid 2) c H.=== Just 7

-- ---------------------------------------------------------------------------
-- NOP / RETI
-- ---------------------------------------------------------------------------

-- NOP leaves all registers and flags unchanged.
prop_nop_no_effect :: H.Property
prop_nop_no_effect = det $ do
    let c0 = withR 16 0xAB $ withC 1 base
        c1 = exec Nop c0
    getReg c1 16 H.=== 0xAB
    c_flag c1 H.=== 1

-- RETI sets the global interrupt flag I (SREG bit 7).
prop_reti_sets_i :: H.Property
prop_reti_sets_i = det $ do
    let c = exec Reti $ withI 0 base
    i_flag c H.=== 1

instructionTests :: TestTree
instructionTests = $(testGroupGenerator)
