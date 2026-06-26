; program.S — alias-read demo for avr_soc
;
; Exercises the memory-mapped-register *read* path: SREG is aliased into the
; data address space at 0x005F.  We set a SREG bit through the flag mechanism
; (sec → SREG.C = 1) — which writes the architectural SREG register but leaves
; SRAM[0x5F] untouched (0x00) — then read SREG back with `lds`.  If the alias
; read works, the loaded value is the live SREG (0x01); if it were reading raw
; SRAM it would be 0x00.  The result is driven onto PORT_A so the testbench can
; observe it.
;
; Memory map:
;   0x005D  SP   (low)   — aliased 16-bit stack pointer
;   0x005F  SREG         — aliased status register
;   0x0061  GPIO_A DDR   (1 = output)
;   0x0062  GPIO_A PORT  (output latch)
;
; Expected observations:
;   gpio_ddr  = 0xFF
;   gpio_port = 0x01   (= SREG with only the carry flag set → proves alias read)

.arch avr6
.text
.org 0

; ── Interrupt vector table ────────────────────────────────────────────────────
reset_vec:
    rjmp  reset             ; word 0: RESET vector
irq0_vec:
    rjmp  isr               ; word 1: IRQ0 vector (unused here)

; ── Reset handler ─────────────────────────────────────────────────────────────
reset:
    ldi   r16, 0xFF
    sts   0x0061, r16       ; DDR_A = 0xFF  (all pins → output)

    sec                     ; SREG.C = 1   → SREG register = 0x01, SRAM[0x5F] = 0x00
    lds   r17, 0x005F       ; r17 = SREG   (alias READ of the status register)
    sts   0x0062, r17       ; PORT_A = r17 = 0x01  (only if the alias read worked)
loop:
    rjmp  loop              ; spin

; ── ISR stub (interrupts never enabled in this test) ─────────────────────────
isr:
    reti
