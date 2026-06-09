; program.S — GPIO toggle with timer-interrupt demo for avr_soc
;
; Memory map:
;   0x0060  GPIO_A PIN  (read-only)
;   0x0061  GPIO_A DDR  (1 = output)
;   0x0062  GPIO_A PORT (output latch)
;
; Interrupt vector table (word addresses):
;   0x0000  RESET — jump to reset handler
;   0x0001  IRQ0  — jump to ISR (wired to the SoC's periodic timer)
;
; Behaviour:
;   Reset: configure all pins as outputs, set PORT_A = 0x55, enable interrupts,
;          then spin in a tight loop waiting for the next interrupt.
;   ISR:   toggle PORT_A between 0x55 and 0xAA on every timer tick.
;
; Register convention:
;   r16  — holds the current PORT_A output value (0x55 or 0xAA).
;           Preserved across interrupt boundaries because the main loop never
;           touches it after initialisation; the ISR updates it in place.
;   r17  — scratch inside the ISR (0xFF mask for XOR toggle).

.arch avr6
.text
.org 0

; ── Interrupt vector table ────────────────────────────────────────────────────
reset_vec:
    rjmp  reset             ; word 0: RESET vector
irq0_vec:
    rjmp  isr               ; word 1: IRQ0 vector (periodic timer)

; ── Reset handler ─────────────────────────────────────────────────────────────
reset:
    ldi   r16, 0xFF
    sts   0x0061, r16       ; DDR_A  = 0xFF  (all pins → output)
    ldi   r16, 0x55
    sts   0x0062, r16       ; PORT_A = 0x55  (initial drive value; r16 tracks this)
    sei                     ; SREG.I = 1     (global interrupt enable)
loop:
    rjmp  loop              ; spin — everything interesting happens in the ISR

; ── ISR: toggle PORT_A between 0x55 and 0xAA ─────────────────────────────────
isr:
    ldi   r17, 0xFF
    eor   r16, r17          ; 0x55 → 0xAA, 0xAA → 0x55
    sts   0x0062, r16       ; PORT_A = updated value
    reti                    ; restore I-bit and return
