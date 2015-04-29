.model tiny
.386
.code
org 100h
@entry:		
	jmp @start
	f31h db '/w1'
	int27h db '/w2'
	msg1 db 'Using f31h$'
	msg2 db 'Using int27h$'
	invalidArgsMsg db 'Specified argument is invalid, use /w1 or /w2$'
@start:		
	call readArgs
	test ax, ax
	jz @invalid
	cmp ax, 1
	je @f31h
	cmp ax, 2
	je @int27h
@f31h:
	lea dx, msg1
	call printMsg
@int27h:
	lea dx, msg2
	call printMsg
	call residentInt27H
@invalid:
	lea dx, invalidArgsMsg
	call printMsg
	ret
	
residentF31h proc
	mov ah, 31h
	xor al, al
	xor dx, dx
	; dx paragraphs are resident
	int 21h
	ret
residentF31h endp

residentInt27H proc
	xor dx, dx 
	; resident from start to cs:dx 
	int 27h
residentInt27H endp
	
readArgs proc
	push bx cx dx si di
	
	mov al, byte ptr ds:[80h]
	cmp al, 3
	jle @raInvalid
	
	mov cx, 3
	mov si, 82h
	lea di, f31h
	rep cmpsb				
	je @arg1				; if arg is /w1
	
	mov cx, 3
	mov si, 82h
	lea di, int27h
	rep cmpsb				
	je @arg2				; if arg is /w1
	
@raInvalid:
	xor ax, ax				; invalid arg
	jmp @raEnd
@arg1:
	mov ax, 1
	jmp @raEnd
@arg2:
	mov ax, 2
@raEnd:
	pop di si dx cx bx
	ret
readArgs endp

; dx = $ terminated message offset 
printMsg proc
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
printMsg endp

end @entry