module AVR.ALU where

import Clash.Prelude
import AVR.Core
import AVR.InstructionSet
import Core.ALU

-- ---------------------------------------------------------------------------
-- Register file access
-- ---------------------------------------------------------------------------

getReg :: CoreData n -> Register -> AVRWord
getReg core rd = registers core !! (fromIntegral rd :: Index 32)

setReg :: KnownNat n => CoreData n -> Register -> AVRWord -> CoreData n
setReg core rd val =
    core { registers = replace (fromIntegral rd :: Index 32) val (registers core) }

getRegPair :: CoreData n -> Register -> Unsigned 16
getRegPair core rlo =
    zeroExtend (getReg core (rlo + 1)) `shiftL` 8
    .|. zeroExtend (getReg core rlo)

setRegPair :: KnownNat n => CoreData n -> Register -> Unsigned 16 -> CoreData n
setRegPair core rlo v =
    setReg (setReg core rlo (truncateB v)) (rlo + 1) (truncateB (v `shiftR` 8))

-- ADIW/SBIW register base: WideUpperRegister 0→R24, 1→R26, 2→R28, 3→R30
wideBase :: WideUpperRegister -> Register
wideBase wr = 24 + 2 * zeroExtend wr

upperReg :: UpperRegister -> Register
upperReg ur = 16 + zeroExtend ur

lowerUpperReg :: LowerUpperRegister -> Register
lowerUpperReg lur = 16 + zeroExtend lur

-- X=R27:R26  Y=R29:R28  Z=R31:R30
getX, getY, getZ :: CoreData n -> Unsigned 16
getX c = getRegPair c 26
getY c = getRegPair c 28
getZ c = getRegPair c 30

setX, setY, setZ :: KnownNat n => CoreData n -> Unsigned 16 -> CoreData n
setX c v = setRegPair c 26 v
setY c v = setRegPair c 28 v
setZ c v = setRegPair c 30 v

-- ---------------------------------------------------------------------------
-- Internal memory map
-- The AVR data address space maps 0x0000-0x005F directly to CoreData fields.
-- Addresses 0x0000-0x001F are the register file.
-- Addresses 0x0058-0x005F are the special registers.
-- ---------------------------------------------------------------------------

readInternal :: CoreData n -> AVRAddr -> AVRWord
readInternal core addr
    | addr <= 0x001F = getReg core (fromIntegral addr)
    | addr == 0x0058 = rampd core
    | addr == 0x0059 = rampx core
    | addr == 0x005A = rampy core
    | addr == 0x005B = rampz core
    | addr == 0x005C = eind core
    | addr == 0x005D = truncateB (sp core)
    | addr == 0x005E = truncateB (sp core `shiftR` 8)
    | addr == 0x005F = bitCoerce (pack (status core))
    | otherwise      = 0

writeInternal :: KnownNat n => CoreData n -> AVRAddr -> AVRWord -> CoreData n
writeInternal core addr val
    | addr <= 0x001F = setReg core (fromIntegral addr) val
    | addr == 0x0058 = core { rampd = val }
    | addr == 0x0059 = core { rampx = val }
    | addr == 0x005A = core { rampy = val }
    | addr == 0x005B = core { rampz = val }
    | addr == 0x005C = core { eind = val }
    | addr == 0x005D = core { sp = sp core .&. 0xFF00 .|. zeroExtend val }
    | addr == 0x005E = core { sp = sp core .&. 0x00FF .|. zeroExtend val `shiftL` 8 }
    | addr == 0x005F = core { status = unpack (pack val) }
    | otherwise      = core

-- I/O address (IN/OUT, CBI/SBI etc.) to data address
ioToData :: ShortImmediate -> AVRAddr
ioToData a = 0x20 + zeroExtend a

-- ---------------------------------------------------------------------------
-- 8-bit arithmetic primitives
-- Unsigned 9-bit arithmetic: the carry/borrow lives in bit 8.
-- Wrapping subtraction on Unsigned naturally produces the borrow in bit 8.
-- ---------------------------------------------------------------------------

-- Returns (result, carry-out, half-carry)
add8 :: AVRWord -> AVRWord -> Bit -> (AVRWord, Bit, Bit)
add8 rd rr cin =
    let c    = zeroExtend (unpack (pack cin) :: Unsigned 1) :: Unsigned 9
        s9   = zeroExtend rd + zeroExtend rr + c
        r    = truncateB s9 :: AVRWord
        co   = msb (pack s9)
        h5   = zeroExtend (truncateB rd :: Unsigned 4)
             + zeroExtend (truncateB rr :: Unsigned 4)
             + zeroExtend (unpack (pack cin) :: Unsigned 1)
             :: Unsigned 5
        hc   = msb (pack h5)
    in (r, co, hc)

