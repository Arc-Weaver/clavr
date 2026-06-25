; uart_test.S — exercises UART peripheral bus access
;
; Memory map: UART base = 0x0040
;   0x0040  UDR   TX write / RX read
;   0x0041  USR   status (bit 0 = UDRE, bit 1 = RXC)
;   0x0042  UBRR  baud rate divisor
;
; Test: write UBRR = 0x68 (104), read it back, write to GPIO.
; 0x68 = 104 decimal: at 10 MHz, gives ~96 kbaud (10e6 / 104 ≈ 96154).
;
; Final state: GPIO_PORT = 0x68 (104 decimal)

.arch avr6
.text
.org 0

    ldi   r16, 0xFF
    sts   0x0061, r16       ; GPIO DDR = 0xFF

    ldi   r16, 0x68
    sts   0x0042, r16       ; UART UBRR = 0x68

    lds   r16, 0x0042       ; r16 = UBRR (should be 0x68)

    sts   0x0062, r16       ; GPIO_PORT = 0x68
halt:
    rjmp  halt
