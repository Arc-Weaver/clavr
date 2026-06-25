; alu_test.S — exercises all single-register and two-register ALU instructions
;
; Final state: r16 = 0xBA, GPIO_PORT = 0xBA (186 decimal)
;
; Step-by-step trace:
;   LDI  r16, 5          r16=0x05
;   LDI  r17, 3          r17=0x03
;   ADD  r16, r17        r16=0x08
;   SUB  r16, r17        r16=0x05
;   AND  r16, r17        r16=0x01  (0x05 & 0x03)
;   OR   r16, r17        r16=0x03  (0x01 | 0x03)
;   EOR  r16, r17        r16=0x00  (0x03 ^ 0x03)
;   INC  r16             r16=0x01
;   DEC  r16             r16=0x00
;   LDI  r16, 0x80
;   LSR  r16             r16=0x40  (logical shift right)
;   LDI  r16, 0x80
;   ASR  r16             r16=0xC0  (arithmetic: sign bit replicated)
;   LDI  r16, 0x01
;   NEG  r16             r16=0xFF  (0x00 - 0x01 = 0xFF two's complement)
;   LDI  r16, 0xAA
;   COM  r16             r16=0x55  (bitwise NOT of 0xAA)
;   LDI  r16, 0xAB
;   SWAP r16             r16=0xBA  (nibble swap)

.arch avr6
.text
.org 0

    ; Setup GPIO: all pins output
    ldi   r16, 0xFF
    sts   0x0061, r16       ; DDR = 0xFF

    ; Two-register arithmetic
    ldi   r16, 5
    ldi   r17, 3
    add   r16, r17          ; r16 = 8
    sub   r16, r17          ; r16 = 5
    and   r16, r17          ; r16 = 1
    or    r16, r17          ; r16 = 3
    eor   r16, r17          ; r16 = 0

    ; Single-register arithmetic
    inc   r16               ; r16 = 1
    dec   r16               ; r16 = 0

    ; Shifts
    ldi   r16, 0x80
    lsr   r16               ; r16 = 0x40
    ldi   r16, 0x80
    asr   r16               ; r16 = 0xC0

    ; Two's complement and bitwise NOT
    ldi   r16, 0x01
    neg   r16               ; r16 = 0xFF
    ldi   r16, 0xAA
    com   r16               ; r16 = 0x55

    ; Nibble swap
    ldi   r16, 0xAB
    swap  r16               ; r16 = 0xBA

    ; Write result to GPIO
    sts   0x0062, r16       ; GPIO_PORT = 0xBA
halt:
    rjmp  halt
