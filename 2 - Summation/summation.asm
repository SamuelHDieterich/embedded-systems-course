.device ATMega328p

  .org 0x0000

  rjmp INIT


INIT:

  ldi R16, 0x01 ; counter     = 1
  ldi R17, 0x00 ; result      = 0 
  ldi R18, 0x05 ; stop value  = 5


L1: 

  add R17, R16  ; result = result + counter
  inc R16       ; counter = counter + 1
  cpse R16, R18 ; counter == stop value ?
  rjmp L1       ; skip if true


LOOP:
  
  rjmp LOOP