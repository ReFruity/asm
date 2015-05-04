model tiny
.code
.386
org 100h

@entry:
	jmp @start
	infoMsg 			db 'This is simple electronic organ. Press ESC to exit.',13,10,'$'
	debugMsgSptr 		db 'Stack pointer: $'
	debugMsgRemRet 		db "'removeKey' procedure returns: $"
	debugMsgStack 		db 'Key stack: $'
	debugMsgPushKey 	db 'Not duplicate key!$'
	debugMsgCalcFreq 	db 'Key frequency found!$'
	separator 			db '----',13,10,'$'
	
	head 	dw 0
	tail 	dw 0
	prev 	db 0
	
	oldEs08h dw	?
	oldBx08h dw ?
	oldEs09h dw ?
	oldBx09h dw ?
	
	buffer 		db 8 dup(?)
	bufferSize 	dw 7
	
	maxKeys 	dw 0FFh
	keyStack 	db 0FFh dup(?)
	sptr 		dw 0
	
	nilKey 		db 0
	
	maxNotes 	dw 38
	scanCodes 	db 0Fh, 10h, 3h, 11h, 4h, 12h, 13h, 6h, 14h, 7h, 15h, 8h, 16h, 17h, 0Ah, 18h, 0Bh, 19h, 1Ah, 0Dh, 1Bh, 1Eh, 2Ch, 1Fh, 2Dh, 2Eh, 21h, 2Fh, 22h, 30h, 31h, 24h, 32h, 25h, 33h, 26h, 34h, 35h
	freqNums 	dw 9663, 9121, 8609, 8126, 7670, 7239, 6833, 6449, 6087, 5746, 5423, 5119, 4831, 4560, 4304, 4063, 3834, 3619, 3416, 3224, 3043, 2873, 2711, 2559, 2415, 2280, 2152, 2031, 1917, 1809, 1715, 1612, 1521, 1436, 1355, 1292, 1207, 1140
	
	melodyNotesAmount	dw 	198
	melodyFreqs 		dw 	4560, 3619, 3043, 2280, 1809, 3043, 2280, 1809
	melodyFreqs2		dw	4560, 3619, 3043, 2280, 1809, 3043, 2280, 1809
	melodyFreqs3		dw	4560, 4063, 2711, 2031, 1715, 2711, 2031, 1715
	melodyFreqs4		dw	4560, 4063, 2711, 2031, 1715, 2711, 2031, 1715
	melodyFreqs5		dw	4831, 4063, 3043, 2031, 1715, 3043, 2031, 1715
	melodyFreqs6		dw	4831, 4063, 3043, 2031, 1715, 3043, 2031, 1715
	melodyFreqs7		dw	4560, 3619, 3043, 2280, 1809, 3043, 2280, 1809
	melodyFreqs8		dw	4560, 3619, 3043, 2280, 1809, 3043, 2280, 1809
	
	melodyFreqs9		dw	4560, 3619, 2711, 1809, 1355, 2711, 1809, 1355
	melodyFreqs10		dw	4560, 3619, 2711, 1809, 1355, 2711, 1809, 1355
	melodyFreqs11		dw	4560, 4063, 3224, 2711, 2031, 3224, 2711, 2031
	melodyFreqs12		dw	4560, 4063, 3224, 2711, 2031, 3224, 2711, 2031
	melodyFreqs13		dw	4831, 4063, 3043, 2031, 1521, 3043, 2031, 1521
	melodyFreqs14		dw	4831, 4063, 3043, 2031, 1521, 3043, 2031, 1521
	melodyFreqs15		dw	4831, 4560, 3619, 3043, 2280, 3619, 3043, 2280
	melodyFreqs16		dw	4831, 4560, 3619, 3043, 2280, 3619, 3043, 2280
	
	melodyFreqs17		dw	5423, 4560, 3619, 3043, 2280, 3619, 3043, 2280
	melodyFreqs18		dw	5423, 4560, 3619, 3043, 2280, 3619, 3043, 2280
	melodyFreqs19		dw	8126, 5423, 4063, 3224, 2280, 4063, 3224, 2280
	melodyFreqs20		dw	8126, 5423, 4063, 3224, 2280, 4063, 3224, 2280
	melodyFreqs21		dw	6087, 4831, 4063, 3043, 2415, 4063, 3043, 2415
	melodyFreqs22		dw	6087, 4831, 4063, 3043, 2415, 4063, 3043, 2711
	melodyFreqs23		dw	5423, 4560, 3834, 3043, 2711, 3043, 3834, 4560
	melodyFreqs24		dw	3043, 3834, 4560, 5423, 3834, 4560, 5423, 7239
	
	melodyFreqs25		dw	12175,8126, 6087, 4831, 4063, 3043

	; 	Arranged Octaves (doc)
	;	9121, 8609, 8126, 7670, 7239, 6833, 6449, 6087, 5746, 5423, 5119, 4831, 
	;	4560, 4304, 4063, 3834, 3619, 3416, 3224, 3043, 2873, 2711, 2559, 2415, 
	;	2280, 2152, 2031, 1917, 1809, 1715, 1612, 1521, 1436, 1355, 1292, 1207, 
	;	1140, 
	
	; 	Calculated numbers
	; 																 43388, 40953, 38655, 
	; 36485, 34437, 32505, 30680, 28958, 27333, 25799, 24351, 22984, 21694, 20477, 19327, 
	; 18243, 17219, 16252, 15340, 14479, 13666, 12899, 12175, 11492, 10847, 10238, 9664, 
	; 9121,  8609,  8126,  7670,  7240,  6833,  6450,  6088,  5746,  5424,  5119,  4832,  
	; 4561,  4305,  4063,  3835,  3620,  3417,  3225,  3044,  2873,  2712,  2560,  2416,  
	; 2280,  2152,  2032,  1918,  1810,  1708,  1612,  1522,  1437,  1356,  1280,  1208,  
	; 1140,  1076,  1016,  959,   905,   854,   806,   761,   718,   678,   640,   604,   
	; 570,   538,   508,   479,   452,   427,   403,   380,   359,   339,   320,   302,   
	; 285
	
	melody2Freqs		dw	0
	
	noteDurations 		dw 	192 dup (3)
	noteDurations2 		dw 	1, 1, 1, 1, 1, 8
	delayCounter 		dw 	0
	noteCounter 		dw 	0
	
