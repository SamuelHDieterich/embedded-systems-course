; ______ _             _     ___  ___            _ _             
; | ___ \ |           | |    |  \/  |           (_) |            
; | |_/ / | __ _ _ __ | |_   | .  . | ___  _ __  _| |_ ___  _ __ 
; |  __/| |/ _` | '_ \| __|  | |\/| |/ _ \| '_ \| | __/ _ \| '__|
; | |   | | (_| | | | | |_   | |  | | (_) | | | | | || (_) | |   
; \_|   |_|\__,_|_| |_|\__   \_|  |_/\___/|_| |_|_|\__\___/|_|   


; COURSE:       Embedded Systems Projects
; PROFESSOR:    Milton Tumelero
; TEAM:         Helena, Marlon, Mirian and Samuel
; Date:         September-October, 2022



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
.DEF    mem_value0    = R18   ; First byte
.DEF    mem_value1    = R19   ; Second byte
.DEF    mem_value2    = R20   ; Third byte

; Counter from memory
.DEF    counter_mem   = R21

; Memory address (top left position) - Z
.DEF    mem_address_l = R30
.DEF    mem_address_h = R31

; Temporary register
.DEF    temp          = R22 

; Number of the sensor (0:2)
.DEF    sensor        = R23

; Selected type of plant (0:2)
.DEF    plant_type    = R24

; LEDs output result
.DEF    led_output_b  = R25   ; PORTB output
.DEF    led_output_d  = R26   ; PORTD output

; Plant conditions (changed by plant type and sensor)
.DEF    low_sensor_l  = R0
.DEF    low_sensor_h  = R1
.DEF    high_sensor_l = R2
.DEF    high_sensor_h = R3


;--------------;
;    MACROS    ;
;--------------;

;--- STACK SETUP ---
.MACRO STACK

  ldi   temp, HIGH(RAMEND)
  out   sph, temp           ; HIGH(STACK) address
  ldi   temp, LOW(RAMEND)
  out   spl, temp           ; LOW(STACK) address

.ENDMACRO


;--- PINS MODE ---
.MACRO CONFIG_PINS

  ; Arduino - D13:8 (LEDs)
  ldi   temp, 0b00111111
  out   DDRB, temp

  ; Arduino - D7:0 (LEDs[7:5] and Buttons[4:0])
  ldi   temp, 0b11100000
  out   DDRD, temp

  ; Arduino - A2:0 (Sensors)
  ldi   temp, 0b00000111
  out   DDRC, temp

.ENDMACRO


;--- BUTTONS INTERRUPT ---
.MACRO BUTTONS_INTERRUPT

  ; INT1 (Arduino D3) - ISC11 and ISC10
  ; INT0 (Arduino D2) - ISC01 and ISC00
  ; 00 - Low level
  ; 01 - Any logical change
  ; 10 - Falling edge
  ; 11 - Rising edge
  ldi   temp, (ISC11<<1) || (ISC10<<1)
  sts   EICRA, temp

  ; INT1 - Enable external INT1 interrupt request
  ; INT0 - Enable external INT0 interrupt request
  ldi   temp, (INT1<<1)
  out   EIMSK, temp

.ENDMACRO


;--- TIMER INTERRUPT ---
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

  .org  0x0000
  rjmp  INIT
  .org  0x0004
  rjmp  BUTTONS
  .org  0x001A ; timer1 vector
  rjmp  MAIN


; Setup
INIT:

  ; Execute macros
  STACK
  CONFIG_PINS
  BUTTONS_INTERRUPT
  TIMER
  DEFAULT_VALUES

  ; Enable interrupts
  sei

  rjmp  LOOP


; Do nothing loop
LOOP:

  rjmp  LOOP


BUTTONS:

  ; Backup status register value
  in    temp, SREG
  push  temp

  ; Check reset memory operation
  sbic  PORTC, 4      ; Reset buttom
  call  RESET_MEMORY  ; Clear memory

  ; Change plant type (preference: 0>1>2)
  sbic  PORTC, 2
  ldi   plant_type, 2
  sbic  PORTC, 1
  ldi   plant_type, 1
  sbic  PORTC, 0
  ldi   plant_type, 0

  ; recover status register value
  pop   temp
  out   SREG, temp

  ; Return
  reti


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

  ; REFS1:0 - Voltage reference         = 01 (Vcc=5V)
  ; ADLAR   - Left adjust result        = 0 (Right adjust)
  ; MUX3:0  - Analog channel selection  = Depend on the sensor
  ldi   temp, (0<<REFS1) || (1<<REFS0)
  add   temp, sensor                    ; Set ADC for right sensor
  sts   ADMUX, R16

  ; Turn on ADC and start conversion
  ; ADEN    - Enable              = 1 (turn on)
  ; ADSC    - Start conversion    = 1 (convert)
  ; ADATE   - Auto trigger enable = 0 (manualy)
  ; ADIF    - Interrupt flag      = 0
  ; ADIE    - Interrupt enable    = 0
  ; ADPS2:0 - Prescaler           = 101 (1:32)
  ldi   temp, (1<<ADEN) || (1<<ADSC) || (1<<ADPS2) || (0<<ADPS1) || (1<<ADPS0)
  sts   ADCSRA, temp

  ; Read value and save it on register
  lds   read_l, ADCL
  lds   read_h, ADCH

  ; Turn off ADC (power safe)
  clr   temp
  sts   ADCSRA, temp

  ; Prepare the memory address
  call  START_MEM

  ; Load previously value
  ld    mem_value1, Z
  ldd   mem_value0, Z+1
  
  ; Load counter
  ldd   counter_mem, Z+2

  ; Shift right (10 bit -> 9 bit)
  lsr   mem_value1
  ror   mem_value0

  ; Add new value to the sum
  add   mem_value0, read_l
  adc   mem_value1, read_h

  ; Increment counter
  inc   counter_mem

  ; Check counter value
  cpi   counter_mem, 120
  ; If counter value == maximum value
  ; Call NEXT_TIMESTAMP subroutine: store values to new spots and clear this stage
  breq  NEXT_TIMESTAMP
  ; Else (counter < maximum value): store values in same spot
  st    Z,   mem_value0
  std   Z+1, mem_value1
  std   Z+2, counter_mem

  ; Verify sensor number
  cpi   sensor, 2
  breq  END_MAIN  ; If sensor = 2, end the loop

  ; Increment sensor number
  inc sensor

  ; Restart MAIN with next sensor 
  rjmp  MAIN

END_MAIN:

  ; Clear sensor number
  clr   sensor

  ; Clear led_output registers
  clr   led_output_b
  clr   led_output_d

  ; Verify the condition of the plant
  ; Update the LEDs status
  call  PLANT_CONDITION

  ; Return
  reti


; Indicates the top left position of the memory table
START_MEM:

  ; Set appropriate value
  ; Sensor 0: 0x0100
  ; Sensor 1: 0x0230
  ; Sensor 2: 0x0360

  ; Check the number of the sensor
  cpi   sensor, 0
  breq  _FIRST_POSITION
  cpi   sensor, 1
  breq  _SECOND_POSITION

_THIRD_POSITION: 

  ldi   mem_address_l, 0x60
  ldi   mem_address_h, 0x03

  ; Return
  ret

_FIRST_POSITION:

  ldi   mem_address_l, 0x00
  ldi   mem_address_h, 0x01

  ; Return
  ret

_SECOND_POSITION:

  ldi   mem_address_l, 0x30
  ldi   mem_address_h, 0x02

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
  std   Z+6, mem_value1
  std   Z+7, mem_value0

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
  std   Z,   mem_value1
  std   Z+1, mem_value0

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

  ; Change anchor position
  ldi   temp, 0x10                  ; skip one row
  add   mem_address_l, temp

  ; Reset mem values and counter
  clr   mem_value0
  clr   mem_value1
  clr   mem_value2
  clr   counter_mem

  ; Helper loop 
_SUM_RECORDS:

  ; Load record and add it to mem_value[0:2]
  ld    temp, Z+
  add   mem_value0, temp
  ld    temp, Z+
  adc   mem_value1, temp
  clr   temp
  adc   mem_value2, temp

  ; Increment counter
  inc   counter_mem

  ; If counter != 144 (all records), repeat
  cpi   counter_mem, 144
  brne  _SUM_RECORDS
  
  ; Reset anchor position
  call  START_MEM

  ; Store values in memory
  std   Z+8,  mem_value2
  std   Z+9,  mem_value1
  std   Z+10, mem_value0

  ; Return
  ret


; Check plant type and its conditions 
PLANT_CONDITION:

  ; Call appropriate subroutine
  ; Change parameters value
  ; Calculation: value/2 * 120 * 144
  ; Aproximation with two most significant bytes
  cpi   plant_type, 1
  brlo  SUCCULENT
  breq  VEGETABLE
  rjmp  PINE

_END_PLANT_SELECTION:

  ; Set memory position
  call  START_MEM

  ; Load value from memory
  ldd   mem_value0, Z+5
  ldd   mem_value2, Z+8
  ldd   mem_value1, Z+9

  ; Check verification
  sbrc  mem_value0, 0
  rjmp  OK_SENSOR_RESULT

  ; Compare limits
  cp    mem_value2, low_sensor_h
  cpc   mem_value1, low_sensor_l
  brsh  _NEXT_COMPARE
  rjmp  LOW_SENSOR_RESULT

_NEXT_COMPARE:

  cp    mem_value2, high_sensor_h
  cpc   mem_value1, high_sensor_l

  ; Workaround: brlo
  in    temp, SREG
  sbrc  temp, 0   
  rjmp  OK_SENSOR_RESULT

  rjmp  HIGH_SENSOR_RESULT

_END_SENSOR_COMPARE:

  ; Increment sensor
  inc   sensor

  ; Verify sensor number
  cpi   sensor, 3
  brne  PLANT_CONDITION

  ; Update LEDs status
  out   PORTB, led_output_b
  out   PORTD, led_output_d

  ; Return
  ret


SUCCULENT:

  cpi   sensor, 1
  brlo  _SUCCULENT_LUMINOSITY
  breq  _SUCCULENT_TEMPERATURE
  rjmp  _SUCCULENT_HUMIDITY

_SUCCULENT_LUMINOSITY:

  ; Low: < 200
  ldi   mem_value0, 0x5E
  ldi   mem_value1, 0x1A
  movw  low_sensor_h:low_sensor_l, mem_value1:mem_value0
  ; High: > 600
  ldi   mem_value0, 0x1A
  ldi   mem_value1, 0x4F
  movw  high_sensor_h:high_sensor_l, mem_value1:mem_value0

  rjmp  _END_PLANT_SELECTION

_SUCCULENT_TEMPERATURE:

  ; Low: < 250
  ldi   mem_value0, 0xF6
  ldi   mem_value1, 0x20
  movw  low_sensor_h:low_sensor_l, mem_value1:mem_value0
  ; High: > 850
  ldi   mem_value0, 0x10
  ldi   mem_value1, 0x70
  movw  high_sensor_h:high_sensor_l, mem_value1:mem_value0

  rjmp  _END_PLANT_SELECTION

_SUCCULENT_HUMIDITY:

  ; Low: < 300
  ldi   mem_value0, 0x8D
  ldi   mem_value1, 0x27
  movw  low_sensor_h:low_sensor_l, mem_value1:mem_value0
  ; High: > 700
  ldi   mem_value0, 0x49
  ldi   mem_value1, 0x5C
  movw  high_sensor_h:high_sensor_l, mem_value1:mem_value0

  rjmp  _END_PLANT_SELECTION


VEGETABLE:

  cpi   sensor, 1
  brlo  _VEGETABLE_LUMINOSITY
  breq  _VEGETABLE_TEMPERATURE
  rjmp  _VEGETABLE_HUMIDITY

_VEGETABLE_LUMINOSITY:

  ; Low: < 300
  ldi   mem_value0, 0x8D
  ldi   mem_value1, 0x27
  movw  low_sensor_h:low_sensor_l, mem_value1:mem_value0
  ; High: > 850
  ldi   mem_value0, 0x10
  ldi   mem_value1, 0x70
  movw  high_sensor_h:high_sensor_l, mem_value1:mem_value0

  rjmp  _END_PLANT_SELECTION

_VEGETABLE_TEMPERATURE:

  ; Low: < 200
  ldi   mem_value0, 0x5E
  ldi   mem_value1, 0x1A
  movw  low_sensor_h:low_sensor_l, mem_value1:mem_value0
  ; High: > 750
  ldi   mem_value0, 0xE1
  ldi   mem_value1, 0x62
  movw  high_sensor_h:high_sensor_l, mem_value1:mem_value0

  rjmp  _END_PLANT_SELECTION

_VEGETABLE_HUMIDITY:

  ; Low: < 500
  ldi   mem_value0, 0xEB
  ldi   mem_value1, 0x41
  movw  low_sensor_h:low_sensor_l, mem_value1:mem_value0
  ; High: > 700
  ldi   mem_value0, 0x49
  ldi   mem_value1, 0x5C
  movw  high_sensor_h:high_sensor_l, mem_value1:mem_value0

  rjmp  _END_PLANT_SELECTION


PINE:

  cpi   sensor, 1
  brlo  _PINE_LUMINOSITY
  breq  _PINE_TEMPERATURE
  rjmp  _PINE_HUMIDITY

_PINE_LUMINOSITY:

  ; Low: < 400
  ldi   mem_value0, 0xBC
  ldi   mem_value1, 0x34
  movw  low_sensor_h:low_sensor_l, mem_value1:mem_value0
  ; High: > 950
  ldi   mem_value0, 0x3F
  ldi   mem_value1, 0x7D
  movw  high_sensor_h:high_sensor_l, mem_value1:mem_value0

  rjmp  _END_PLANT_SELECTION

_PINE_TEMPERATURE:

  ; Low: < 150
  ldi   mem_value0, 0xC7
  ldi   mem_value1, 0x13
  movw  low_sensor_h:low_sensor_l, mem_value1:mem_value0
  ; High: > 850
  ldi   mem_value0, 0x10
  ldi   mem_value1, 0x70
  movw  high_sensor_h:high_sensor_l, mem_value1:mem_value0

  rjmp  _END_PLANT_SELECTION

_PINE_HUMIDITY:

  ; Low: < 500
  ldi   mem_value0, 0xEB
  ldi   mem_value1, 0x41
  movw  low_sensor_h:low_sensor_l, mem_value1:mem_value0
  ; High: > 900
  ldi   mem_value0, 0xA7
  ldi   mem_value1, 0x76
  movw  high_sensor_h:high_sensor_l, mem_value1:mem_value0

  rjmp  _END_PLANT_SELECTION


OK_SENSOR_RESULT:

  ; Arduino D12 - PB4 - Luminosity
  ; Arduino D9  - PB1 - Temperature
  ; Arduino D6  - PD6 - Humidity

  sbrc  sensor, 1
  sbr   led_output_b, 4
  sbrc  sensor, 0
  sbr   led_output_b, 1
  sbr   led_output_d, 6  

  rjmp  _END_SENSOR_COMPARE


LOW_SENSOR_RESULT:

  ; Arduino D13 - PB5 - Luminosity
  ; Arduino D10 - PB2 - Temperature
  ; Arduino D7  - PD7 - Humidity

  sbrc  sensor, 1
  sbr   led_output_b, 5
  sbrc  sensor, 0
  sbr   led_output_b, 2
  sbr   led_output_d, 7  

  rjmp  _END_SENSOR_COMPARE


HIGH_SENSOR_RESULT:

  ; Arduino D11 - PB3 - Luminosity
  ; Arduino D8  - PB0 - Temperature
  ; Arduino D5  - PD5 - Humidity

  sbrc  sensor, 1
  sbr   led_output_b, 3
  sbrc  sensor, 0
  sbr   led_output_b, 0
  sbr   led_output_d, 5  

  rjmp  _END_SENSOR_COMPARE