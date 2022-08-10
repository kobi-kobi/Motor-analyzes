
USING 0             
POSITIVE 		  EQU P2.5 
COMPLEMENT 		  EQU P2.4 
	 
#include <ADUC841.H>

UNITS				EQU			R2
TENS				EQU			R3
HUNDREDS			EQU			R4
WAVE				EQU         R5	
COUNTER_H			EQU			R6
COUNTER_L			EQU			R7
;OFFSET 			EQU		    20        

CSEG			AT					0000H
MOV				    SP, #0CH
JMP					MAIN



CSEG			AT					000BH					; Timer 0 ISR
CALL			 	waves
JB					FINISH_ROUND,END_BH
RETI
END_BH: 
CLR 				FINISH_ROUND ;G
SETB			    END_SIN_WAVE_PERIOD
RETI


 
CSEG			AT					002BH	
CLR					TF2													
SETB 				FLRG_TIMER2
RETI							

CSEG			AT					003BH
CALL				 SPI_FUNC
RETI	

CSEG			AT					0023H
CALL UART_FUNC				
RETI



;###################MAIN##########################################
CSEG			AT					0100H
MAIN:
;
SETB 		PADC					
MOV 		IEIP2, #11101111B		


; TIMER2 
CLR 			RCLK
CLR 			TCLK
MOV				TH2,	#0A9H			; [X*(1/11.0592E6)]=0.5mS
MOV				TL2,	#09AH			; FFFF-X
MOV				RCAP2H,	#00H			; RCAP2H/L are the bytes from which TH2 and TL2 are reloaded
MOV				RCAP2L,	#00H
CLR				CNT2					; Have Timer2 run as a timer.
CLR				CAP2					; Enable its 16-bit autoreload mode.
SETB			TR2						; Turn on Timer2.
SETB			ET2						; Enable the Timer2 interrupt.  You will _not_ want to do this.
;PWM

MOV 			PWMCON,#013H  ; mode1 send using p2.7
MOV 			PWM0L, #255d
MOV 			PWM1L, #255d
MOV 			PWM1H, #255d
MOV 			PWM0H, #255d

;
SETB			P2.4
CLR  			P2.5
;SPI 								  
ANL				CFG841,	#10111101B
SETB			SPE
SETB       	   SPIM
CLR				CPOL
CLR				CPHA
SETB			SPR1
SETB			SPR0
ORL				IEIP2,#00000001B 							; SPI
SETB			ES									; Enable the serial interrupt.
 ;DAC
MOV 			DACCON,		#00D6H						
ANL				ADCCON1,	#10111111B
ORL				ADCCON1,	#10000000B
; UART TIMER
MOV				T3FD,		#08H					;Sets timer 3
ANL				T3CON,		#01111000B				;Sets the timer and the DIV value (2)
ORL				T3CON,		#10000100B
ANL				TMOD,		#11110000B				;Sets timer 0 
ORL				TMOD,		#00000010B
MOV				TH0,		#040
; UART
CLR				SM0
SETB			SM1									; Run the UART in 8-bit variable rate mode.
SETB			REN									; We want to be able to receive data.
SETB			TR0									; Turn Timer 0 on.
SETB			ET0									; Enable the Interrupts Timer 0
SETB			ES									; Enable the serial interrupt.
SETB			EA
;
SETB			FLRG_WAVE    
MOV				DPTR,		#sin        
;
MOV				ADD_H,	#0         
MOV				ADD_L,	#100
;
CLR			    END_SPI
CLR			    END_FIRST_SPI
CLR			    FINISHED_UART_LOOP
;





USER_UPDATE:
JNB FLRG_END_UART, ROUTINE
PUSH ACC
PUSH PSW

CLR						FLRG_END_UART
MOV						A,			TENS
MOV						B,			#10
MUL						AB
ADD						A,			UNITS
MOV						ADD_L,		A
MOV						A,			HUNDREDS
MOV						B,			#100
MUL						AB
ADD						A,			ADD_L
MOV						ADD_L,		A
CLR						A
ADDC					A,			B
MOV						ADD_H,		A        

