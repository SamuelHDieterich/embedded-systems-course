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

  ldi R16, 0x10 ; x = 10
  ldi R17, 0x02 ; y = 2
  call MULT
  rjmp LOOP


MULT:
  
  ; Setup for the multiplication subroutine
  clr R18       ; clear result
  mov R19, R17  ; backup y (counter)
  call _MULT
  ret


_MULT:
  
  cpi R19, 0    ; counter == 0 ?   
  brne _SUM
  ret


_SUM:
  
  add R18, R16  ; result = result + x
  dec R19       ; counter = counter - 1
  rjmp _MULT


LOOP:
  
  rjmp LOOP