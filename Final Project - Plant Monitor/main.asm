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

; R1:0 - Load/Store indirectly from/into program memory (lpm/spm)
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

; Number of the sensor (0:2)
.DEF    sensor        = R22

; Selected type of plant (0:2)
.DEF    plant_type    = R23


;--------------;
;    MACROS    ;
;--------------;

;--- SETUP THE STACK ---
.MACRO STACK

  ldi   temp, HIGH(RAMEND)
  out   sph, temp           ; HIGH(STACK) address
  ldi   temp, LOW(RAMEND)
  out   spl, temp           ; LOW(STACK) address

.ENDMACRO


;--- INTERRUPT TIMER ---
; Trigger every 5 seconds
.MACRO TIMER

  ; Initialize counter
  clr   temp
  sts   TCNT1L, temp  ; LOW(TCNT1) - 16 bits counter
  sts   TCNT1H, temp  ; HIGH(TCNT1) - 16 bits counter
  
  ; Set prescaler to 1:1024
  ; 00000100 OR 00000001 = 00000101
  ; Waveform generation mode to CTC
  ; 00000101 OR 00001000 = 00001101
  ldi   temp, (1<<CS02) || (1<<CS00) || (1<<WGM12)
  sts   TCCR1B, temp
  
  ; Interrupt by overflow
  ldi   temp, (1<<TOIE1)
  sts   TIMSK1, temp
  
  ; Value to be compared - 39062 = 0x9896
  ldi   temp, 0x96
  sts   OCR1AL, temp ; LOW(OCR1A)
  ldi   temp, 0X98
  sts   OCR1AH, temp ; HIGH(OCR1A)

.ENDMACRO


;--- SET THE DEFAULT VALUES ---
.MACRO DEFAULT_VALUES

  ldi   sensor, 0
  ldi   plant_type, 0

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

  ; Execute macros
  STACK
  TIMER
  DEFAULT_VALUES

  rjmp  LOOP


; Do nothing loop
LOOP:

  rjmp  LOOP


; MEMORY SCHEMA
; -------------

;        | +00 | +01 | +02 | +03 | +04 | +05 | +06 | +07 | +08 | +09 | +0A | ...
;--------|-----------|-----|-----|-----|-----|-----------|-----------------|-----
; ANCHOR |     A     |  B  |  C  |  D  |  E  |     F     |        G        |...
;--------|-----------|-----------|-----------|-----------|-----------|-----------
;   +10  |     H ...
;--------|     ...

; (A) - Added values (5s x 120[max])
; (B) - Counter (max = 120) - 10 minutes
; (C) - Counter (max = 144) - 1 day
; (D) - Verification - 10 minutes
; (E) - Verification - 1 day
; (F) - Last value - 10 minutes (2 bytes)
; (G) - Last value - 1 day (3 bytes)
; (H) - Last records - 10 minutes (2 bytes x 144)

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

  ; Shift right (10 bit -> 9 bit)
  lsr   mem_value_h
  ror   mem_value_l

  ; Add new value to the sum
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
  st    Z,   mem_value_l
  std   Z+1, mem_value_h
  std   Z+2, counter_mem

  ; Verify sensor number
  cpi sensor, 2
  breq  END_MAIN  ; If sensor = 2, end the loop

  ; Increment sensor number
  inc sensor

  ; Restart MAIN with next sensor 
  rjmp  MAIN

END_MAIN:

  ; Clear sensor number
  clr   sensor

  ; Return
  reti


; Indicates the top left position of the memory table
START_MEM:

  ; Set appropriate value
  ; Sensor 0: 0x0100
  ; Sensor 1: 0x01A0
  ; Sensor 2: 0x0240

  ; Check the number of the sensor
  cpi   sensor, 0
  breq  _FIRST_POSITION
  cpi   sensor, 1
  breq  _SECOND_POSITION

_THIRD_POSITION: 

  ldi   mem_address_l, 0x40
  ldi   mem_address_h, 0x02

  ; Return
  ret

_FIRST_POSITION:

  ldi   mem_address_l, 0x00
  ldi   mem_address_h, 0x01

  ; Return
  ret

_SECOND_POSITION:

  ldi   mem_address_l, 0xA0
  ldi   mem_address_h, 0x01

  ; Return
  ret


;--- CLEAN/RESET THE MEMORY ---
; With this function, all the history of
; the plant will be deleted.
RESET_MEMORY:

  ; Start from the beginning of the memory address
  ldi   mem_address_l, 0x00
  ldi   mem_address_h, 0x01

  ; Helper subroutine
_CLEAN_MEM:

  ; Clear temp
  clr   temp

  ; Store clean value
  st    Z+, temp

  ; Check end of the memory (0x02E0)
  cpi   mem_address_l, 0xE0
  ldi   temp, 0x02
  cpc   mem_address_h, temp ; Compare with carry

  ; SREG[1] = Zero flag
  ; Zero flag is set, numbers are equal
  brbc  1, _CLEAN_MEM   ; If not equal, repeat the process

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

  ; Change anchor position
  ldi   temp, 0x10                  ; skip one row
  add   mem_address_l, temp
  clr   temp                        ; clear temp
  lsl   counter_mem                 ; counter x2 (can overflow)
  adc   mem_address_h, temp         ; add just the carry from previous operation
  add   mem_address_l, counter_mem  ; add counter x2
  adc   mem_address_h, temp         ; add carry from possible overflow

  ; Save new record
  std   Z,   mem_value_h
  std   Z+1, mem_value_l

  ; Reset memory position
  call START_MEM

  ; Load counter again and increment it
  ldd   counter_mem, Z+3
  inc   counter_mem

  ; Check counter value
  cpi   counter_mem, 144
  brne  _NO_NEW_CYCLE

_NEW_CYCLE:

  ; Verification - 1 day = 1 (true)
  ldi   temp, 1
  std   Z+5, temp

  ; Clear counter - 1 day
  clr   temp
  std   Z+3, temp

_NO_NEW_CYCLE: ; Just skip the _NEW_CYCLE part

  ; Load verification - 1 day
  ldd   temp, Z+5
  
  ; Check if it is true
  sbrc  temp, 0
  call  CALC_AVERAGE

    ; Verify sensor number
  cpi sensor, 2
  breq  END_MAIN  ; If sensor = 2, end the loop

  ; Increment sensor number
  inc sensor

  ; Restart MAIN with next sensor 
  rjmp  MAIN


CALC_AVERAGE:

  ; Return
  ret