.device ATMega328p


.DEF MAX      = R16
.DEF COUNTER  = R17
.DEF SIZE     = R18


.MACRO STACK
  ldi R16, HIGH(RAMEND)
  out sph, R16
  ldi R16, LOW(RAMEND)
  out spl, R16
.ENDMACRO


  .org 0x0000
  rjmp INIT


INIT:
  
  STACK
  ldi R30, LOW(ARRAY << 1)  ; LOW(Z) address
  ldi R31, HIGH(ARRAY << 1) ; HIGH(Z) address
  ldi SIZE, 5               ; size of ARRAY
  call SEARCH
  rjmp LOOP


SEARCH:

  clr COUNTER
  clr MAX
  call _SEARCH
  ret


_SEARCH:

  cp COUNTER, SIZE
  breq _RET
  inc COUNTER
  lpm R1, Z+  ; get ARRAY element value (R1 is necessary)
  cp R1, MAX  ; ARRAY element > MAX ?
  brsh CHANGE_MAX
  rjmp _SEARCH


_RET:
  
  ret


CHANGE_MAX:

  mov MAX, R1
  rjmp _SEARCH


LOOP:
  
  rjmp LOOP


ARRAY: .dB 0x00, 0x10, 0x04, 0x02, 0x03