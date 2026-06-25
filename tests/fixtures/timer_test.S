; timer_test.S — exercises Timer peripheral bus access
;
; Memory map: Timer base = 0x0050
;   0x0050  TCCR  control (bit 0 = CTC mode)
;   0x0051  TCNT  counter (read-back)
;   0x0052  OCR   output compare register
;
; Test: write OCR = 0xA5, read it back, write to GPIO.
; Also writes TCCR = 0x01 (CTC mode enable) to verify write path.
;
; Final state: GPIO_PORT = 0xA5 (165 decimal)

.arch avr6
.text
.org 0

    ldi   r16, 0xFF
    sts   0x0061, r16       ; GPIO DDR = 0xFF

    ldi   r16, 0x01
    sts   0x0050, r16       ; Timer TCCR = 0x01 (CTC mode)

    ldi   r16, 0xA5
    sts   0x0052, r16       ; Timer OCR = 0xA5

    lds   r16, 0x0052       ; r16 = OCR (should be 0xA5)

    sts   0x0062, r16       ; GPIO_PORT = 0xA5
halt:
    rjmp  halt
