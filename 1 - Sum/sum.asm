.device ATMega328p

  .org 0x0000

  rjmp INIT


INIT:

  ldi R16, 0x04 ; x = 4
  ldi R17, 0x07 ; y = 7
  add R16, R17  ; x = x + y = 11 = 0xA0


LOOP:   
  
  rjmp LOOP