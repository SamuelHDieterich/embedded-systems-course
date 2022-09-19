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

; R1:0 - Load/Store inderectly from/into program memory (lpm/spm)
; R31:16 - Immediate addressing - ldi Rd, value

; Value read by the sensor
.DEF    read_l        = R16   ; LOW
.DEF    read_h        = R17   ; HIGH

; Value stored in memory
.DEF    mem_value_l   = R18   ; LOW
.DEF    mem_value_h   = R19   ; HIGH

; Counter from memory
.DEF    counter_mem   = R20

; Memory address (top left position) - Z
.DEF    mem_address_l = R30
.DEF    mem_address_h = R31

; Temporary register
.DEF    temp          = R21 



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

.org    0x0000
rjmp    INIT
.org    0x001A ; timer1 vector
rjmp    MAIN


; Setup
INIT:

  STACK
  TIMER
  rjmp  LOOP


; Do nothing loop
LOOP:

  rjmp  LOOP


; Main function - trigger by timer
MAIN:

  ; Turn on ADC for sensor
  ; Read value and save it on register
  ; TODO

  ; Prepare the memory address
  call  START_MEM

  ; Load previously value
  ld    mem_value_h, Z
  ldd   mem_value_l, Z+1
  
  ; Load counter
  ldd   counter_mem, Z+2

  ; Add new value to the sum
  ; Workaround (add overflow): shift right
  lsr   mem_value_h
  ror   mem_value_l
  add   mem_value_l, read_l
  adc   mem_value_h, read_h

  ; Increment counter
  inc   counter_mem

  ; Check counter value
  cpi   counter_mem, 120
  ; If counter value == maximum value
  ; Call NEXT_TIMESTAMP subroutine: store values to new spots and clear this stage
  breq  NEXT_TIMESTAMP
  ; Else (counter < maximum value): store values in same spot
  st    Z, mem_value_l
  std   Z+1, mem_value_h
  std   Z+2, counter_mem

  ; Set next sensor

  ; Return
  ret


; Indicates the top left position of the memory table
START_MEM:

  ; Check the number of the sensor
  ; TODO

  ; Set appropriate value
  ; Sensor 0: 0x0100
  ; Sesnor 1: 0x01A0
  ; Sesnor 2: 0x0240
  ldi   mem_address_l, 0x00
  ldi   mem_address_h, 0x01

  ; Return
  ret


NEXT_TIMESTAMP:

  ; Store the new value on the last value spot
  std   Z+6, mem_value_h
  std   Z+7, mem_value_l

  ; Check verification location
  ldi   temp, 1
  std   Z+4, temp

  ; Load next counter from memory
  ldd   counter_mem, Z+3
  ; Check maximum value before incrementing
  ; If maximum value: reset second counter, check 2nd verification
  ; TODO
  inc   counter_mem

  ; Save value into right spot
  ; Z = Z + 0x10 + (2nd_counter << 1) [overflow]

  ; If 2nd verification == 1
  ;call  AVERAGE_MEAN

  ; Set next sensor

  ; Return
  ret




