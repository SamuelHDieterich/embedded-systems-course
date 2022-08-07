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
  call MULT     ; x * 2^y
  rjmp LOOP


MULT:
  
  ; Setup for the multiplication subroutine
  mov R18, R16  ; backup x
  mov R19, R17  ; backup y
  call _MULT    ; call the inner function
  ret


_MULT:
  
  cpi R19, 0    ; backup_y == 0 ?
  brne SHIFT
  ret


SHIFT:
     
  lsr R18       ; left shift
  dec R19       ; backup_y = backup_y - 1
  rjmp _MULT



LOOP:
  
  rjmp LOOP