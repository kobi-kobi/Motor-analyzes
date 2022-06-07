; YOU GIVE HALF FREQUNCEY THAN YOU WANNA WITH "F123" IN DECIMAL
; THE ENGINE TRY TO GO TO 80H WITH CHANGED SINOS PWM BY FREQUACNEY YOU GAVE
; TO STOP DOING THE CIOMPARRTOR YOU NEED TO CHANGE THE CPL IN 23 24 


#include <ADUC841.H>

UNITS		EQU			R2
TENS		EQU			R3
HUNDREDS	EQU			R4
WAVE		EQU         R5	
COUNTER_H	EQU			R6
COUNTER_L	EQU			R7
OFFSET 		EQU		    20
CSEG		AT			0000H
JMP			MAIN



CSEG		AT			000BH					; Timer 0 ISR
CALL			waves
JB		FINISH_ROUND,END_BH
RETI
END_BH:


CLR FINISH_ROUND
SETB END_SIN_WAVE_PERIOD
RETI
 
CSEG		AT		002BH		; In the program that you are writing, you will  _not_ be using the ISR.
CLR			TF2					; You must clear the interrupt flag manually -- just as TI and RI must be cleared manually.
 CPL P3.4
 SETB FLRG_TIMER2
;CALL R_S

RETI

CSEG		AT			003BH
CALL SPI_FUNC
	RETI	

;Sets the UART and Entering the values obtained into the appropriate registers
CSEG		AT			0023H
CALL UART_FUNC
RETI
CSEG		AT			0100H
MAIN:
;
SETB PADC
MOV IEIP2, #11101111B


; TIMER2 
CLR 		RCLK
CLR 		TCLK
MOV			TH2,	#0EAH			; [X*(1/11.0592E6)]=0.5mS
MOV			TL2,	#066H			; FFFF-X
MOV			RCAP2H,	#0EAH			; RCAP2H/L are the bytes from which TH2 and TL2 are reloaded
MOV			RCAP2L,	#066H
CLR			CNT2					; Have Timer2 run as a timer.
CLR			CAP2					; Enable its 16-bit autoreload mode.
SETB		TR2						; Turn on Timer2.
SETB		ET2						; Enable the Timer2 interrupt.  You will _not_ want to do this.
;######

MOV PWMCON,#13H  ; mode1 send using p2.7
MOV PWM0L, #255d
MOV PWM1L, #255d
MOV PWM1H,#255d
MOV PWM0H,#255d

;define motor side
SETB P2.4
CLR  P2.5
; define SPI 								  
ANL			CFG841,	#11111101B
SETB		SPE
SETB        SPIM
CLR			CPOL
CLR			CPHA
SETB		SPR1
SETB		SPR0
ORL			IEIP2,#00000001B 							; SPI
SETB		ES									; Enable the serial interrupt.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MOV 		DACCON,		#00D6H						
ANL			ADCCON1,	#10111111B
ORL			ADCCON1,	#10000000B
;SE
MOV			T3FD,		#020H					;Sets timer 3
ANL			T3CON,		#01111000B				;Sets the timer and the DIV value (2)
ORL			T3CON,		#10000010B
ANL			TMOD,		#11110000B				;Sets timer 0 
ORL			TMOD,		#00000010B
MOV			TH0,		#040

CLR			SM0
SETB		SM1									; Run the UART in 8-bit variable rate mode.
SETB		REN									; We want to be able to receive data.
SETB		TR0									; Turn Timer 0 on.
SETB		ET0									; Enable the Interrupts Timer 0
SETB		ES									; Enable the serial interrupt.
SETB		EA

SETB		FLRG_WAVE

MOV			DPTR,		#sin
; SE -- You defined a wave type but not the value of delta.  The next two lines cause the 
; SE -- program to work nicely upon startup/reset.
MOV			ADD_H,	#0
MOV			ADD_L,	#100
; SE
	
; SE -- It would be better to use a definition like OFFSET EQU 20 rather than having a register
; SE -- hold a constant value.
;MOV			OFFSET,			#20



USER_UPDATE:
;Updates the requested frequency to the counter register
JNB			FLRG_END_UART, ROUTINE
PUSH		ACC
PUSH		PSW
CLR			FLRG_END_UART
MOV			A,			TENS
MOV			B,			#10
MUL			AB
ADD			A,			UNITS
MOV			ADD_L,		A
MOV			A,			HUNDREDS
MOV			B,			#100
MUL			AB
ADD			A,			ADD_L
MOV			ADD_L,		A
CLR			A
ADDC		A,			B
MOV			ADD_H,		A
END_UP:
SETB		FLRG_WAVE
POP			ACC
POP			PSW
ROUTINE:

