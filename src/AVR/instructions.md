# AVR Instruction Set Reference

Source: AVR® Instruction Set Manual DS40002198B (Microchip, 2021)

## CPU Core Variants

| Core   | Description                                                        |
|--------|--------------------------------------------------------------------|
| AVRe   | Base. Adds MOVW and enhanced LPM over original 1995 AVR.          |
| AVRe+  | AVRe + MUL/MULS/MULSU/FMUL/FMULS/FMULSU. ELPM/EIJMP/EICALL on >64KB devices. |
| AVRxm  | AVRe+ + DES + RMW (LAC/LAS/LAT/XCH) + SPM Z+. XMEGA family.     |
| AVRxt  | Same instructions as AVRe+, improved timing. tinyAVR 0/1/2, AVR Dx. |
| AVRrc  | Reduced: R16–R31 only. No CALL/JMP/MOVW/ADIW/SBIW/MUL/ELPM.     |

## SREG Bit Layout

| Bit 7 | Bit 6 | Bit 5 | Bit 4 | Bit 3 | Bit 2 | Bit 1 | Bit 0 |
|-------|-------|-------|-------|-------|-------|-------|-------|
| I     | T     | H     | S     | V     | N     | Z     | C     |

I=GlobalInterrupt T=BitCopy H=HalfCarry S=Sign V=Overflow N=Negative Z=Zero C=Carry

## Instruction Table

Columns: Mnemonic | 16-bit Opcode Pattern | Words | Operation | Flags | Cores

"Cores" lists which variants support the instruction. Omission means not available.
Words=2 means a second 16-bit immediate word follows the opcode word.

SREG flag column uses: Z C N V S H T I  (— = unaffected, ⇔ = computed, 0 = cleared)

### Arithmetic and Logic

