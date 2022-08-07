.device ATMega328p

  .org 0x0000
  rjmp INIT


INIT:
  
  ;--- STACK SETUP ----
  ldi R16, HIGH(RAMEND)
  out sph, R16
  ldi R16, LOW(RAMEND)
  out spl, R16
  ;--------------------

  ldi R19, 0x0A ; N = 10
  call FIBONACCI
  rjmp LOOP


FIBONACCI:

  ldi R16, 0x01   ; x_0 = 1
  ldi R17, 0X01   ; x_1 = 1
  ldi R20, 0x01   ; x_n
  ldi R21, 0x01   ; counter = 1
  cp R19, R16     ; n < 2
  brge _FIBONACCI
  ret


_FIBONACCI: 

  ; x_n = x_(n-1) + x_(n-2)
  add R20, R16    ; x_n = x_n + x_(n-2)
  mov R16, R17    ; x_(n-2) = x_(n-1)
  mov R17, R20    ; x_(n-1) = x_n
  inc R21         ; counter = counter +1
  cp R19, R21     ; counter != N ?
  brne _FIBONACCI
  ret


LOOP:
  
  rjmp LOOP