END_UP:							
SETB FLRG_WAVE			
POP  PSW
POP  ACC

ROUTINE:


;*\FIRST_INSERT REQUST ANGLE  -  MSB
JNB 					FLRG_TIMER2,USER_UPDATE
CLR					    FLRG_TIMER2

CPL 					P3.4
CLR 		     		P3.7			;ss pin
MOV			 	 		SPIDAT,	#00000000B
JNB						END_FIRST_SPI,$ 	; NOW WE HAVE THE DGIMA IN R2 SO WE CAN CALL THE FUNC
MOV						SPIDAT,		#00000000B ; LSB


	
JNB					  END_SPI,$ 
CLR					  END_FIRST_SPI	
CLR 				  END_SPI

MOV 		         R0,		#STRING
CALL				 ADD_FUNC 		
SETB				 TI				

JNB 			    FINISHED_UART_LOOP,$
CLR 			   	FINISHED_UART_LOOP	

JMP			 		USER_UPDATE






ADD_FUNC:
PUSH ACC
PUSH PSW
MOV DPH_TEMP,DPH   
MOV DPL_TEMP,DPL
MOV DPP_TEMP,DPP

MOV 		A, 		    MSB_SAMPLE 						;to_conv
ANL 		A,		    #11110000b
SWAP 		A
MOV 		DPTR,		#NUMS
MOVC    	A,			@A+DPTR
MOV 		STRING,		A

MOV 		A,		     MSB_SAMPLE
ANL			A,		     #00001111b
MOVC 		A,		     @A+DPTR
MOV			STRING+1,	 A

MOV 		A, 	    	 LSB_SAMPLE						 ;to_conv
ANL 		A,		     #11110000b
SWAP 		A
MOVC		A,			 @A+DPTR
MOV			STRING+2,    A

MOV 		STRING+3,	 #13D 							; finish string
MOV 		STRING+4,	 #10D
MOV			STRING+5,	 #0D							 ;flag of finished string       




MOV DPP,DPP_TEMP 
MOV DPL,DPL_TEMP 
MOV DPH_TEMP,DPH 
POP PSW
POP ACC
RET


CSEG		 AT			0300H
NUMS:		 DB     '0123456789ABCDEF'	

;Loops for making the waves + updating the counter	
WAVES:
PUSH  ACC
PUSH  PSW

;Check if the top counter has slipped beyond 200
CJNE			COUNTER_H,		#200D,		SUB_S 
SETB 			FINISH_ROUND
MOV				COUNTER_H,		#000H
JMP				NEXT_S
SUB_S:
JC				NEXT_S		
CLR				C
MOV				A,		COUNTER_H	
SUBB			A,		#200
SETB 			FINISH_ROUND

MOV				COUNTER_H,		A

NEXT_S:
MOV				A,			COUNTER_H
MOV				DPTR,		#SIN
MOVC			A,			@A+DPTR
MOV				DPTR,		#NUMS

CONTINUE:
MOV		   		DAC1L,		A
MOV				TARGET,		A
MOV 		 	CURRENT_MEASUREMENT, MSB_SAMPLE
CALL		 	MULsubbOfAngle
										;MOV		DAC1L,		RESULT
MOV 			PWM0H,		RESULT
MOV		 		PWM0L,		#0D


;Counter update
MOV				A,			ADD_L
ADD				A,			COUNTER_L
MOV				COUNTER_L,	A
MOV				A,			ADD_H
ADDC			A,			COUNTER_H
MOV				COUNTER_H,	A


POP	ACC
POP	PSW
RETI





;############################UART_FUNC###########################################
UART_FUNC:
PUSH ACC
PUSH PSW
JBC			TI,		TRANS_INT	
	
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