| Mnemonic      | Opcode                  | Words | Operation                             | Flags       | AVRe | AVRxm | AVRxt | AVRrc |
|---------------|-------------------------|-------|---------------------------------------|-------------|------|-------|-------|-------|
| ADD Rd,Rr     | `0000 11rd dddd rrrr`   | 1     | Rd ← Rd + Rr                          | Z,C,N,V,S,H | ✓    | ✓     | ✓     | ✓     |
| ADC Rd,Rr     | `0001 11rd dddd rrrr`   | 1     | Rd ← Rd + Rr + C                      | Z,C,N,V,S,H | ✓    | ✓     | ✓     | ✓     |
| ADIW Rd,K     | `1001 0110 KKdd KKKK`   | 1     | R[d+1]:Rd ← R[d+1]:Rd + K  d∈{24,26,28,30} | Z,C,N,V,S | ✓ | ✓  | ✓     |       |
| SUB Rd,Rr     | `0001 10rd dddd rrrr`   | 1     | Rd ← Rd − Rr                          | Z,C,N,V,S,H | ✓    | ✓     | ✓     | ✓     |
| SUBI Rd,K     | `0101 KKKK dddd KKKK`   | 1     | Rd ← Rd − K  d∈{16..31}               | Z,C,N,V,S,H | ✓    | ✓     | ✓     | ✓     |
| SBC Rd,Rr     | `0000 10rd dddd rrrr`   | 1     | Rd ← Rd − Rr − C                      | Z,C,N,V,S,H | ✓    | ✓     | ✓     | ✓     |
| SBCI Rd,K     | `0100 KKKK dddd KKKK`   | 1     | Rd ← Rd − K − C  d∈{16..31}           | Z,C,N,V,S,H | ✓    | ✓     | ✓     | ✓     |
| SBIW Rd,K     | `1001 0111 KKdd KKKK`   | 1     | R[d+1]:Rd ← R[d+1]:Rd − K  d∈{24,26,28,30} | Z,C,N,V,S | ✓ | ✓  | ✓     |       |
| AND Rd,Rr     | `0010 00rd dddd rrrr`   | 1     | Rd ← Rd ∧ Rr                          | Z,N,V,S     | ✓    | ✓     | ✓     | ✓     |
| ANDI Rd,K     | `0111 KKKK dddd KKKK`   | 1     | Rd ← Rd ∧ K  d∈{16..31}               | Z,N,V,S     | ✓    | ✓     | ✓     | ✓     |
| OR Rd,Rr      | `0010 10rd dddd rrrr`   | 1     | Rd ← Rd ∨ Rr                          | Z,N,V,S     | ✓    | ✓     | ✓     | ✓     |
| ORI Rd,K      | `0110 KKKK dddd KKKK`   | 1     | Rd ← Rd ∨ K  d∈{16..31}               | Z,N,V,S     | ✓    | ✓     | ✓     | ✓     |
| EOR Rd,Rr     | `0010 01rd dddd rrrr`   | 1     | Rd ← Rd ⊕ Rr                          | Z,N,V,S     | ✓    | ✓     | ✓     | ✓     |
| COM Rd        | `1001 010d dddd 0000`   | 1     | Rd ← 0xFF − Rd                        | Z,C,N,V,S   | ✓    | ✓     | ✓     | ✓     |
| NEG Rd        | `1001 010d dddd 0001`   | 1     | Rd ← 0x00 − Rd                        | Z,C,N,V,S,H | ✓    | ✓     | ✓     | ✓     |
| INC Rd        | `1001 010d dddd 0011`   | 1     | Rd ← Rd + 1                           | Z,N,V,S     | ✓    | ✓     | ✓     | ✓     |
| DEC Rd        | `1001 010d dddd 1010`   | 1     | Rd ← Rd − 1                           | Z,N,V,S     | ✓    | ✓     | ✓     | ✓     |
| MUL Rd,Rr     | `1001 11rd dddd rrrr`   | 1     | R1:R0 ← Rd × Rr (unsigned)            | Z,C         | ✓    | ✓     | ✓     |       |
| MULS Rd,Rr    | `0000 0010 dddd rrrr`   | 1     | R1:R0 ← Rd × Rr (signed)  d,r∈{16..31} | Z,C       | ✓    | ✓     | ✓     |       |
| MULSU Rd,Rr   | `0000 0011 0ddd 0rrr`   | 1     | R1:R0 ← Rd × Rr (signed×unsigned)  d,r∈{16..23} | Z,C | ✓ | ✓  | ✓     |       |
| FMUL Rd,Rr    | `0000 0011 0ddd 1rrr`   | 1     | R1:R0 ← (Rd × Rr)<<1 (unsigned)  d,r∈{16..23} | Z,C | ✓ | ✓ | ✓     |       |
| FMULS Rd,Rr   | `0000 0011 1ddd 0rrr`   | 1     | R1:R0 ← (Rd × Rr)<<1 (signed)  d,r∈{16..23} | Z,C | ✓ | ✓ | ✓     |       |
| FMULSU Rd,Rr  | `0000 0011 1ddd 1rrr`   | 1     | R1:R0 ← (Rd × Rr)<<1 (s×u)  d,r∈{16..23} | Z,C  | ✓  | ✓     | ✓     |       |
| DES K         | `1001 0100 KKKK 1011`   | 1     | R15:R0 ← DES(R15:R0, K) enc/dec       | —           |      | ✓     |       |       |
| SBR Rd,K      | *(alias ORI)*           | —     | Rd ← Rd ∨ K                           | Z,N,V,S     | ✓    | ✓     | ✓     | ✓     |
| CBR Rd,K      | *(alias ANDI ~K)*       | —     | Rd ← Rd ∧ (0xFF − K)                  | Z,N,V,S     | ✓    | ✓     | ✓     | ✓     |
| TST Rd        | *(alias AND Rd,Rd)*     | —     | Rd ∧ Rd                               | Z,N,V,S     | ✓    | ✓     | ✓     | ✓     |
| CLR Rd        | *(alias EOR Rd,Rd)*     | —     | Rd ← 0                                | Z,N,V,S     | ✓    | ✓     | ✓     | ✓     |
| SER Rd        | *(alias LDI Rd,0xFF)*   | —     | Rd ← 0xFF  d∈{16..31}                 | —           | ✓    | ✓     | ✓     | ✓     |

### Flow Control

