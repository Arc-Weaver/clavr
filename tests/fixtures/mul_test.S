; mul_test.S — exercises MUL (unsigned) and MULS (signed), proving the product
; is a genuine 16-bit value split across R1:R0 (not the old truncated-to-8 bug
; that wrote the same byte to both R0 and R1).
;
;   MUL  r16,r17 : 200 * 3   = 600    = 0x0258 -> R1:R0 = 0x02:0x58
;   MULS r16,r17 : (-3) * 5  = -15    = 0xFFF1 -> R1:R0 = 0xFF:0xF1
;
; Combine all four result bytes into one observable:
;   (R0_mul + R1_mul) = 0x58 + 0x02 = 0x5A
;   (R0_muls+ R1_muls)= 0xF1 + 0xFF = 0xF0   (8-bit wrap)
;   0x5A XOR 0xF0     = 0xAA
;
; Final state: GPIO_PORT = 0xAA (170), GPIO_DDR = 0xFF (255)

.arch avr6
.text
.org 0

    ; Setup GPIO: all pins output
    ldi   r16, 0xFF
    sts   0x0061, r16       ; DDR = 0xFF

    ; --- MUL (unsigned): 200 * 3 = 600 = 0x0258
    ldi   r16, 200
    ldi   r17, 3
    mul   r16, r17          ; R0 = 0x58, R1 = 0x02
    mov   r18, r0
    mov   r19, r1

    ; --- MULS (signed): (-3) * 5 = -15 = 0xFFF1
    ldi   r16, 0xFD         ; -3
    ldi   r17, 5
    muls  r16, r17          ; R0 = 0xF1, R1 = 0xFF

    ; --- combine the four product bytes into one observable
    add   r18, r19          ; 0x58 + 0x02 = 0x5A
    add   r0,  r1           ; 0xF1 + 0xFF = 0xF0
    eor   r18, r0           ; 0x5A ^ 0xF0 = 0xAA
    sts   0x0062, r18       ; GPIO_PORT = 0xAA
halt:
    rjmp  halt
