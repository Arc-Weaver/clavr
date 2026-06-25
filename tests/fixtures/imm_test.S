; imm_test.S — exercises immediate-form instructions: SUBI, ANDI, ORI, CPI + BRCC
;
; Final state: GPIO_PORT = 0x4C (76 decimal)
;
; Trace:
;   LDI  r16, 0x50    r16 = 0x50
;   SUBI r16, 0x10    r16 = 0x40  (subtract immediate)
;   ANDI r16, 0xF0    r16 = 0x40  (AND with immediate)
;   ORI  r16, 0x0C    r16 = 0x4C  (OR with immediate)
;   CPI  r16, 0x40    compare: 0x4C - 0x40 = 0x0C, no borrow → C = 0, Z = 0
;   BRCC over         C = 0 → branch taken, skip next instruction
;   LDI  r16, 0x00    SKIPPED
;   over: GPIO_PORT = r16 = 0x4C

.arch avr6
.text
.org 0

    ldi   r16, 0xFF
    sts   0x0061, r16       ; DDR = 0xFF

    ldi   r16, 0x50
    subi  r16, 0x10         ; r16 = 0x40
    andi  r16, 0xF0         ; r16 = 0x40
    ori   r16, 0x0C         ; r16 = 0x4C

    cpi   r16, 0x40         ; 0x4C >= 0x40 → C = 0
    brcc  over              ; branch if carry clear (taken)
    ldi   r16, 0x00         ; SKIPPED

over:
    sts   0x0062, r16       ; GPIO_PORT = 0x4C
halt:
    rjmp  halt
