.model tiny
.386
.code
org 100h
@entry:
	jmp @start
	msg db 'Totally nailed it!$'
	; nop
@start:
	; xor ax, ax
	; mov es, ax
	; mov word ptr es:[0], offset myhandler
	mov ah, 25h
	mov al, 0h
	mov dx, offset myhandler
	int 21h
	jmp @ending
	; xor ax, ax
	; div al
myhandler proc
	push ax bx cx dx
	mov ah, 09h
	push cs
	pop ds
	mov dx, offset msg
	int 21h
	pop dx cx bx ax
	mov al, 20h
	out 20h, al
	iret
myhandler endp
@ending:
	mov dx, word ptr [$+6]
	int 27h
end @entry