@start:
	lea 	dx, infoMsg
	call 	printMsg
	
	call	saveOld08h
	call	saveOld09h
	call	install09h
	
	call	prepareSpeaker
	
@mainLoop:
	mov 	bx, head
	cmp 	tail, bx
	je 		@mainLoop
	cli
	call 	incHead
	sti
	
	add 	bx, offset buffer
	mov 	al, byte ptr [bx]
	
	; ignore rapid repeating
	cmp		al, prev
	je 		@mainLoop
	mov		prev, al
	
	; ignore additional scan-codes
	; cli
	; mov		dx, tail
	; mov 	head, dx
	; sti
	
	call	printHex
	call 	printNewLine
	
	cmp 	al, 81h 			; escape code
	je 		@restoreOldAndExit
	
	cmp 	al, 4Ch				; num 5
	je		@playMelody
	
	cmp		al, 50h				; num 2
	je 		@stopMelody
	
	cmp 	al, 1h
	je		@onKeyUp			; escape stops the sound
	cmp 	al, 80h
	ja		@onKeyUp
	
@onKeyPressed:	
	call 	calcFreqNum
	cmp		bx, 0				
	je		@next				; not a keyboard key
	call	pushKey
	call	playSoundOrIgnore
	jmp 	@next
	
@onKeyUp:
	call	removeKey
	
	; Debug info
	; push 	ax
	; lea 	dx, debugMsgRemRet
	; call 	printMsg
	; mov 	ax, bx
	; call	printHex
	; call 	printNewLine
	; pop 	ax
	
	test	bx, bx
	jz		@next
	call	stopSound
	cmp		sptr, 0
	jz 		@next
	call	peekKey
	call 	calcFreqNum
	call	playSoundOrIgnore
	
