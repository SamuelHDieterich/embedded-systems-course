; ______ _             _     ___  ___            _ _             
; | ___ \ |           | |    |  \/  |           (_) |            
; | |_/ / | __ _ _ __ | |_   | .  . | ___  _ __  _| |_ ___  _ __ 
; |  __/| |/ _` | '_ \| __|  | |\/| |/ _ \| '_ \| | __/ _ \| '__|
; | |   | | (_| | | | | |_   | |  | | (_) | | | | | || (_) | |   
; \_|   |_|\__,_|_| |_|\__   \_|  |_/\___/|_| |_|_|\__\___/|_|   


; COURSE:       Embedded Systems Projects
; PROFESSOR:    Milton Tumelero
; TEAM:         Helena, Marlon, Mirian and Samuel
; Date:         Setember, 2022



;--------------;
;    DEVICE    ;
;--------------;

; Arduino UNO
.device ATMega328p



;-------------------;
;    DEFINITIONS    ;
;-------------------;




;--------------;
;    MACROS    ;
;--------------;

;--- SETUP THE STACK ---
.MACRO STACK

  ldi   R16, HIGH(RAMEND)
  out   sph, R16          ; HIGH(STACK) address
  ldi   R16, LOW(RAMEND)
  out   spl, R16          ; LOW(STACK) address

.ENDMACRO


;--- INTERRUPT TIMER ---
; Trigger every 5 seconds
.MACRO TIMER

  ; Initialize counter
  clr   R16
  sts   TCNT1L, R16 ; LOW(TCNT1) - 16 bits counter
  sts   TCNT1H, R16 ; HIGH(TCNT1) - 16 bits counter
  
  ; Set prescaler to 1:1024
  ; 00000100 OR 00000001 = 00000101
  ; Waveform generation mode to CTC
  ; 00000101 OR 00001000 = 00001101
  ldi   R16, (1<<CS02) || (1<<CS00) || (1<<WGM12)
  sts   TCCR1B, R16
  
  ; Interrupt by overflow
  ldi   R16, (1<<TOIE1)
  sts   TIMSK1, R16
  
  ; Value to be compared - 39062 = 0x9896
  ldi   R16, 0x96
  sts   OCR1AL, R16 ; LOW(OCR1A)
  ldi   R16, 0X98
  sts   OCR1AH, R16 ; HIGH(OCR1A)

.ENDMACRO



;-------------------;
;    CODE MEMORY    ;
;-------------------;

.org 0x0000
rjmp INIT
.org 0x001A ; timer1 vector
rjmp MAIN


INIT:

  STACK
  TIMER
