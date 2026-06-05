; jump_test.S — tests unconditional jump and conditional branch loop
;
; Expected final state:
;   R16 = 0x00   (loop counter decremented to zero)
;   R17 = 0x0F   (sum 5+4+3+2+1 = 15)
;   R18 = 0xFF   (ldi before rjmp; the skipped ldi 0x00 was not executed)

.arch avr6
.text
.org 0

    ldi  r16, 5         ; counter = 5
    ldi  r17, 0         ; sum = 0
    ldi  r18, 0xFF      ; sentinel: must survive the skip
    rjmp loop           ; skip the next instruction
    ldi  r18, 0x00      ; SKIPPED — rjmp jumps over this
loop:
    add  r17, r16       ; sum += counter
    dec  r16            ; counter--
    brne loop           ; if counter != 0, repeat
    nop                 ; stop here