@next:	
	; Debug info
	call 	printSptr
	; call 	printKeyStack
	call 	printNewLine

	cmp 	al, 0B9h
	jne 	@mainLoop
	
	lea 	dx, separator
	call 	printMsg
	jmp 	@mainLoop
	
@playMelody:
	mov		noteCounter, 0
	mov		delayCounter, 0
	call	install08h
	jmp 	@mainLoop
	
@stopMelody:
	call 	restoreOld08h
	call	stopSound
	jmp 	@mainLoop
	
@restoreOldAndExit:
	call 	restoreOld08h
	call 	restoreOld09h
	call	stopSound
	ret
	
	
int09h proc
    push	ax bx
    mov 	ax, tail
    inc 	ax
    and 	ax, bufferSize
    cmp 	ax, head
	in      al, 60h        
    je		@iOverlow

	; add new char
    lea  	bx, buffer
    add 	bx, tail
    mov 	byte ptr [bx], al
	call	incTail

	jmp 	@iExit
	
@iOverlow:
	call	beep
@iExit:
	call 	ackReception
	; eoi
    mov     al, 20h
    out     20h, al
    pop		bx ax
    iret
int09h endp

int08h proc
	push	ax bx cx ds si
	push 	cs
	pop 	ds	
	
	mov 	cx, noteCounter
	cmp		cx, melodyNotesAmount
	jl		@i08Step
	jmp		@i08Stop
	
@i08Step:
	cmp		delayCounter, 0
	je		@i08Play
	
	lea 	si, noteDurations
	mov		cx, noteCounter
	shl		cx, 1
	add		si, cx
	mov		cx, [si]
	cmp		delayCounter, cx
	jl		@i08Inc
	
	mov		delayCounter, 0
	inc 	noteCounter
	
	; Debug 
	mov 	ax, noteCounter
	call	printHex
	call 	printSpace
	
	jmp 	@i08End

@i08Play:
	lea 	si, melodyFreqs
	mov		cx, noteCounter
	shl		cx, 1
	add		si, cx
	mov		bx, [si]
	call 	playSoundOrStop
	jmp		@i08Inc
	
@i08Inc:
	inc		delayCounter
	jmp 	@i08End
@i08Stop:
	call	stopSound
	call	restoreOld08h
@i08End:
	mov 	al, 20h
	out		20h, al
	pop		si ds cx bx ax
	iret
int08h endp

; Doesn't push duplicate key and can't cause overflow
; Arguments: al = scan-code
pushKey proc
	push	bx dx
	; check if stack is going to overlow
	mov 	dx, maxKeys
	cmp		dx, sptr
	jle		@pkEnd
	
	lea 	bx, keyStack
	add 	bx, sptr
	; check if empty
	cmp 	sptr, 0
	je		@pkNext
	; check if it's duplicate
	mov		dl, byte ptr [bx - 1]
	cmp		al, dl
	je 		@pkEnd
	; debug msg
	; lea		dx, debugMsgPushKey
	; call 	printMsg
	; call 	printNewLine
@pkNext:
	mov		byte ptr [bx], al
	inc 	sptr
@pkEnd:
	pop		dx bx
	ret
pushKey endp

; Arguments: al = key up scan-code
; Returns: bx = if top scan-code removed
removeKey proc
	push	ax dx
	cmp 	sptr, 0
	je 		@rkRet0
	sub		al, 80h				; translate to press scan-code
	
	lea 	bx, keyStack
	lea		dx, keyStack
	add 	dx, sptr