-- Returns (result, borrow-out, half-borrow)
sub8 :: AVRWord -> AVRWord -> Bit -> (AVRWord, Bit, Bit)
sub8 rd rr bin =
    let b    = zeroExtend (unpack (pack bin) :: Unsigned 1) :: Unsigned 9
        diff9 = zeroExtend rd - zeroExtend rr - b
        r    = truncateB diff9 :: AVRWord
        bo   = msb (pack diff9)
        h5   = zeroExtend (truncateB rd :: Unsigned 4)
             - zeroExtend (truncateB rr :: Unsigned 4)
             - zeroExtend (unpack (pack bin) :: Unsigned 1)
             :: Unsigned 5
        hb   = msb (pack h5)
    in (r, bo, hb)

-- ---------------------------------------------------------------------------
-- SREG update helpers
-- ---------------------------------------------------------------------------

-- Bit 7 (MSB) of an AVRWord as a Bit
b7 :: AVRWord -> Bit
b7 w = msb (pack w)

-- Bit 0 (LSB) of an AVRWord as a Bit
b0 :: AVRWord -> Bit
b0 w = lsb (pack w)

-- Bool to Bit
bb :: Bool -> Bit
bb = boolToBit

-- Flags set by ADD/ADC: H S V N Z C
sregAdd :: AVRWord -> AVRWord -> AVRWord -> Bit -> Bit -> StatusRegister -> StatusRegister
sregAdd rd rr r co hc s =
    let v = (complement (b7 rd) .&. complement (b7 rr) .&. b7 r)
         .|. (b7 rd .&. b7 rr .&. complement (b7 r))
        n = b7 r
    in s { carry_flag = co, half_carry = hc, overflow_flag = v
         , negative_flag = n, zero_flag = bb (r == 0), sign_flag = n `xor` v }

-- Flags set by SUB/SBC/CP/CPC: H S V N Z C
-- preserveZ=True for CPC/SBCI (Z is ANDed: only cleared when result /= 0)
sregSub :: Bool -> AVRWord -> AVRWord -> AVRWord -> Bit -> Bit -> StatusRegister -> StatusRegister
sregSub preserveZ rd rr r bo hb s =
    let v = (b7 rd .&. complement (b7 rr) .&. complement (b7 r))
         .|. (complement (b7 rd) .&. b7 rr .&. b7 r)
        n = b7 r
        z = if preserveZ then bb (r == 0) .&. zero_flag s else bb (r == 0)
    in s { carry_flag = bo, half_carry = hb, overflow_flag = v
         , negative_flag = n, zero_flag = z, sign_flag = n `xor` v }

-- Flags set by AND/OR/EOR: S V N Z  (V cleared, H unchanged, C unchanged)
sregLogic :: AVRWord -> StatusRegister -> StatusRegister
sregLogic r s =
    let n = b7 r
    in s { overflow_flag = 0, negative_flag = n
         , zero_flag = bb (r == 0), sign_flag = n }

-- Flags set by ADIW
sregAdiw :: Unsigned 16 -> Unsigned 16 -> StatusRegister -> StatusRegister
sregAdiw rdOld r s =
    let rdh7 = msb (pack rdOld)
        r15  = msb (pack r)
        v    = complement rdh7 .&. r15   -- was pos, now neg
        c    = rdh7 .&. complement r15   -- wrapped past 0xFFFF
        n    = r15
    in s { carry_flag = c, overflow_flag = v, negative_flag = n
         , zero_flag = bb (r == 0), sign_flag = n `xor` v }

-- Flags set by SBIW
sregSbiw :: Unsigned 16 -> Unsigned 16 -> StatusRegister -> StatusRegister
sregSbiw rdOld r s =
    let rdh7 = msb (pack rdOld)
        r15  = msb (pack r)
        v    = rdh7 .&. complement r15   -- was neg, now pos (underflow)
        c    = r15 .&. complement rdh7   -- borrow
        n    = r15
    in s { carry_flag = c, overflow_flag = v, negative_flag = n
         , zero_flag = bb (r == 0), sign_flag = n `xor` v }

-- ---------------------------------------------------------------------------
-- Main compute function
-- ---------------------------------------------------------------------------

