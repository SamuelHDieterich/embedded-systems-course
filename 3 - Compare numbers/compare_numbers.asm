.device ATMega328p

  .org 0x0000

  rjmp INIT


INIT:

  ldi R16, 0x03     ; x = 3
  ldi R17, 0x03     ; y = 3
  ldi R18, 0x08     ; z = 8
  add R16, R17      ; x = x + y
  cp R16, R18       ; x ? z
  brsh GREATER_THAN ; if x > z
  rjmp LESS_THAN    ; else


GREATER_THAN:  
  
  nop 
  rjmp LOOP


MENOLESS_THANR:

  nop
  rjmp LOOP


LOOP:
  
  rjmp LOOP