@rkLoop:
	cmp 	byte ptr [bx], al
	je 		@rkFound
	inc 	bx
	cmp		bx, dx
	jl	 	@rkLoop
	jmp 	@rkRet0
@rkFound:
	push 	dx
	mov		dl, nilKey
	mov		byte ptr [bx], dl
	call	popNilKeys
	pop 	dx
	inc 	bx
	
	; Debug info
	; mov		al, bl
	; call 	printHex
	; call 	printSpace
	; mov 	al, dl
	; call	printHex
	; call 	printNewLine
	
	cmp 	bx, dx
	jne		@rkRet0
@rkRet1:
	mov 	bx, 1
	jmp 	@rkEnd
@rkRet0:
	xor		bx, bx
@rkEnd:
	pop		dx ax
	ret
removeKey endp

; Removes all the nil keys from the top of the stack
popNilKeys proc
	push	ax bx cx dx
	cmp		sptr, 0
	jz 		@pnkEnd
	
	lea		bx, keyStack
	add		bx, sptr
	mov		cx, sptr
	mov 	dl, nilKey
@pnkLoop:
	dec 	bx
	cmp		byte ptr [bx], dl
	jne 	@pnkEnd
	call	popKey
	loop 	@pnkLoop
@pnkEnd:
	pop		dx cx bx ax 
	ret
popNilKeys endp

; Returns: al = scan-code at the top of the key stack
peekKey proc
	push	bx
	cmp		sptr, 0
	jz 		@peekKeyEnd
	
	lea 	bx, keyStack
	add 	bx, sptr
	dec 	bx
	xor		ax, ax
	mov 	al, byte ptr [bx]
	@peekKeyEnd:
	pop		bx
	ret
peekKey endp

; Returns: al = popped scan-code
popKey proc
	push	bx
	cmp		sptr , 0
	jz		@popkEnd
	
	dec 	sptr
	lea 	bx, keyStack
	add 	bx, sptr
	xor		ax, ax
	mov 	al, byte ptr [bx]
@popkEnd:
	pop		bx
	ret
popKey endp

; Arguments: al = scan-code
; Returns: bx = frequency number; 0 if not found
calcFreqNum proc
	push	ax cx
	xor		cx, cx
	lea		di, scanCodes
@cfnLoop:
	cmp 	byte ptr [di], al
	je		@cfnRetFreq
	inc 	cx
	inc 	di
	cmp		cx, maxNotes
	jl	 	@cfnLoop
	jmp		@cfnRet0
@cfnRetFreq:
	; Debug info
	; lea		dx, debugMsgCalcFreq
	; call	printMsg
	; call 	printNewLine
	
	mov		ax, 2
	mul		cl
	mov 	cx, ax
	
	lea 	di, freqNums
	add		di, cx
	mov		bx, [di]
	jmp 	@cfnEnd
@cfnRet0:
	xor 	bx, bx
@cfnEnd:
	pop		cx ax
	ret
calcFreqNum endp

playSoundOrStop proc
	cmp 	bx, 0
	je		@psosStop
	call 	playSound
	jmp		@psosEnd
@psosStop:
	call 	stopSound
@psosEnd:
	ret
playSoundOrStop endp

; Arguments: bx = frequency number, ignore if bx = 0
playSoundOrIgnore proc
	cmp 	bx, 0			
	je 		@psoiEnd
	call	playSound
@psoiEnd:
	ret
playSoundOrIgnore endp

; Arguments: bx = frequency number
playSound proc
	push 	ax bx cx
	mov 	ax, bx
	; mov     ax, 4560        ; Frequency number (in decimal)
							;  for middle C.
	out     42h, al         ; Output low byte.
	mov     al, ah          ; Output high byte.
	out     42h, al 
	in      al, 61h         ; Turn on note (get value from
							;  port 61h).
	or      al, 00000011b   ; Set bits 1 and 0.
	out     61h, al         ; Send new value.
@psEnd:
	pop 	cx bx ax
	ret