;R_S:
;*\FIRST_INSERT REQUST ANGLE
JNB FLRG_TIMER2,USER_UPDATE
CLR END_SPI
CLR FINISHED_UART_LOOP
CLR END_FIRST_SPI
CLR P0.7			;ss pin
MOV			SPIDAT,	#00000000B
JNB END_FIRST_SPI,$ 	; NOW WE HAVE THE DGIMA IN R2 SO WE CAN CALL THE FUNC
MOV			SPIDAT,	#00000000B
CLR FLRG_TIMER2
;RET
	
JNB END_SPI,$ 		; NOW WE HAVE THE DGIMA IN LSB_SAMPLE SO WE CAN CALL THE FUNC		
MOV R0,#STRING
CALL ADD_FUNC 
SETB TI
JNB FINISHED_UART_LOOP,$
	

JMP USER_UPDATE






ADD_FUNC:
PUSH ACC
PUSH PSW
MOV DPH_TEMP,DPH
MOV DPL_TEMP,DPL
MOV DPP_TEMP,DPP
MOV 	A, 	MSB_SAMPLE ;to_conv
ANL 	A, #11110000b
SWAP 	A
MOV 	DPTR,#NUMS
MOVC    A,@A+DPTR
MOV 	STRING,A

MOV 	A, 	MSB_SAMPLE
ANL		A,#00001111b
MOVC 	A,@A+DPTR
MOV		STRING+1,A

MOV 	A, 	LSB_SAMPLE ;to_conv
ANL 	A, #11110000b
SWAP 	A
MOVC 	A,@A+DPTR
MOV		STRING+2,A

MOV 	STRING+3,#13D ; finish string
MOV 	STRING+4,#10D
MOV 	STRING+5,#0D ;flag of finished string
JNB     END_SIN_WAVE_PERIOD,COUNTIUE_PRINT
CLR 	END_SIN_WAVE_PERIOD
MOV 	STRING+5,#'G' ;flag of finished string
MOV 	STRING+6,#13D ;flag of finished string
MOV 	STRING+7,#10D ;flag of finished string
MOV 	STRING+8,#0D ;flag of finished string
COUNTIUE_PRINT:



MOV DPP,DPP_TEMP
MOV DPL,DPL_TEMP
MOV DPH_TEMP,DPH

POP ACC
POP PSW
RET

CSEG		AT			0300H
NUMS:				 DB     '0123456789ABCDEF'	
;Loops for making the waves + updating the counter	
WAVES:
PUSH		ACC
PUSH		PSW
;Check if the top counter has slipped beyond 200
CJNE		COUNTER_H, #200D,	SUB_S
SETB FINISH_ROUND
CPL P2.4
CPL P2.5
MOV			COUNTER_H,	#000H
JMP			NEXT_S
SUB_S:
JC			NEXT_S		
CLR			C
MOV			A,			COUNTER_H	
SUBB		A,			#200
SETB FINISH_ROUND
CPL P2.4
CPL P2.5
MOV			COUNTER_H,	A
;Transfer values to DAC
NEXT_S:
MOV			A,			COUNTER_H
MOVC		A,			@A+DPTR
;JNZ CONTINUE

CONTINUE:
MOV			DAC1L,		A
MOV 		PWM0H,		A
MOV 		PWM0L,		A


;Counter update
MOV			A,			ADD_L
ADD			A,			COUNTER_L
MOV			COUNTER_L,	A
MOV			A,			ADD_H
ADDC		A,			COUNTER_H
MOV			COUNTER_H,	A


POP			ACC
POP			PSW
RETI





;#######################################################################
UART_FUNC:
PUSH	ACC
PUSH	PSW
JBC		TI,		TRANS_INT	
CLR			RI						;Manual reset to RI bit
JB			CHECK_F,	CHECK_HUNDREDS
MOV			A,	SBUF
CJNE 		A,#'F',END_UART_FUNC
SETB 		CHECK_F
SETB 		FLRG_HUNDREDS
SETB 		FLRG_TENS
SETB 		FLRG_UNITS
	
POP		ACC
POP		PSW
RET
CHECK_HUNDREDS:
JNB			FLRG_HUNDREDS,	CHECK_TENS
CLR			FLRG_HUNDREDS
SETB		FLRG_TENS
MOV			A,	SBUF
ANL			A,			#00001111B			;Convert from ASCCI code to binary buffer
MOV			HUNDREDS,	A
POP		ACC
POP		PSW
RET
CHECK_TENS:
JNB			FLRG_TENS,	CHECK_UNITS
CLR			FLRG_TENS
SETB		FLRG_UNITS
MOV			A,		SBUF
ANL			A,		#00001111B
MOV			TENS,	A
POP		ACC
POP		PSW
RET
CHECK_UNITS:
CLR			FLRG_UNITS
SETB		FLRG_END_UART		;Raising a flag to enter the loop of changing the wave
MOV			A,		SBUF
ANL			A,		#00001111B
MOV			UNITS,	A
CLR CHECK_F
POP		ACC
POP		PSW
RET

