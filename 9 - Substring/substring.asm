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

  ldi R16, 0b00110011 ; word
  ldi R17, 0b00000110 ; key

  call SEARCH
  rjmp LOOP


SEARCH:
     
  mov R18, R16  ; word_backup = word
  ldi R19, 0x0F ; mask = 00001111
  ldi R20, 0x00 ; counter
  call _SEARCH


_SEARCH:
     
  and R18, R19  ; word_backup AND mask  - clean the word_backup with the size and position of the key
  eor R18, R17  ; word_backup XOR chave - if word_backup == key, word_backup = 00000000
  cpi R18, 0    ; word_backup == 0 ?
  breq SUCCEED

  inc R20       ; counter = counter + 1
  cpi R20, 0x05 ; checked all possibilities?
  breq FAILED

  mov R18, R16  ; word_backup = word
  ldi R21, 0x01 ; shift_counter
  call SHIFT    ; prepare the next position for the word and mask
  rjmp _SEARCH


SHIFT:

  lsl R18       ; left shift word_backup
  lsl R19       ; left shift mask
  cp R21, R20   ; SHIFT again?
  brne SHIFT
  ret


FAILED:
     
  clr R31
  rjmp LOOP


SUCCEED:

  ldi R31, 0x01
  rjmp LOOP


LOOP:
  
  rjmp LOOP