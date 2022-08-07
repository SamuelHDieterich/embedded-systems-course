.device ATMega328p

  .org 0x0000
  rjmp INIT


INIT:
  
  ldi R16, 0b00000100 ; x = 4
  sbrs R16, 0 ; check if bit 0 is 1
  rjmp EVEN
  rjmp ODD


EVEN:
  
  ldi R17, 2
  rjmp LOOP


ODD:

  ldi R17, 1
  rjmp LOOP


LOOP:
  
  rjmp LOOP