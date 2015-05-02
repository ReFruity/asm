model tiny
.code
.386
org 100h

@entry:
	jmp @start
	infoMsg db 'This is simple electronic organ. Press ESC to exit.',13,10,'$'
	debugMsg db 'Stack pointer: $'
	debugMsgRemRet db "'removeKey' procedure returns: $"
	debugMsgStack db 'Key stack: $'
	pushKeyDbg db 'Not duplicate key!$'
	head dw 0
	tail dw 0
	prev db 0
	separator db '----',13,10,'$'
	oldEs dw ?
	oldBx dw ?
	
	buffer db 8 dup(?)
	bufferSize dw 7
	
	maxKeys dw 10
	keyStack db 10 dup(?)
	sptr dw 0
	
	nilKey db 0
	
@start:
	lea 	dx, infoMsg
	call 	printMsg
	; save old vector
	mov 	ax, 3509h
	int 	21h
	mov 	oldEs, es
	mov 	oldBx, bx
	; intall our vector
	mov 	ah, 25h
	mov 	dx, offset int09h
	int 	21h
	
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
	
	cmp		al, prev
	je 		@mainLoop
	mov		prev, al
	
	call 	printHex
	call	printNewLine
	cmp 	al, 81h 			; escape code
	je 		@restoreOldAndExit
	
	cmp 	al, 1h
	je		@onKeyUp
	cmp 	al, 80h
	ja		@onKeyUp
	
@onKeyPressed:	
	call	pushKey
	call 	calcFreqNum
	call	playSound
	jmp 	@next
	
@onKeyUp:
	call	removeKey
	
	; Debug info
	push 	ax
	lea 	dx, debugMsgRemRet
	call 	printMsg
	mov 	ax, bx
	call	printHex
	call 	printNewLine
	pop 	ax
	
	test	bx, bx
	jz		@next
	call	stopSound
	cmp		sptr, 0
	jz 		@next
	call	popKey
	call 	calcFreqNum
	call	playSound
	
@next:	
	; Debug info
	lea 	dx, debugMsg
	call	printMsg
	push 	ax
	mov		ax, sptr
	call	printHex
	call	printNewLine
	call 	printKeyStack
	call 	printNewLine
	pop		ax

	cmp 	al, 0B9h
	jne 	@mainLoop
	
	lea 	dx, separator
	call 	printMsg
	jmp 	@mainLoop
	
@restoreOldAndExit:
	call	stopSound
	call 	restoreOld
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
	lea		dx, pushKeyDbg
	call 	printMsg
	call 	printNewLine
@pkNext:
	mov		byte ptr [bx], al
	inc 	sptr
@pkEnd:
	pop		dx bx
	ret
pushKey endp

; Arguments: al = scan-code
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
	mov		al, bl
	call 	printHex
	call 	printSpace
	mov 	al, dl
	call	printHex
	call 	printNewLine
	
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
; Returns: bx = frequency number
calcFreqNum proc
	push	ax
	xor 	ah, ah
	mov 	bl, 100
	mul		bl
	mov		bx, ax
	pop		ax
	ret
calcFreqNum endp

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
	
restoreOld proc
	mov 	ax, 2509h
	mov 	dx, oldBx
	push 	ds
	mov 	ds, oldEs
	int 	21h
	pop 	ds
	ret
restoreOld endp
	
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
	push	cx
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
	pop		cx
	ret
printKeyStack endp
	
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