avrCompute :: KnownNat pcBits
           => Instruction -> Maybe AVRWord -> CoreData pcBits -> CoreData pcBits

-- ── Arithmetic ──────────────────────────────────────────────────────────────

avrCompute (Add rd rr) _ c =
    let (r, co, hc) = add8 (getReg c rd) (getReg c rr) 0
    in setReg c { status = sregAdd (getReg c rd) (getReg c rr) r co hc (status c) } rd r

avrCompute (Adc rd rr) _ c =
    let (r, co, hc) = add8 (getReg c rd) (getReg c rr) (carry_flag (status c))
    in setReg c { status = sregAdd (getReg c rd) (getReg c rr) r co hc (status c) } rd r

avrCompute (Adiw wr k) _ c =
    let base = wideBase wr
        old  = getRegPair c base
        r    = old + zeroExtend k
    in setRegPair c { status = sregAdiw old r (status c) } base r

avrCompute (Sub rd rr) _ c =
    let (r, bo, hb) = sub8 (getReg c rd) (getReg c rr) 0
    in setReg c { status = sregSub False (getReg c rd) (getReg c rr) r bo hb (status c) } rd r

avrCompute (Subi rd k) _ c =
    let rd' = upperReg rd
        (r, bo, hb) = sub8 (getReg c rd') k 0
    in setReg c { status = sregSub False (getReg c rd') k r bo hb (status c) } rd' r

avrCompute (Sbc rd rr) _ c =
    let (r, bo, hb) = sub8 (getReg c rd) (getReg c rr) (carry_flag (status c))
    in setReg c { status = sregSub False (getReg c rd) (getReg c rr) r bo hb (status c) } rd r

avrCompute (Sbci rd k) _ c =
    let rd' = upperReg rd
        (r, bo, hb) = sub8 (getReg c rd') k (carry_flag (status c))
    in setReg c { status = sregSub True (getReg c rd') k r bo hb (status c) } rd' r

avrCompute (Sbiw wr k) _ c =
    let base = wideBase wr
        old  = getRegPair c base
        r    = old - zeroExtend k
    in setRegPair c { status = sregSbiw old r (status c) } base r

avrCompute (Com rd) _ c =
    let r = complement (getReg c rd)
        n = b7 r
    in setReg c { status = (status c) { carry_flag = 1, overflow_flag = 0
                                      , negative_flag = n, zero_flag = bb (r == 0)
                                      , sign_flag = n } } rd r

avrCompute (Neg rd) _ c =
    let rdv = getReg c rd
        r   = 0 - rdv
        n   = b7 r
        v   = bb (r == 0x80)
        h   = b7 r .|. unpack (slice d3 d3 (pack rdv))
    in setReg c { status = (status c) { carry_flag = bb (r /= 0), half_carry = h
                                      , overflow_flag = v, negative_flag = n
                                      , zero_flag = bb (r == 0), sign_flag = n `xor` v } } rd r

avrCompute (Inc rd) _ c =
    let r = getReg c rd + 1
        v = bb (r == 0x80)
        n = b7 r
    in setReg c { status = (status c) { overflow_flag = v, negative_flag = n
                                      , zero_flag = bb (r == 0), sign_flag = n `xor` v } } rd r

avrCompute (Dec rd) _ c =
    let r = getReg c rd - 1
        v = bb (r == 0x7F)
        n = b7 r
    in setReg c { status = (status c) { overflow_flag = v, negative_flag = n
                                      , zero_flag = bb (r == 0), sign_flag = n `xor` v } } rd r

-- ── Logic ────────────────────────────────────────────────────────────────────

avrCompute (AVR.InstructionSet.And rd rr) _ c =
    let r = getReg c rd .&. getReg c rr
    in setReg c { status = sregLogic r (status c) } rd r

avrCompute (Andi rd k) _ c =
    let rd' = upperReg rd; r = getReg c rd' .&. k
    in setReg c { status = sregLogic r (status c) } rd' r

avrCompute (Or rd rr) _ c =
    let r = getReg c rd .|. getReg c rr
    in setReg c { status = sregLogic r (status c) } rd r

avrCompute (Ori rd k) _ c =
    let rd' = upperReg rd; r = getReg c rd' .|. k
    in setReg c { status = sregLogic r (status c) } rd' r

avrCompute (Eor rd rr) _ c =
    let r = getReg c rd `xor` getReg c rr
    in setReg c { status = sregLogic r (status c) } rd r

-- ── Multiply ─────────────────────────────────────────────────────────────────

avrCompute (Mul rd rr) _ c =
    let p = zeroExtend (getReg c rd) * zeroExtend (getReg c rr) :: Unsigned 16
        c' = setReg (setReg c 0 (truncateB p)) 1 (truncateB (p `shiftR` 8))
    in c' { status = (status c') { carry_flag = msb (pack p), zero_flag = bb (p == 0) } }

avrCompute (Muls rd rr) _ c =
    let rd' = upperReg rd; rr' = upperReg rr
        a   = bitCoerce (getReg c rd') :: Signed 8
        b   = bitCoerce (getReg c rr') :: Signed 8
        p   = signExtend a * signExtend b :: Signed 16
        pu  = bitCoerce p :: Unsigned 16
        c'  = setReg (setReg c 0 (truncateB pu)) 1 (truncateB (pu `shiftR` 8))
    in c' { status = (status c') { carry_flag = msb (pack pu), zero_flag = bb (pu == 0) } }

avrCompute (Mulsu rd rr) _ c =
    let rd' = lowerUpperReg rd; rr' = lowerUpperReg rr
        a   = signExtend (bitCoerce (getReg c rd') :: Signed 8) :: Signed 16
        b   = fromIntegral (getReg c rr') :: Signed 16
        p   = a * b
        pu  = bitCoerce p :: Unsigned 16
        c'  = setReg (setReg c 0 (truncateB pu)) 1 (truncateB (pu `shiftR` 8))
    in c' { status = (status c') { carry_flag = msb (pack pu), zero_flag = bb (pu == 0) } }

avrCompute (Fmul rd rr) _ c =
    let p  = zeroExtend (getReg c (lowerUpperReg rd)) * zeroExtend (getReg c (lowerUpperReg rr)) :: Unsigned 16
        p' = p `shiftL` 1
        c' = setReg (setReg c 0 (truncateB p')) 1 (truncateB (p' `shiftR` 8))
    in c' { status = (status c') { carry_flag = msb (pack p), zero_flag = bb (p' == 0) } }

avrCompute (Fmuls rd rr) _ c =
    let a  = signExtend (bitCoerce (getReg c (lowerUpperReg rd)) :: Signed 8) :: Signed 16
        b  = signExtend (bitCoerce (getReg c (lowerUpperReg rr)) :: Signed 8) :: Signed 16
        p  = a * b
        pu = bitCoerce (p `shiftL` 1) :: Unsigned 16
        c' = setReg (setReg c 0 (truncateB pu)) 1 (truncateB (pu `shiftR` 8))
    in c' { status = (status c') { carry_flag = msb (pack (bitCoerce p :: Unsigned 16))
                                 , zero_flag = bb (pu == 0) } }

avrCompute (Fmulsu rd rr) _ c =
    let a  = signExtend (bitCoerce (getReg c (lowerUpperReg rd)) :: Signed 8) :: Signed 16
        b  = fromIntegral (getReg c (lowerUpperReg rr)) :: Signed 16
        p  = a * b
        pu = bitCoerce (p `shiftL` 1) :: Unsigned 16
        c' = setReg (setReg c 0 (truncateB pu)) 1 (truncateB (pu `shiftR` 8))
    in c' { status = (status c') { carry_flag = msb (pack (bitCoerce p :: Unsigned 16))
                                 , zero_flag = bb (pu == 0) } }

-- ── Shift and rotate ─────────────────────────────────────────────────────────

avrCompute (Asr rd) _ c =
    let rdv = pack (getReg c rd) :: BitVector 8
        r   = unpack (slice d7 d7 rdv ++# slice d7 d1 rdv) :: AVRWord
        co  = unpack (slice d0 d0 rdv) :: Bit
        n   = b7 r
        v   = n `xor` co
    in setReg c { status = (status c) { carry_flag = co, overflow_flag = v
                                      , negative_flag = n, zero_flag = bb (r == 0)
                                      , sign_flag = n `xor` v } } rd r

avrCompute (Lsr rd) _ c =
    let rdv = pack (getReg c rd) :: BitVector 8
        r   = unpack ((0 :: BitVector 1) ++# slice d7 d1 rdv) :: AVRWord
        co  = unpack (slice d0 d0 rdv) :: Bit
    in setReg c { status = (status c) { carry_flag = co, overflow_flag = co
                                      , negative_flag = 0, zero_flag = bb (r == 0)
                                      , sign_flag = co } } rd r

avrCompute (Ror rd) _ c =
    let rdv  = pack (getReg c rd) :: BitVector 8
        cin  = pack (carry_flag (status c)) :: BitVector 1
        r    = unpack (cin ++# slice d7 d1 rdv) :: AVRWord
        co   = unpack (slice d0 d0 rdv) :: Bit
        n    = b7 r
        v    = n `xor` co
    in setReg c { status = (status c) { carry_flag = co, overflow_flag = v
                                      , negative_flag = n, zero_flag = bb (r == 0)
                                      , sign_flag = n `xor` v } } rd r

-- ── Data movement ────────────────────────────────────────────────────────────

avrCompute (Mov rd rr) _ c = setReg c rd (getReg c rr)

avrCompute (Movw rd rr) _ c =
    let lo = getReg c (2 * zeroExtend rr)
        hi = getReg c (2 * zeroExtend rr + 1)
    in setReg (setReg c (2 * zeroExtend rd) lo) (2 * zeroExtend rd + 1) hi

avrCompute (Ldi rd k) _ c = setReg c (upperReg rd) k

avrCompute (Swap rd) _ c =
    let bv = pack (getReg c rd) :: BitVector 8
    in setReg c rd (unpack (slice d3 d0 bv ++# slice d7 d4 bv))

-- ── Compare (SREG only, no register write) ───────────────────────────────────

avrCompute (Cp rd rr) _ c =
    let (r, bo, hb) = sub8 (getReg c rd) (getReg c rr) 0
    in c { status = sregSub False (getReg c rd) (getReg c rr) r bo hb (status c) }

avrCompute (Cpc rd rr) _ c =
    let (r, bo, hb) = sub8 (getReg c rd) (getReg c rr) (carry_flag (status c))
    in c { status = sregSub True (getReg c rd) (getReg c rr) r bo hb (status c) }

avrCompute (Cpi rd k) _ c =
    let rd' = upperReg rd
        (r, bo, hb) = sub8 (getReg c rd') k 0
    in c { status = sregSub False (getReg c rd') k r bo hb (status c) }

-- ── SREG bit manipulation ────────────────────────────────────────────────────

-- Use the BitPack instance: treat SREG as an 8-bit word and set/clear bits.
avrCompute (Bset s) _ c =
    let w = bitCoerce (pack (status c)) :: AVRWord
    in c { status = unpack (pack (w .|. 1 `shiftL` fromIntegral s)) }

avrCompute (Bclr s) _ c =
    let w = bitCoerce (pack (status c)) :: AVRWord
    in c { status = unpack (pack (w .&. complement (1 `shiftL` fromIntegral s))) }

avrCompute (Seb s) _ c =
    let w = bitCoerce (pack (status c)) :: AVRWord
    in c { status = unpack (pack (w .|. 1 `shiftL` fromIntegral s)) }
avrCompute (Clb s) _ c =
    let w = bitCoerce (pack (status c)) :: AVRWord
    in c { status = unpack (pack (w .&. complement (1 `shiftL` fromIntegral s))) }

-- BST: T ← Rr(b)
avrCompute (Bst rd b) _ c =
    let t = bb (testBit (getReg c rd) (fromIntegral b))
    in c { status = (status c) { bit_copy = t } }

-- BLD: Rd(b) ← T
avrCompute (Bld rd b) _ c =
    let t    = bit_copy (status c)
        mask = 1 `shiftL` fromIntegral b :: AVRWord
        r    = if t == 1 then getReg c rd .|. mask
                         else getReg c rd .&. complement mask
    in setReg c rd r

-- ── I/O via internal memory map ──────────────────────────────────────────────

avrCompute (In rd a) _ c =
    setReg c rd (readInternal c (ioToData a))

avrCompute (Out a rr) _ c =
    writeInternal c (ioToData a) (getReg c rr)

-- CBI/SBI: clear/set one bit in an I/O register
avrCompute (Cbi a b) _ c =
    let addr = ioToData (zeroExtend a)
        mask = 1 `shiftL` fromIntegral b :: AVRWord
    in writeInternal c addr (readInternal c addr .&. complement mask)

avrCompute (Sbi a b) _ c =
    let addr = ioToData (zeroExtend a)
        mask = 1 `shiftL` fromIntegral b :: AVRWord
    in writeInternal c addr (readInternal c addr .|. mask)

-- ── Stack ────────────────────────────────────────────────────────────────────

-- PUSH decrements SP; the executor writes Rr to the pre-decrement address.
avrCompute (Push _) _ c = c { sp = sp c - 1 }

-- POP increments SP; the executor reads the new-SP address, passes value here.
avrCompute (Pop rd) mval c =
    let c' = c { sp = sp c + 1 }
    in case mval of { Nothing -> c'; Just v -> setReg c' rd v }

-- ── Memory load result: store into destination register ──────────────────────
-- Pointer register updates (X/Y/Z ++/--) happen here so the executor only
-- needs to compute the address and supply the value.

avrCompute (Ld rd XIndirect)              mval c = storeLoad c rd mval
avrCompute (Ld rd XIndirectPostIncrement) mval c = storeLoad (setX c (getX c + 1)) rd mval
avrCompute (Ld rd XIndirectPreDecrement)  mval c = storeLoad (setX c (getX c - 1)) rd mval
avrCompute (Ld rd YIndirect)              mval c = storeLoad c rd mval
avrCompute (Ld rd YIndirectPostIncrement) mval c = storeLoad (setY c (getY c + 1)) rd mval
avrCompute (Ld rd YIndirectPreDecrement)  mval c = storeLoad (setY c (getY c - 1)) rd mval
avrCompute (Ld rd (YOffset _))            mval c = storeLoad c rd mval
avrCompute (Ld rd ZIndirect)              mval c = storeLoad c rd mval
avrCompute (Ld rd ZIndirectPostIncrement) mval c = storeLoad (setZ c (getZ c + 1)) rd mval
avrCompute (Ld rd ZIndirectPreDecrement)  mval c = storeLoad (setZ c (getZ c - 1)) rd mval
avrCompute (Ld rd (ZOffset _))            mval c = storeLoad c rd mval
avrCompute (Ld rd (XOffset _))            mval c = storeLoad c rd mval  -- not a real AVR mode
avrCompute (Lds rd _)  mval c = storeLoad c rd mval
avrCompute (Lpm)       mval c = storeLoad c 0 mval
avrCompute (LpmZ  rd)  mval c = storeLoad c rd mval
avrCompute (LpmZPlus rd) mval c = storeLoad (setZ c (getZ c + 1)) rd mval
avrCompute (Elpm)          mval c = storeLoad c 0 mval
avrCompute (ElpmZ rd)      mval c = storeLoad c rd mval
avrCompute (ElpmZPlus rd)  mval c = storeLoad (setZ c (getZ c + 1)) rd mval

-- Read-modify-write atomics: executor supplies old DS(Z), compute updates Rd
-- and stores the new DS(Z) value; executor handles the write-back.
avrCompute (Xch rd) mval c =
    case mval of { Nothing -> c; Just v -> setReg c rd v }   -- Rd ← DS(Z)
avrCompute (Las rd) mval c =
    case mval of { Nothing -> c; Just v -> setReg c rd v }   -- Rd ← DS(Z)
avrCompute (Lac rd) mval c =
    case mval of { Nothing -> c; Just v -> setReg c rd v }   -- Rd ← DS(Z)
avrCompute (Lat rd) mval c =
    case mval of { Nothing -> c; Just v -> setReg c rd v }   -- Rd ← DS(Z)

-- RETI restores the global interrupt flag.
avrCompute Reti _ c = c { status = (status c) { interrupt_flag = 1 } }

-- ── ST pointer register updates ───────────────────────────────────────────
-- avrXWrite uses PRE-compute state for the write address, so pointer
-- updates must happen here (compute) so the post-execute state is correct.
avrCompute (St _ XIndirectPostIncrement) _ c = setX c (getX c + 1)
avrCompute (St _ XIndirectPreDecrement)  _ c = setX c (getX c - 1)
avrCompute (St _ YIndirectPostIncrement) _ c = setY c (getY c + 1)
avrCompute (St _ YIndirectPreDecrement)  _ c = setY c (getY c - 1)
avrCompute (St _ ZIndirectPostIncrement) _ c = setZ c (getZ c + 1)
avrCompute (St _ ZIndirectPreDecrement)  _ c = setZ c (getZ c - 1)

-- NOP, SLEEP, WDR, BREAK, ST (non-modifying modes), all branch/jump: no compute effect.
avrCompute _ _ c = c

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

storeLoad :: KnownNat n => CoreData n -> Register -> Maybe AVRWord -> CoreData n
storeLoad c rd = maybe c (setReg c rd)

-- ---------------------------------------------------------------------------
-- Remaining ALU record (interfaces stubbed pending executor design)
-- ---------------------------------------------------------------------------

avrXALU :: KnownNat pcBits
         => ALU Instruction (CoreData pcBits) AVRXAddr (Unsigned pcBits) AVRWord
avrXALU = ALU
    { read    = avrXRead
    , compute = avrCompute
    , write   = avrXWrite
    , jump    = avrJump
    }

avrXRead :: KnownNat pcBits => Instruction -> CoreData pcBits -> Maybe AVRXAddr
avrXRead (Pop _)      c = Just (zeroExtend (sp c) + 1)
avrXRead (Ld _ XIndirect)              c = Just (zeroExtend (getX c))
avrXRead (Ld _ XIndirectPostIncrement) c = Just (zeroExtend (getX c))
avrXRead (Ld _ XIndirectPreDecrement)  c = Just (zeroExtend (getX c) - 1)
avrXRead (Ld _ YIndirect)              c = Just (zeroExtend (getY c))
avrXRead (Ld _ YIndirectPostIncrement) c = Just (zeroExtend (getY c))
avrXRead (Ld _ YIndirectPreDecrement)  c = Just (zeroExtend (getY c) - 1)
avrXRead (Ld _ (YOffset q))            c = Just (zeroExtend (getY c) + zeroExtend q)
avrXRead (Ld _ ZIndirect)              c = Just (zeroExtend (getZ c))
avrXRead (Ld _ ZIndirectPostIncrement) c = Just (zeroExtend (getZ c))
avrXRead (Ld _ ZIndirectPreDecrement)  c = Just (zeroExtend (getZ c) - 1)
avrXRead (Ld _ (ZOffset q))            c = Just (zeroExtend (getZ c) + zeroExtend q)
avrXRead (Lds _ k)    _ = Just (zeroExtend k)
avrXRead (Lpm)        c = Just (zeroExtend (getZ c))
avrXRead (LpmZ _)     c = Just (zeroExtend (getZ c))
avrXRead (LpmZPlus _) c = Just (zeroExtend (getZ c))
avrXRead (Elpm)           c = Just (zeroExtend (rampz c) `shiftL` 16 .|. zeroExtend (getZ c))
avrXRead (ElpmZ _)        c = Just (zeroExtend (rampz c) `shiftL` 16 .|. zeroExtend (getZ c))
avrXRead (ElpmZPlus _)    c = Just (zeroExtend (rampz c) `shiftL` 16 .|. zeroExtend (getZ c))
avrXRead (Xch _)      c = Just (zeroExtend (getZ c))
avrXRead (Las _)      c = Just (zeroExtend (getZ c))
avrXRead (Lac _)      c = Just (zeroExtend (getZ c))
avrXRead (Lat _)      c = Just (zeroExtend (getZ c))
avrXRead (Sbic a _)   _ = Just (zeroExtend (ioToData (zeroExtend a)))
avrXRead (Sbis a _)   _ = Just (zeroExtend (ioToData (zeroExtend a)))
avrXRead _            _ = Nothing

avrXWrite :: KnownNat pcBits
          => Instruction -> CoreData pcBits -> Maybe (AVRXAddr, AVRWord)
avrXWrite (Push rr)   c = Just (zeroExtend (sp c), getReg c rr)
avrXWrite (St rr XIndirect)              c = Just (zeroExtend (getX c),           getReg c rr)
avrXWrite (St rr XIndirectPostIncrement) c = Just (zeroExtend (getX c),           getReg c rr)
avrXWrite (St rr XIndirectPreDecrement)  c = Just (zeroExtend (getX c) - 1,       getReg c rr)
avrXWrite (St rr YIndirect)              c = Just (zeroExtend (getY c),           getReg c rr)
avrXWrite (St rr YIndirectPostIncrement) c = Just (zeroExtend (getY c),           getReg c rr)
avrXWrite (St rr YIndirectPreDecrement)  c = Just (zeroExtend (getY c) - 1,       getReg c rr)
avrXWrite (St rr (YOffset q))            c = Just (zeroExtend (getY c + zeroExtend q), getReg c rr)
avrXWrite (St rr ZIndirect)              c = Just (zeroExtend (getZ c),           getReg c rr)
avrXWrite (St rr ZIndirectPostIncrement) c = Just (zeroExtend (getZ c),           getReg c rr)
avrXWrite (St rr ZIndirectPreDecrement)  c = Just (zeroExtend (getZ c) - 1,       getReg c rr)
avrXWrite (St rr (ZOffset q))            c = Just (zeroExtend (getZ c + zeroExtend q), getReg c rr)
avrXWrite (St _  (XOffset _))            _ = Nothing  -- not a real AVR mode
avrXWrite (Sts k rr) c = Just (zeroExtend k,                                    getReg c rr)
-- RMW atomics: write the computed new value back to DS(Z)
avrXWrite (Xch rd) c = Just (zeroExtend (getZ c), getReg c rd `xor` getReg c rd) -- TODO: proper RMW
avrXWrite (Las rd) c = Just (zeroExtend (getZ c), getReg c rd)   -- DS(Z) ← Rd ∨ DS(Z): needs old DS(Z)
avrXWrite (Lac rd) c = Just (zeroExtend (getZ c), getReg c rd)   -- TODO: needs old DS(Z)
avrXWrite (Lat rd) c = Just (zeroExtend (getZ c), getReg c rd)   -- TODO: needs old DS(Z)
avrXWrite _ _ = Nothing

avrJump :: KnownNat pcBits => Instruction -> CoreData pcBits -> Maybe (Unsigned pcBits)
avrJump (Rjmp k)  c = Just (pc c + 1 + fromIntegral k)
avrJump (Rcall k) c = Just (pc c + 1 + fromIntegral k)
avrJump (Jmp k)   _ = Just (fromIntegral k)
avrJump (Call k)  _ = Just (fromIntegral k)
avrJump Ijmp      c = Just (fromIntegral (getZ c))
avrJump Icall     c = Just (fromIntegral (getZ c))
avrJump Eijmp     c = Just (fromIntegral (zeroExtend (eind c) `shiftL` 16 .|. zeroExtend (getZ c) :: Unsigned 24))
avrJump Eicall    c = Just (fromIntegral (zeroExtend (eind c) `shiftL` 16 .|. zeroExtend (getZ c) :: Unsigned 24))
avrJump Ret       _ = Nothing  -- executor pops PC from stack
avrJump Reti      _ = Nothing  -- executor pops PC from stack
avrJump (Brcc k) c = if carry_flag    (status c) == 0 then Just (pc c + 1 + fromIntegral k) else Nothing
avrJump (Brcs k) c = if carry_flag    (status c) == 1 then Just (pc c + 1 + fromIntegral k) else Nothing
avrJump (Breq k) c = if zero_flag     (status c) == 1 then Just (pc c + 1 + fromIntegral k) else Nothing
avrJump (Brne k) c = if zero_flag     (status c) == 0 then Just (pc c + 1 + fromIntegral k) else Nothing
avrJump (Brge k) c = if sign_flag     (status c) == 0 then Just (pc c + 1 + fromIntegral k) else Nothing
avrJump (Brlt k) c = if sign_flag     (status c) == 1 then Just (pc c + 1 + fromIntegral k) else Nothing
avrJump (Brmi k) c = if negative_flag (status c) == 1 then Just (pc c + 1 + fromIntegral k) else Nothing
avrJump (Brpl k) c = if negative_flag (status c) == 0 then Just (pc c + 1 + fromIntegral k) else Nothing
avrJump (Brvs k) c = if overflow_flag (status c) == 1 then Just (pc c + 1 + fromIntegral k) else Nothing
avrJump (Brvc k) c = if overflow_flag (status c) == 0 then Just (pc c + 1 + fromIntegral k) else Nothing
avrJump (Brhs k) c = if half_carry    (status c) == 1 then Just (pc c + 1 + fromIntegral k) else Nothing
avrJump (Brhc k) c = if half_carry    (status c) == 0 then Just (pc c + 1 + fromIntegral k) else Nothing
avrJump (Brts k) c = if bit_copy      (status c) == 1 then Just (pc c + 1 + fromIntegral k) else Nothing
avrJump (Brtc k) c = if bit_copy      (status c) == 0 then Just (pc c + 1 + fromIntegral k) else Nothing
avrJump (Brie k) c = if interrupt_flag(status c) == 1 then Just (pc c + 1 + fromIntegral k) else Nothing
avrJump (Brid k) c = if interrupt_flag(status c) == 0 then Just (pc c + 1 + fromIntegral k) else Nothing
avrJump (Brlo k) c = if carry_flag (status c) == 1 then Just (pc c + 1 + fromIntegral k) else Nothing
avrJump (Brsh k) c = if carry_flag (status c) == 0 then Just (pc c + 1 + fromIntegral k) else Nothing
avrJump _ _ = Nothing