| Mnemonic      | Opcode                        | Words | Operation                              | Flags | AVRe | AVRxm | AVRxt | AVRrc |
|---------------|-------------------------------|-------|----------------------------------------|-------|------|-------|-------|-------|
| RJMP k        | `1100 kkkk kkkk kkkk`         | 1     | PC ← PC + k + 1  k∈{−2048..2047}      | —     | ✓    | ✓     | ✓     | ✓     |
| IJMP          | `1001 0100 0000 1001`         | 1     | PC(15:0)←Z; PC(21:16)←0               | —     | ✓    | ✓     | ✓     | ✓     |
| EIJMP         | `1001 0100 0001 1001`         | 1     | PC(15:0)←Z; PC(21:16)←EIND            | —     | ✓    | ✓     | ✓     |       |
| JMP k         | `1001 010k kkkk 110k` + k[15:0] | 2   | PC ← k  k∈{0..4194303} (22-bit word addr) | —  | ✓    | ✓     | ✓     |       |
| RCALL k       | `1101 kkkk kkkk kkkk`         | 1     | STACK←PC; PC←PC+k+1  k∈{−2048..2047}  | —     | ✓    | ✓     | ✓     | ✓     |
| ICALL         | `1001 0101 0000 1001`         | 1     | STACK←PC; PC(15:0)←Z; PC(21:16)←0     | —     | ✓    | ✓     | ✓     | ✓     |
| EICALL        | `1001 0101 0001 1001`         | 1     | STACK←PC; PC(15:0)←Z; PC(21:16)←EIND  | —     | ✓    | ✓     | ✓     |       |
| CALL k        | `1001 010k kkkk 111k` + k[15:0] | 2   | STACK←PC; PC←k  k=22-bit word addr    | —     | ✓    | ✓     | ✓     |       |
| RET           | `1001 0101 0000 1000`         | 1     | PC ← STACK                            | —     | ✓    | ✓     | ✓     | ✓     |
| RETI          | `1001 0101 0001 1000`         | 1     | PC←STACK; I←1                         | I     | ✓    | ✓     | ✓     | ✓     |
| CPSE Rd,Rr    | `0001 00rd dddd rrrr`         | 1     | if Rd==Rr: skip next instr             | —     | ✓    | ✓     | ✓     | ✓     |
| CP Rd,Rr      | `0001 01rd dddd rrrr`         | 1     | Rd − Rr (discard result)               | Z,C,N,V,S,H | ✓ | ✓ | ✓  | ✓     |
| CPC Rd,Rr     | `0000 01rd dddd rrrr`         | 1     | Rd − Rr − C (discard result)           | Z,C,N,V,S,H | ✓ | ✓ | ✓  | ✓     |
| CPI Rd,K      | `0011 KKKK dddd KKKK`         | 1     | Rd − K (discard result)  d∈{16..31}    | Z,C,N,V,S,H | ✓ | ✓ | ✓  | ✓     |
| SBRC Rr,b     | `1111 110r rrrr 0bbb`         | 1     | if Rr(b)==0: skip next instr           | —     | ✓    | ✓     | ✓     | ✓     |
| SBRS Rr,b     | `1111 111r rrrr 0bbb`         | 1     | if Rr(b)==1: skip next instr           | —     | ✓    | ✓     | ✓     | ✓     |
| SBIC A,b      | `1001 1001 aaaa abbb`         | 1     | if I/O(A,b)==0: skip next instr        | —     | ✓    | ✓     | ✓     | ✓     |
| SBIS A,b      | `1001 1011 aaaa abbb`         | 1     | if I/O(A,b)==1: skip next instr        | —     | ✓    | ✓     | ✓     | ✓     |

#### Conditional Branches

All branches: opcode `1111 0xkk kkkk ksss`, 1 word, PC←PC+k+1 if condition met, all cores.
x=0 → branch if SREG(s)==1; x=1 → branch if SREG(s)==0. k is signed 7-bit offset (−64..+63).