POP	PSW
POP	ACC
RET
CHECK_TENS:
JNB			FLRG_TENS,	CHECK_UNITS
CLR			FLRG_TENS
SETB		FLRG_UNITS
MOV			A,		SBUF
ANL			A,		#00001111B
MOV			TENS,	A
POP	ACC
POP	PSW
RET
CHECK_UNITS:
CLR			FLRG_UNITS
SETB		FLRG_END_UART		;Raising a flag to enter the loop of changing the wave
MOV			A,		SBUF
ANL			A,		#00001111B
MOV			UNITS,	A
CLR 		CHECK_F
POP	ACC
POP	PSW
RET


TRANS_INT:
MOV A,@R0
JZ END_INT

INC R0
MOV SBUF,A
POP PSW
POP ACC
RET

END_INT:
SETB FINISHED_UART_LOOP
POP PSW
POP ACC
RET

END_UART_FUNC:
POP PSW
POP ACC
RET

;################SPI_FUNC#################
SPI_FUNC:
PUSH ACC
PUSH PSW
	JB END_FIRST_SPI,SECOND_SPI
	MOV	MSB_SAMPLE,	SPIDAT	; needed to clear ISPI.
	;CJNE MSB_SAMPLE,#0FH
	SETB END_FIRST_SPI
	
	POP PSW
	POP ACC
	RET
	SECOND_SPI:
	MOV	LSB_SAMPLE,	SPIDAT	; needed to clear ISPI.
	SETB P3.7		; return SS high 
	SETB END_SPI
POP PSW
POP ACC
RET
;##############END#############SPI_FUNC####################

;################MULsubbOfAngle############################
MULsubbOfAngle:
PUSH ACC
PUSH PSW
;PUSH AR1
;PUSH AR3
USING 1
SETB	RS0
CLR		RS1
;DESIERD = A   ## TARGET
;MESSURMENT CURRENT IS R1
MOV A ,TARGET
MOV R1,CURRENT_MEASUREMENT
CLR C
SUBB A,R1

;CPL P3.4
JNB ACC.7,SetPositive
CLR  POSITIVE
SETB COMPLEMENT

MOV R3, A
CLR A
CLR	C
SUBB A, R3

JMP EndOfsubbOfAngle

SetPositive:
SETB POSITIVE
CLR  COMPLEMENT

EndOfsubbOfAngle:


;MOV A, RESULT
;MOV B,#255D                   ; THE K OF MUL PID
;MUL AB
ADD A,ACC
JNC NO_SATURATION
MOV RESULT,#255
JMP	ENDMULSTAGE

NO_SATURATION:
MOV RESULT,A


ENDMULSTAGE:
CLR		RS0
USING 0
POP PSW
POP ACC
RET
;###############END#########MULsubbOfAngle##########################




;Table of values of the sine signal
sin:
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	64
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128
DB	128





;Allocation of flags, etc.
DSEG				AT		0030H
ADD_H:						DS		1
ADD_L:						DS		1
MSB_SAMPLE:			        DS	    1
LSB_SAMPLE:			        DS	    1	
DPH_TEMP:   			    DS	    1
DPL_TEMP: 					DS	    1
DPP_TEMP: 					DS	    1
TEMP_A:		 				DS	    1
CURRENT_MEASUREMENT:	    DS	 	1
TARGET:					    DS 		1
RESULT:					    DS 		1
STRING:			    	    DS	    8


	
BSEG 
FLRG_UNITS:		  		    DBIT	1
FLRG_TENS:		 		    DBIT	1
FLRG_HUNDREDS:			    DBIT	1
FLRG_WAVE:				    DBIT	1
FLRG_END_UART:				DBIT	1
FLRG_S:		    			DBIT	1
CHECK_F:	    			DBIT	1
FLRG_A:		    			DBIT	1
FLRG_Q:			 		    DBIT	1
FINISHED_UART: 				DBIT    1	
FINISHED_UART_LOOP: 		DBIT    1	
END_FIRST_SPI:				DBIT 	1
END_SPI:					DBIT	1
FINISH_ROUND:        		DBIT 	1
END_SIN_WAVE_PERIOD:	 	DBIT 	1
FLRG_TIMER2:		 		DBIT	1
FIRST_SIN:		     		DBIT    1

END
