model tiny
.code
org 100h

@entry:
	jmp @start
	infoMsg db 'This program prints up and down key scan-codes. Press ESC to exit.',13,10,'$'
	head dw 0
	tail dw 0
	separator db '----',13,10,'$'
	oldEs dw ?
	oldBx dw ?
	buffer db 8 dup(?)
	bufferMask dw 7
	
@start:
	lea 	dx, infoMsg
	call 	printMsg
	
	mov 	ax, 3509h
	int 	21h
	mov 	oldEs, es
	mov 	oldBx, bx
	
	mov 	ah, 25h
	mov 	dx, offset int09h
	int 	21h
	
@loop:
	mov 	bx, head
	cmp 	tail, bx
	je 		@loop
	cli
	call 	incHead
	sti
	add 	bx, offset buffer
	mov 	al, byte ptr [bx]
	call 	printHex
	call	printNewLine
	cmp 	al, 81h 			; escape code
	je 		@restoreOldAndExit
	cmp 	al, 0B9h
	jne 	@loop
	lea 	dx, separator
	call 	printMsg
	jmp 	@loop

@restoreOldAndExit:
	call 	restoreOld
	ret
	
	
int09h proc
    push	ax bx
    mov 	ax, tail
    inc 	ax
    and 	ax, bufferMask
    cmp 	ax, head
    je 		@overflow

	; add new char
    in      al, 60h        
    lea  	bx, buffer
    add 	bx, tail
    mov 	byte ptr [bx], al
	call	incTail

	jmp 	@exit
	
@overflow:
	call beep
@exit:
	in 		al, 60h
	call 	ackReception
	; eoi
    mov     al, 20h
    out     20h, al
    pop		bx ax
    iret
int09h endp
	
incHead proc
	push ax
	inc head
	mov ax, bufferMask
	and head, ax
	pop ax
	ret
incHead endp

incTail proc
	push ax
	inc tail
	mov ax, bufferMask
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
@k:            
	rol bx, 4                          ; 4 left bits to the right
	mov al, bl
	and al, 0Fh
	cmp al, 10
	sbb al, 69h
	das
	mov dh, 02h
	xchg ax, dx
	int 21h
	loop @k
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