| Mnemonic  | s   | x | Condition    | Complement | Note                      |
|-----------|-----|---|--------------|------------|---------------------------|
| BRBS s,k  | any | 0 | SREG(s)==1   | BRBC       | generic                   |
| BRBC s,k  | any | 1 | SREG(s)==0   | BRBS       | generic                   |
| BREQ k    | 001 | 0 | Z==1         | BRNE       |                           |
| BRNE k    | 001 | 1 | Z==0         | BREQ       |                           |
| BRCS k    | 000 | 0 | C==1         | BRCC       | same encoding as BRLO     |
| BRLO k    | 000 | 0 | C==1         | BRSH       | same encoding as BRCS     |
| BRCC k    | 000 | 1 | C==0         | BRCS       | same encoding as BRSH     |
| BRSH k    | 000 | 1 | C==0         | BRLO       | same encoding as BRCC     |
| BRMI k    | 010 | 0 | N==1         | BRPL       |                           |
| BRPL k    | 010 | 1 | N==0         | BRMI       |                           |
| BRVS k    | 011 | 0 | V==1         | BRVC       |                           |
| BRVC k    | 011 | 1 | V==0         | BRVS       |                           |
| BRLT k    | 100 | 0 | S==1         | BRGE       | signed less-than          |
| BRGE k    | 100 | 1 | S==0         | BRLT       | signed greater-or-equal   |
| BRHS k    | 101 | 0 | H==1         | BRHC       |                           |
| BRHC k    | 101 | 1 | H==0         | BRHS       |                           |
| BRTS k    | 110 | 0 | T==1         | BRTC       |                           |
| BRTC k    | 110 | 1 | T==0         | BRTS       |                           |
| BRIE k    | 111 | 0 | I==1         | BRID       |                           |
| BRID k    | 111 | 1 | I==0         | BRIE       |                           |

### Data Transfer

