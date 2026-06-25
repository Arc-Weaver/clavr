; mem_test.S — tests STS/LDS (direct SRAM access) and PUSH/POP
;
; Z-pointer indirect (LD Z / ST Z) is omitted: avrZ is a separate scalar
; register independent of the GPR file, so ldi r30/r31 does not populate
; it — ld r16, Z would read from address 0.  That pairing is not yet wired.
;
; Final state: GPIO_PORT = 0xFF (255 decimal)
;
; Instruction coverage:
;   STS / LDS     — direct store/load to SRAM (0x0200, 0x0201)
;   EOR           — combine the two loaded values (0xAA ^ 0x55 = 0xFF)
;   PUSH / POP    — stack round-trip (SP initialised to 0x09FF by reset)

.arch avr6
.text
.org 0

    ldi   r16, 0xFF
    sts   0x0061, r16       ; GPIO DDR = 0xFF

    ; Write two complementary bytes to SRAM
    ldi   r16, 0xAA
    sts   0x0200, r16       ; mem[0x0200] = 0xAA
    ldi   r16, 0x55
    sts   0x0201, r16       ; mem[0x0201] = 0x55

    ; Load them back and XOR
    lds   r16, 0x0200       ; r16 = 0xAA
    lds   r17, 0x0201       ; r17 = 0x55
    eor   r16, r17          ; r16 = 0xFF

    ; PUSH / POP round-trip via hardware stack
    push  r16               ; mem[SP=0x09FF] = 0xFF; SP → 0x09FE
    ldi   r16, 0x00         ; clobber r16
    pop   r16               ; SP → 0x09FF; r16 = mem[0x09FF] = 0xFF

    sts   0x0062, r16       ; GPIO_PORT = 0xFF
halt:
    rjmp  halt
