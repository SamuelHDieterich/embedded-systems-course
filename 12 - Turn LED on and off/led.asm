.device ATMega328p


.MACRO STACK
  ldi R16, HIGH(RAMEND)
  out sph, R16
  ldi R16, LOW(RAMEND)
  out spl, R16
.ENDMACRO


.MACRO SETUP_PORT
  ldi R16, 0x20   ; 00010000 (Arduino 13 pin)
  ldi R17, 0x00   ; 
  out DDRB, R16   ; Mode of B registrer
  out PORTB, R17  ; Value of B registrer (R16 = ON | R17 = OFF)
.ENDMACRO


  .org 0x0000
  rjmp INIT


INIT:

  STACK
  SETUP_PORT
  rjmp LOOP


LOOP:
  
  rjmp LOOP
