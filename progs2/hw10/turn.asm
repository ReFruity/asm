;Laboratory Exercise 
;You are to write a program in 8088 assembly language to turn on the PC speaker at 256 Hz for 5 seconds. 
;­##############################################; 
; Author : Chi Keung Tang ; 
; Program : turning on the PC speaker ; 
; at some frequency ; 
; for specific duration ; 
; ##############################################; 
Port		= 61h ; I/O ports 
Timer2		= 42h ; Timer2 
TimerMode	= 43h 
on		= 00000011b ; bit 0 and 1 turn on speaker 
Period		= 4660 ; Period 
OneSec		= 768		; change accroding to CPU speed
Term		= 4c00h 
DosInt		= 21h 

SSeg	segment stack 
	db 256 dup (?) 
SSeg	ends 
DSeg	segment 

hour1 db ' ', '$'
hour2 db ' :', '$'
minute1 db ' ', '$'
minute2 db ' :', '$'
second1 DB ' ', '$'
second2 DB ' ', 0ah, 0dh, '$'
aa db 16
bb dw 3030h

sec	dw ? 
nsec	dw 25000 ; By experiment, 500* (50 * 32768) iterations 
				; make a 5-second delay 
DSeg	ends 
CSeg	segment 
assume cs:CSeg, ds:DSeg, ss:SSeg 

start:	mov		ax, DSeg 
	mov		ds, ax 

; (1) set timer mode 
; 10  11  011 0
; <1> <2> <3> <4>
; <1> - Tell the counter to connect to speaker
; <2> - The period is read from LSB to MSB
; <3> - Tell the timer to generate a square wave
; <4> - The period of the square wave is represented in binary number

	mov		al, 10110110b
	out		TimerMode, al      ; write control byte to port 43h

; (2) set frequency 

	mov		ax,	Period		; set freq of timer 2
	out		Timer2,	al		; send byte
	mov		al,	ah
	out		Timer2,	al



; modified by david
;
mov ah, 2		; set timer option to read 
int 1ah 

;Hour:
mov ah, 0             	; copy the second into ax
mov al, ch
div aa                  ; divide ax by a number
add ax, bb		; add a number to ax
mov hour2, ah		; ah stores the 2nd digit in ASCII format (= '6' in the example)
mov hour1, al   	; al stores the 1st digit in ASCII format (= '5' in the example)

;Minute:
mov ah, 0             	; copy the second into ax
mov al, cl
div aa                  	; divide ax by a number
add ax, bb		; add a number to ax
mov minute2, ah	; ah stores the 2nd digit in ASCII format (= '6' in the example)
mov minute1, al   	; al stores the 1st digit in ASCII format (= '5' in the example)

;Second:
mov ah, 0             	; copy the second into ax
mov al, dh
div aa                  	; divide ax by a number
add ax, bb		; add a number to ax
mov second2, ah	; ah stores the 2nd digit in ASCII format (= '6' in the example)
mov second1, al   	; al stores the 1st digit in ASCII format (= '5' in the example)

lea  dx, hour1
mov  ah, 9                   ;DOS print string function
int  21h                    ;display
lea  dx, hour2
mov  ah, 9                   ;DOS print string function
int  21h                    ;display

lea  dx, minute1
mov  ah, 9                   ;DOS print string function
int  21h                    ;display
lea  dx, minute2
mov  ah, 9                   ;DOS print string function
int  21h                    ;display

lea  dx, second1
mov  ah, 9                   ;DOS print string function
int  21h                    ;display
lea  dx, second2
mov  ah, 9                   ;DOS print string function
int  21h                    ;display

;end



; (3) turn on speaker 
; N.B. Since we only want to set the last 2 bits of I/O port to 1
;      we should use "or" instead of setting the port directly to 3
;      Otherwise, other real service of the system may be affected

	in		al, Port		; get port value
	or		al, on		; turn speaker on
	out		Port , al		; put it back to port

; (4) delay loop 
; delay 1 control number of seconds
; delay 2 consumes one second (approximately)

delay1:	mov		sec, OneSec		; delay loop
delay2:	sub		sec, 1
	jnz		delay2
	sub		nsec, 1
	jnz		delay1

; (5) turn off speaker 

	in		al, Port		; get port value
	and		al, NOT on		; turn speaker off
	out		Port , al		; put it back to port

	mov		ax, Term ; return to DOS 
	int		DosInt 
CSeg ends 
end start 
;The I/O instruction groups, in, out, can be found in Table 4.19 in the 25 page manual, page 98. 
;