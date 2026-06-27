; ramp_demo.S — end-to-end test of the signed Ramp peripheral over the bus.
;
; Exercises the typed-HDL signed datapath (PLAN_TYPED_HDL #3d): the CPU writes
; the ramp's STEP and a *negative* SETPOINT over the data bus, the ramp's signed
; FSM ramps CURRENT down through zero into negative, and the CPU reads CURRENT
; back and drives it onto PORT_A so the testbench can observe it.
;
; Memory map (data bus):
;   0x0061  GPIO_A DDR    (1 = output)
;   0x0062  GPIO_A PORT   (output latch)
;   0x0070  RAMP SETPOINT (signed, RW)
;   0x0071  RAMP STEP     (signed, RW)
;   0x0072  RAMP CURRENT  (signed, RO)
;
; STEP = 2, SETPOINT = -6 (0xFA).  With the ramp ticking every cycle, CURRENT
; converges 0 -> -2 -> -4 -> -6 within a few cycles.  The CPU polls CURRENT in a
; loop and drives it onto PORT_A; once the ramp settles, PORT_A holds 0xFA (250),
; the two's-complement byte for -6 — proving the signed datapath end-to-end.
;
; Expected observation:
;   gpio_ddr  = 0xFF
;   gpio_port = 0xFA   (= -6, the signed CURRENT read back over the bus)

.arch avr6
.text
.org 0

reset_vec:
    rjmp  reset             ; word 0: RESET vector
irq0_vec:
    rjmp  isr               ; word 1: IRQ0 vector (unused)

reset:
    ldi   r16, 0xFF
    sts   0x0061, r16       ; DDR_A = 0xFF (all pins output)

    ldi   r16, 2
    sts   0x0071, r16       ; RAMP STEP = 2

    ldi   r16, 0xFA         ; -6 in two's complement
    sts   0x0070, r16       ; RAMP SETPOINT = -6

loop:
    lds   r17, 0x0072       ; r17 = RAMP CURRENT (signed, read over the bus)
    sts   0x0062, r17       ; PORT_A = CURRENT  (settles at 0xFA = -6)
    rjmp  loop

isr:
    reti
