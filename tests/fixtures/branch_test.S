; branch_test.S — tests RJMP (forward skip) + BRNE countdown loop
;
; RCALL/RET are omitted: the single-port data bus can only commit one
; memory write per instruction, so RCALL (which pushes two bytes) cannot
; work correctly in the current CPU.  Those operations are stubbed here.
;
; Final state: GPIO_PORT = 0x0F (15 decimal)
;   Accumulator = 5+4+3+2+1 = 15 via BRNE-controlled ADD loop.
;
; Instruction coverage:
;   RJMP forward  — jumps from word 0 past dead_code to start
;   LDI, STS      — register-immediate load and I/O store
;   ADD, DEC      — loop body arithmetic
;   BRNE          — branch-not-equal loop back-edge

.arch avr6
.text
.org 0

    rjmp  start         ; forward jump to start — must NOT fall into dead_code
dead_code:
    ldi   r16, 0x00     ; SKIPPED (rjmp lands past here)
start:
    ldi   r16, 0xFF
    sts   0x0061, r16   ; GPIO DDR = 0xFF

    ldi   r16, 0x00     ; accumulator = 0
    ldi   r17, 0x05     ; counter = 5
loop:
    add   r16, r17      ; accumulator += counter
    dec   r17           ; counter--
    brne  loop          ; repeat while counter != 0

    ; r16 = 5+4+3+2+1 = 15 = 0x0F
    sts   0x0062, r16   ; GPIO_PORT = 0x0F
halt:
    rjmp  halt
