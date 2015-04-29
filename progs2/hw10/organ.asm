model tiny
.code
org 100h

@entry:
	jmp @start
	infoMsg db 'This is simple electronic organ. Press ESC to exit.',13,10,'$'
	head dw 0
	tail dw 0
	separator db '----',13,10,'$'
	oldEs dw ?
	oldBx dw ?
	buffer db 8 dup(?)
	bufferSize dw 7
	
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
	
@mainLoop:
	mov 	bx, head
	cmp 	tail, bx
	je 		@mainLoop
	cli
	call 	incHead
	sti
	
	add 	bx, offset buffer
	mov 	al, byte ptr [bx]
	call 	printHex
	call	printNewLine
	cmp 	al, 81h 			; escape code
	je 		@restoreOldAndExit
	
	cmp 	al, 1h
	je		@stopSound
	cmp 	al, 80h
	ja		@stopSound
	
@playSound:	
	call 	calcFreqNum
	call	playSound
	jmp 	@next
	
@stopSound:
	call	stopSound
	
@next:	
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
    je 		@iOverlow
	
	; add new char
    in      al, 60h        
    lea  	bx, buffer
    add 	bx, tail
    mov 	byte ptr [bx], al
	call	incTail

	jmp 	@iExit
	
@iOverlow:
	call beep
@iExit:
	in 		al, 60h
	call 	ackReception
	; eoi
    mov     al, 20h
    out     20h, al
    pop		bx ax
    iret
int09h endp

; Arguments: al = scan code
; Returns: ax = frequency number
calcFreqNum proc
	push	bx
	xor 	ah, ah
	mov 	bl, 100
	mul		bl
	pop		bx
	ret
calcFreqNum endp

playSound proc
	push 	ax bx cx
	call	prepareSpeaker
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