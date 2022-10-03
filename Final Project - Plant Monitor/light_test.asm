;--------------;
;    DEVICE    ;
;--------------;

; Arduino UNO
.device ATMega328p



;-------------------;
;    DEFINITIONS    ;
;-------------------;

; Temporary
.DEF    temp    = R16

; Read sensor
.DEF    read_l  = R17
.DEF    read_h  = R18


;--------------;
;    MACROS    ;
;--------------;

;--- STACK SETUP ---
.MACRO STACK
  
  ldi   temp, HIGH(RAMEND)
  out   sph, temp
  ldi   temp, LOW(RAMEND)
  out   spl, temp

.ENDMACRO


;--- PINS MODE ---
.MACRO CONFIG_PINS

  ; Arduino A0 - Photoresistor
  cbi   DDRC, 0

  ; Arduino D13:11 - PB5:3 - LEDs
  ldi   temp, 0b00111000
  out   DDRB, temp

.ENDMACRO


.MACRO CONFIG_ADC
  
  ; REFS1:0 - Voltage reference         = 01 (Vcc=5V)
  ; ADLAR   - Left adjust result        = 0 (Right adjust)
  ; MUX3:0  - Analog channel selection  = Depend on the sensor
  ;ldi   temp, (REFS1<<0) | (REFS0<<1)
  ldi   temp, 0b01000000
  sts   ADMUX, temp

  ; Turn on ADC and start conversion
  ; ADEN    - Enable              = 1 (turn on)
  ; ADSC    - Start conversion    = 1 (convert)
  ; ADATE   - Auto trigger enable = 1 (automatically)
  ; ADIF    - Interrupt flag      = 0
  ; ADIE    - Interrupt enable    = 0
  ; ADPS2:0 - Prescaler           = 101 (1:32)
  ;ldi   temp, (ADEN<<1) | (ADSC<<1) | (ADATE<<1) | (ADPS2<<1) | (ADPS1<<0) | (ADPS0<<1)
  ldi   temp, 0b11100101
  sts   ADCSRA, temp

  ; Free running
  clr   temp
  sts   ADCSRB, temp

.ENDMACRO



;-------------------;
;    CODE MEMORY    ;
;-------------------;

  .org  0x0000
  rjmp  INIT

INIT:
  
  STACK
  CONFIG_PINS
  CONFIG_ADC
  rjmp LOOP


LOOP:

  ; ADSC=1 - Not in conversion  -> skip LOOP
  lds   temp, ADCSRA   ; R16 <-- ADCSRA
  sbrs  temp, ADSC     ; skip if bit ADSC of R16 is set (=1)
  rjmp  LOOP

  ; Read ADC result
  lds   read_l, ADCL
  lds   read_h, ADCH

  ; If/else logic
  cpi   read_h, 0x03
  brlo  LED_BLUE
  cpi   read_l, 0x80
  brsh  LED_RED
  rjmp  LED_GREEN

  ; If/else logic
;  cpi   read_h, 0x00
;  ldi   temp,   0x59
;  cpc   read_l, temp
;  brlo  _NEXT_COMPARE
;  rjmp  LED_BLUE
;_NEXT_COMPARE:
;  cpi   read_h, 0x03
;  ldi   temp,   0xF8
;  cpc   read_l, temp
;  brlo  LED_GREEN
;  rjmp  LED_RED


  ; Return
  rjmp LOOP


LED_BLUE:
  
  ldi   temp, 0b00100000
  out   PORTB, temp
  rjmp  LOOP


LED_GREEN:
  
  ldi   temp, 0b00010000
  out   PORTB, temp
  rjmp  LOOP


LED_RED:
  
  ldi   temp, 0b00001000
  out   PORTB, temp
  rjmp  LOOP