playSound endp

stopSound proc
	push	ax
	in      al, 61h         ; Turn off note (get value from
							;  port 61h).
	and     al, 11111100b   ; Reset bits 1 and 0.
	out     61h, al         ; Send new value.
	pop		ax
	ret
stopSound endp
	
prepareSpeaker proc
	push	ax
	mov     al, 182
	out     43h, al
	pop		ax
	ret
prepareSpeaker endp
	
incHead proc
	push ax
	inc head
	mov ax, bufferSize
	and head, ax
	pop ax
	ret
incHead endp

incTail proc
	push ax
	inc tail
	mov ax, bufferSize
	and tail, ax
	pop ax
	ret
incTail endp
	
saveOld08h proc
	push	ax es bx
	mov 	ax, 3508h
	int 	21h
	mov 	oldEs08h, es
	mov 	oldBx08h, bx
	pop		bx es ax
	ret
saveOld08h endp
	
saveOld09h proc
	push	ax es bx
	mov 	ax, 3509h
	int 	21h
	mov 	oldEs09h, es
	mov 	oldBx09h, bx
	pop		bx es ax
	ret
saveOld09h endp

install08h proc
	push	ax dx
	mov 	ax, 2508h
	mov 	dx, offset int08h
	int 	21h
	pop		dx ax
	ret
install08h endp

install09h proc
	push	ax dx
	mov 	ax, 2509h
	mov 	dx, offset int09h
	int 	21h
	pop		dx ax
	ret
install09h endp

restoreOld08h proc
	push	ax dx ds
	mov 	ax, 2508h
	mov 	dx, oldBx08h
	mov 	ds, oldEs08h
	int 	21h
	pop 	ds dx ax
	ret
restoreOld08h endp
	
restoreOld09h proc
	push	ax dx ds
	mov 	ax, 2509h
	mov 	dx, oldBx09h
	mov 	ds, oldEs09h
	int 	21h
	pop 	ds dx ax
	ret
restoreOld09h endp
	
ackReception proc
	in		al, 61h
    mov     ah, al
    or      al, 80h
    out     61h, al
    xchg    ah, al 
    out     61h, al
	ret
ackReception endp
	
printKeyStack proc
	push	ax bx cx dx
	lea 	dx, debugMsgStack
	call 	printMsg
	mov 	cx, maxKeys
	lea 	bx, keyStack
@pksLoop:
	mov 	al, byte ptr [bx]
	inc 	bx
	call 	printHex
	call 	printSpace
	loop 	@pksLoop
	call 	printNewLine
	pop		dx cx bx ax
	ret
printKeyStack endp

printSptr proc
	push	ax dx
	lea 	dx, debugMsgSptr
	call	printMsg
	mov		ax, sptr
	call	printHex
	call	printNewLine
	pop		dx ax
	ret
printSptr endp
	
; Arguments: al = hex number to print
printHex proc
	push ax bx cx dx
	mov bx, ax                         ; arg
	mov bh, bl
	mov cx, 2
@phLoop:            
	rol bx, 4                          ; 4 left bits to the right
	mov al, bl
	and al, 0Fh
	cmp al, 10
	sbb al, 69h
	das
	mov dh, 02h
	xchg ax, dx
	int 21h
	loop @phLoop
	pop dx cx bx ax
	ret
printHex endp

; dx = $ terminated message offset 
printMsg proc
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
printMsg endp

printNewLine proc
	push ax dx
	mov ah, 02h
	mov dl, 0Dh
	int 21h
	mov dl, 0Ah
	int 21h
	pop dx ax
	ret
printNewLine endp

printSpace proc
	push ax dx
	mov ah, 02h
	mov dl, ' '
	int 21h
	pop dx ax
	ret
printSpace endp

beep proc
	push ax dx
	mov ah, 02h
	; mov dl, 07h
	mov dl, 06h
	int 21h
	pop dx ax
	ret
beep endp
end @entry