| Mnemonic       | Opcode                         | Words | Operation                                    | AVRe | AVRxm | AVRxt | AVRrc |
|----------------|--------------------------------|-------|----------------------------------------------|------|-------|-------|-------|
| MOV Rd,Rr      | `0010 11rd dddd rrrr`          | 1     | Rd ← Rr                                      | ✓    | ✓     | ✓     | ✓     |
| MOVW Rd,Rr     | `0000 0001 dddd rrrr`          | 1     | R[d+1]:Rd ← R[r+1]:Rr  d,r∈{0,2,4..30}      | ✓    | ✓     | ✓     |       |
| LDI Rd,K       | `1110 KKKK dddd KKKK`          | 1     | Rd ← K  d∈{16..31}                           | ✓    | ✓     | ✓     | ✓     |
| LDS Rd,k       | `1001 000d dddd 0000` + k[15:0] | 2    | Rd ← DS(k)                                   | ✓    | ✓     | ✓     | —†    |
| LD Rd,X        | `1001 000d dddd 1100`          | 1     | Rd ← DS(X)                                   | ✓    | ✓     | ✓     | ✓     |
| LD Rd,X+       | `1001 000d dddd 1101`          | 1     | Rd←DS(X); X++                                | ✓    | ✓     | ✓     | ✓     |
| LD Rd,-X       | `1001 000d dddd 1110`          | 1     | X--; Rd←DS(X)                                | ✓    | ✓     | ✓     | ✓     |
| LD Rd,Y        | `1000 000d dddd 1000`          | 1     | Rd ← DS(Y)                                   | ✓    | ✓     | ✓     | ✓     |
| LD Rd,Y+       | `1001 000d dddd 1001`          | 1     | Rd←DS(Y); Y++                                | ✓    | ✓     | ✓     | ✓     |
| LD Rd,-Y       | `1001 000d dddd 1010`          | 1     | Y--; Rd←DS(Y)                                | ✓    | ✓     | ✓     | ✓     |
| LDD Rd,Y+q     | `10q0 qq0d dddd 1qqq`          | 1     | Rd ← DS(Y+q)                                 | ✓    | ✓     | ✓     |       |
| LD Rd,Z        | `1000 000d dddd 0000`          | 1     | Rd ← DS(Z)                                   | ✓    | ✓     | ✓     | ✓     |
| LD Rd,Z+       | `1001 000d dddd 0001`          | 1     | Rd←DS(Z); Z++                                | ✓    | ✓     | ✓     | ✓     |
| LD Rd,-Z       | `1001 000d dddd 0010`          | 1     | Z--; Rd←DS(Z)                                | ✓    | ✓     | ✓     | ✓     |
| LDD Rd,Z+q     | `10q0 qq0d dddd 0qqq`          | 1     | Rd ← DS(Z+q)                                 | ✓    | ✓     | ✓     |       |
| STS k,Rr       | `1001 001d dddd 0000` + k[15:0] | 2    | DS(k) ← Rr                                   | ✓    | ✓     | ✓     | —†    |
| ST X,Rr        | `1001 001r rrrr 1100`          | 1     | DS(X) ← Rr                                   | ✓    | ✓     | ✓     | ✓     |
| ST X+,Rr       | `1001 001r rrrr 1101`          | 1     | DS(X)←Rr; X++                                | ✓    | ✓     | ✓     | ✓     |
| ST -X,Rr       | `1001 001r rrrr 1110`          | 1     | X--; DS(X)←Rr                                | ✓    | ✓     | ✓     | ✓     |
| ST Y,Rr        | `1000 001r rrrr 1000`          | 1     | DS(Y) ← Rr                                   | ✓    | ✓     | ✓     | ✓     |
| ST Y+,Rr       | `1001 001r rrrr 1001`          | 1     | DS(Y)←Rr; Y++                                | ✓    | ✓     | ✓     | ✓     |
| ST -Y,Rr       | `1001 001r rrrr 1010`          | 1     | Y--; DS(Y)←Rr                                | ✓    | ✓     | ✓     | ✓     |
| STD Y+q,Rr     | `10q0 qq1r rrrr 1qqq`          | 1     | DS(Y+q) ← Rr                                 | ✓    | ✓     | ✓     |       |
| ST Z,Rr        | `1000 001r rrrr 0000`          | 1     | DS(Z) ← Rr                                   | ✓    | ✓     | ✓     | ✓     |
| ST Z+,Rr       | `1001 001r rrrr 0001`          | 1     | DS(Z)←Rr; Z++                                | ✓    | ✓     | ✓     | ✓     |
| ST -Z,Rr       | `1001 001r rrrr 0010`          | 1     | Z--; DS(Z)←Rr                                | ✓    | ✓     | ✓     | ✓     |
| STD Z+q,Rr     | `10q0 qq1r rrrr 0qqq`          | 1     | DS(Z+q) ← Rr                                 | ✓    | ✓     | ✓     |       |
| LPM            | `1001 0101 1100 1000`          | 1     | R0 ← PS(Z)                                   | ✓    | ✓     | ✓     |       |
| LPM Rd,Z       | `1001 000d dddd 0100`          | 1     | Rd ← PS(Z)                                   | ✓    | ✓     | ✓     |       |
| LPM Rd,Z+      | `1001 000d dddd 0101`          | 1     | Rd←PS(Z); Z++                                | ✓    | ✓     | ✓     |       |
| ELPM           | `1001 0101 1101 1000`          | 1     | R0 ← PS(RAMPZ:Z)                             | ✓    | ✓     | ✓     |       |
| ELPM Rd,Z      | `1001 000d dddd 0110`          | 1     | Rd ← PS(RAMPZ:Z)                             | ✓    | ✓     | ✓     |       |
| ELPM Rd,Z+     | `1001 000d dddd 0111`          | 1     | Rd←PS(RAMPZ:Z); (RAMPZ:Z)++                  | ✓    | ✓     | ✓     |       |
| SPM            | `1001 0101 1110 1000`          | 1     | PS(RAMPZ:Z) ← R1:R0                          | ✓    | ✓     | ✓     |       |
| SPM Z+         | `1001 0101 1111 1000`          | 1     | PS(RAMPZ:Z)←R1:R0; Z+=2                      |      | ✓     | ✓     |       |
| IN Rd,A        | `1011 0AAd dddd AAAA`          | 1     | Rd ← I/O(A)  A∈{0..63}                       | ✓    | ✓     | ✓     | ✓     |
| OUT A,Rr       | `1011 1AAr rrrr AAAA`          | 1     | I/O(A) ← Rr  A∈{0..63}                       | ✓    | ✓     | ✓     | ✓     |
| PUSH Rr        | `1001 001d dddd 1111`          | 1     | STACK ← Rr; SP--                             | ✓    | ✓     | ✓     | ✓     |
| POP Rd         | `1001 000d dddd 1111`          | 1     | SP++; Rd ← STACK                             | ✓    | ✓     | ✓     | ✓     |
| XCH Z,Rd       | `1001 001r rrrr 0100`          | 1     | DS(Z) ↔ Rd                                   |      | ✓     |       |       |
| LAS Z,Rd       | `1001 001r rrrr 0101`          | 1     | Rd←DS(Z); DS(Z)←Rd∨DS(Z)                     |      | ✓     |       |       |
| LAC Z,Rd       | `1001 001r rrrr 0110`          | 1     | Rd←DS(Z); DS(Z)←(~Rd)∧DS(Z)                  |      | ✓     |       |       |
| LAT Z,Rd       | `1001 001r rrrr 0111`          | 1     | Rd←DS(Z); DS(Z)←Rd⊕DS(Z)                     |      | ✓     |       |       |

