; program.S  — GPIO toggle demo for avr_soc
;
; Memory map:
;   0x0060  GPIO_A PIN  (read-only)
;   0x0061  GPIO_A DDR  (1 = output)
;   0x0062  GPIO_A PORT (output latch)
;
; Expected behaviour: all 8 GPIO A pins configured as outputs, then PORT
; alternates between 0x55 and 0xAA indefinitely.

.arch avr6
.text
.org 0

    ldi  r16, 0xFF
    sts  0x0061, r16        ; DDR_A = 0xFF (all outputs)

loop:
    ldi  r16, 0x55
    sts  0x0062, r16        ; PORT_A = 0x55

    ldi  r16, 0xAA
    sts  0x0062, r16        ; PORT_A = 0xAA

    rjmp loop
