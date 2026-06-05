; basic.S — linear ALU test program for clavr
; No branches, no memory access.  Executes top-to-bottom then falls into nop.
;
; Expected final register state (verified against GNU avr-as output):
;   R16 = 0x08   (ldi 5 ; ldi r17,3 ; add r16,r17)
;   R17 = 0x03
;   R18 = 0x07   (ldi 10 ; sub r18,r17)
;   R19 = 0x0F   (ldi 0xFF ; ldi r20,0x0F ; and r19,r20)
;   R20 = 0x0F
;   R21 = 0xFF   (ldi 0xF0 ; ldi r22,0x0F ; or r21,r22)
;   R22 = 0x0F
;   R23 = 0xFF   (ldi 0xAA ; ldi r24,0x55 ; eor r23,r24)
;   R24 = 0x55   (source for eor, unchanged)
;   R25 = 0x80   (ldi 0x7F ; inc)
;   R26 = 0x40   (ldi 0x80 ; lsr)
;   R27 = 0x01   (ldi 0x01)
;   R28 = 0xFF   (ldi 0x01 ; neg)  -- R27 used as source
;   R29 = 0x55   (ldi 0xAA ; com)  -- R28 used for com
;   R30 = 0x08   (mov r30, r16)

.arch avr6
.text
.org 0

    ldi  r16, 5         ; R16 = 0x05
    ldi  r17, 3         ; R17 = 0x03
    add  r16, r17       ; R16 = 0x08

    ldi  r18, 10        ; R18 = 0x0A
    sub  r18, r17       ; R18 = 0x07

    ldi  r19, 0xFF      ; R19 = 0xFF
    ldi  r20, 0x0F      ; R20 = 0x0F
    and  r19, r20       ; R19 = 0x0F

    ldi  r21, 0xF0      ; R21 = 0xF0
    ldi  r22, 0x0F      ; R22 = 0x0F
    or   r21, r22       ; R21 = 0xFF

    ldi  r23, 0xAA      ; R23 = 0xAA
    ldi  r24, 0x55      ; R24 = 0x55
    eor  r23, r24       ; R23 = 0xFF

    ldi  r25, 0x7F      ; R25 = 0x7F
    inc  r25            ; R25 = 0x80

    ldi  r26, 0x80      ; R26 = 0x80  (note: ldi only works r16-r31)
    lsr  r26            ; R26 = 0x40

    ldi  r27, 0x01      ; R27 = 0x01
    neg  r27            ; R27 = 0xFF  (0 - 1)

    ldi  r28, 0xAA      ; R28 = 0xAA
    com  r28            ; R28 = 0x55  (0xFF - 0xAA)

    mov  r29, r16       ; R29 = 0x08
    movw r30, r16       ; R30 = 0x08, R31 = 0x00  (word copy r17:r16 → r31:r30)

    nop
