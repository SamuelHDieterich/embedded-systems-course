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

  ldi R16, 0x04 ; x = 4
  ldi R17, 0x05 ; y = 5
  call SUM
  rjmp LOOP     ; <- return here


SUM:
     
  mov R18, R16  ; z = x (copy)
  add R18, R17  ; z = z + y
  ret           ; return


LOOP:
  
  rjmp LOOP