† AVRrc has a different 1-word encoding for LDS/STS (7-bit address, different opcode).

### Bit and Bit-Test

| Mnemonic    | Opcode                  | Words | Operation                 | Flags   | AVRe | AVRxm | AVRxt | AVRrc |
|-------------|-------------------------|-------|---------------------------|---------|------|-------|-------|-------|
| LSR Rd      | `1001 010d dddd 0110`   | 1     | C←Rd(0); Rd>>=1; Rd(7)←0 | Z,C,N,V | ✓    | ✓     | ✓     | ✓     |
| ASR Rd      | `1001 010d dddd 0101`   | 1     | C←Rd(0); Rd>>=1 (sign extend) | Z,C,N,V | ✓ | ✓  | ✓     | ✓     |
| ROR Rd      | `1001 010d dddd 0111`   | 1     | Rotate right through C    | Z,C,N,V | ✓    | ✓     | ✓     | ✓     |
| SWAP Rd     | `1001 010d dddd 0010`   | 1     | Rd(3:0) ↔ Rd(7:4)         | —       | ✓    | ✓     | ✓     | ✓     |
| SBI A,b     | `1001 1010 aaaa abbb`   | 1     | I/O(A,b) ← 1              | —       | ✓    | ✓     | ✓     | ✓     |
| CBI A,b     | `1001 1000 aaaa abbb`   | 1     | I/O(A,b) ← 0              | —       | ✓    | ✓     | ✓     | ✓     |
| BST Rr,b    | `1111 101d dddd 0bbb`   | 1     | T ← Rr(b)                 | T       | ✓    | ✓     | ✓     | ✓     |
| BLD Rd,b    | `1111 100d dddd 0bbb`   | 1     | Rd(b) ← T                 | —       | ✓    | ✓     | ✓     | ✓     |
| BSET s      | `1001 0100 0sss 1000`   | 1     | SREG(s) ← 1               | SREG(s) | ✓    | ✓     | ✓     | ✓     |
| BCLR s      | `1001 0100 1sss 1000`   | 1     | SREG(s) ← 0               | SREG(s) | ✓    | ✓     | ✓     | ✓     |
| LSL Rd      | *(alias ADD Rd,Rd)*     | —     | C←Rd(7); Rd<<=1; Rd(0)←0 | Z,C,N,V,H | ✓  | ✓     | ✓     | ✓     |
| ROL Rd      | *(alias ADC Rd,Rd)*     | —     | Rotate left through C     | Z,C,N,V,H | ✓  | ✓     | ✓     | ✓     |
| SEC/CLC/… | *(alias BSET/BCLR s=0)* | —    | Set/clear C flag          | C       | ✓    | ✓     | ✓     | ✓     |
| SEZ/CLZ/… | *(alias BSET/BCLR s=1)* | —    | Set/clear Z flag          | Z       | ✓    | ✓     | ✓     | ✓     |
| SEN/CLN/… | *(alias BSET/BCLR s=2)* | —    | Set/clear N flag          | N       | ✓    | ✓     | ✓     | ✓     |
| SEV/CLV/… | *(alias BSET/BCLR s=3)* | —    | Set/clear V flag          | V       | ✓    | ✓     | ✓     | ✓     |
| SES/CLS/… | *(alias BSET/BCLR s=4)* | —    | Set/clear S flag          | S       | ✓    | ✓     | ✓     | ✓     |
| SEH/CLH/… | *(alias BSET/BCLR s=5)* | —    | Set/clear H flag          | H       | ✓    | ✓     | ✓     | ✓     |
| SET/CLT/… | *(alias BSET/BCLR s=6)* | —    | Set/clear T flag          | T       | ✓    | ✓     | ✓     | ✓     |
| SEI/CLI/… | *(alias BSET/BCLR s=7)* | —    | Set/clear I flag          | I       | ✓    | ✓     | ✓     | ✓     |