TRANS_INT:
MOV A,@R0
JZ END_INT
INC R0
MOV SBUF,A
POP ACC
POP PSW
RET
END_INT:
SETB FINISHED_UART_LOOP
POP ACC
POP PSW
RET
END_UART_FUNC:
POP ACC
POP PSW
RET
;#################################
SPI_FUNC:
PUSH ACC
PUSH PSW
	JB END_FIRST_SPI,SECOND_SPI
	MOV	MSB_SAMPLE,	SPIDAT	; needed to clear ISPI.
	SETB END_FIRST_SPI
	POP ACC
	POP PSW
	RET
	SECOND_SPI:
	MOV	LSB_SAMPLE,	SPIDAT	; needed to clear ISPI.
	SETB P0.7		; return SS high 
	SETB END_SPI
POP ACC
POP PSW
RET




;Table of values of the sine signal
sin:
DB       0
DB       4
DB       8
DB       12
DB       16
DB       20
DB       24
DB       28
DB       32
DB       36
DB       40
DB       44
DB       48
DB       52
DB       56
DB       60
DB       63
DB       67
DB       71
DB       75
DB       79
DB       83
DB       86
DB       90
DB       94
DB       98
DB       101
DB       105
DB       109
DB       112
DB       116
DB       119
DB       123
DB       126
DB       130
DB       133
DB       137
DB       140
DB       143
DB       147
DB       150
DB       153
DB       156
DB       159
DB       163
DB       166
DB       169
DB       172
DB       175
DB       177
DB       180
DB       183
DB       186
DB       189
DB       191
DB       194
DB       196
DB       199
DB       201
DB       204
DB       206
DB       209
DB       211
DB       213
DB       215
DB       217
DB       219
DB       222
DB       223
DB       225
DB       227
DB       229
DB       231
DB       232
DB       234
DB       236
DB       237
DB       239
DB       240
DB       241
DB       243
DB       244
DB       245
DB       246
DB       247
DB       248
DB       249
DB       250
DB       250
DB       251
DB       252
DB       252
DB       253
DB       253
DB       254
DB       254
DB       254
DB       255
DB       255
DB       255
DB       255
DB       255
DB       255
DB       255
DB       254
DB       254
DB       254
DB       253
DB       253
DB       252
DB       252
DB       251
DB       250
DB       250
DB       249
DB       248
DB       247
DB       246
DB       245
DB       244
DB       243
DB       241
DB       240
DB       239
DB       237
DB       236
DB       234
DB       232
DB       231
DB       229
DB       227
DB       225
DB       223
DB       222
DB       219
DB       217
DB       215
DB       213
DB       211
DB       209
DB       206
DB       204
DB       201
DB       199
DB       196
DB       194
DB       191
DB       189
DB       186
DB       183
DB       180
DB       177
DB       175
DB       172
DB       169
DB       166
DB       163
DB       159
DB       156
DB       153
DB       150
DB       147
DB       143
DB       140
DB       137
DB       133
DB       130
DB       126
DB       123
DB       119
DB       116
DB       112
DB       109
DB       105
DB       101
DB       98
DB       94
DB       90
DB       86
DB       83
DB       79
DB       75
DB       71
DB       67
DB       63
DB       60
DB       56
DB       52
DB       48
DB       44
DB       40
DB       36
DB       32
DB       28
DB       24
DB       20
DB       16
DB       12
DB       8
DB       4
;Allocation of flags, etc.
DSEG	AT		0030H
ADD_H:		DS	1
ADD_L:		DS	1
STRING:			     DS	    8
MSB_SAMPLE:			     DS	    8	
LSB_SAMPLE:			     DS	    8	
DPH_TEMP:     DS	    8
DPL_TEMP: DS	    8
DPP_TEMP: DS	    8
TEMP_A:		 DS	    8



	
BSEG
FLRG_UNITS:		DBIT	1
FLRG_TENS:		DBIT	1
FLRG_HUNDREDS:	DBIT	1
FLRG_WAVE:		DBIT	1
FLRG_END_UART:	DBIT	1
FLRG_S:			DBIT	1
CHECK_F:			DBIT	1
FLRG_A:			DBIT	1
FLRG_Q:			DBIT	1
FINISHED_UART: 		DBIT    1	
FINISHED_UART_LOOP: DBIT    1	
END_FIRST_SPI:			DBIT 	1
END_SPI:			DBIT	1
	FINISH_ROUND: DBIT 1
		END_SIN_WAVE_PERIOD: DBIT 1
		FLRG_TIMER2:		DBIT	1
	FIRST_SIN: DBIT 1

END