### MCU Control

| Mnemonic | Opcode                  | Words | Operation             | AVRe | AVRxm | AVRxt | AVRrc |
|----------|-------------------------|-------|-----------------------|------|-------|-------|-------|
| NOP      | `0000 0000 0000 0000`   | 1     | No operation          | ✓    | ✓     | ✓     | ✓     |
| SLEEP    | `1001 0101 1000 1000`   | 1     | Enter sleep mode      | ✓    | ✓     | ✓     | ✓     |
| WDR      | `1001 0101 1010 1000`   | 1     | Reset watchdog timer  | ✓    | ✓     | ✓     | ✓     |
| BREAK    | `1001 0101 1001 1000`   | 1     | Debug break           | ✓    | ✓     | ✓     | ✓     |

## Multi-Word Instructions

Only four instructions consume 2 words. The second word is always a 16-bit immediate
(data address for LDS/STS, low 16 bits of 22-bit word address for CALL/JMP).

| Instruction | First word identifies as 2-word by...                           |
|-------------|----------------------------------------------------------------|
| LDS Rd,k    | `1001 000d dddd 0000` — lower nibble `0000` with prefix `1001 000` |
| STS k,Rr    | `1001 001d dddd 0000` — same pattern, store variant            |
| JMP k       | `1001 010k kkkk 110k` — bits [3:1] = `110`                     |
| CALL k      | `1001 010k kkkk 111k` — bits [3:1] = `111`                     |

Pre-decode rule (operates on a single 16-bit word before full decode):
```
needsSecondWord w =
    (w[15:10] == 0b100100 && w[3:0] == 0b0000)   -- LDS
 || (w[15:10] == 0b100100 && w[3:0] == 0b0000)   -- STS (same prefix, bit 9 differs)
 || (w[15:9]  == 0b1001010 && w[3:1] == 0b110)   -- JMP
 || (w[15:9]  == 0b1001010 && w[3:1] == 0b111)   -- CALL
```

More precisely (distinguishing LDS from STS and JMP from CALL):
```
needsSecondWord w =
    (w .&. 0xFC0F == 0x9000)   -- LDS: 1001 000x xxxx 0000
 || (w .&. 0xFC0F == 0x9200)   -- STS: 1001 001x xxxx 0000
 || (w .&. 0xFE0E == 0x940C)   -- JMP: 1001 010x xxxx 110x
 || (w .&. 0xFE0E == 0x940E)   -- CALL:1001 010x xxxx 111x
```

## Program Counter Width

The PC holds a **word address** (not byte address). Maximum depends on device:

| Flash size | PC width    | Notes                                     |
|------------|-------------|-------------------------------------------|
| ≤ 8KB      | Unsigned 12 | AVRrc devices, rjmp/rcall only            |
| ≤ 128KB    | Unsigned 16 | Most ATmega. CALL/JMP encode 16-bit k.    |
| ≤ 8MB      | Unsigned 22 | Large ATmega, XMEGA. CALL/JMP encode 22-bit k. EIND extends indirect. |

The CALL/JMP 22-bit address field in the 32-bit encoding:
```
  word0: 1001_010k_kkkk_11xk   (bits 8,7:4,0 carry k[21:16,15])
  word1: kkkk_kkkk_kkkk_kkkk   (k[15:0])
```
On 16-bit-PC devices, k[21:16] are always zero; the 6 k-bits in word0 are ignored.
