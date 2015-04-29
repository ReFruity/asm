.model tiny
.code
org 100h
@entry:
	jmp @start
	info db 'This program prints scan-code, ASCII code and ASCII symbol of pressed keys.', 0Dh, 0Ah, 'Press ESC to exit.', 0Dh, 0Ah, '$'
@start:
	lea dx, info
	call printMsg

@loop:
	mov ah, 00h
	int 16h
	ror ax, 8h
	call printHexNumber
	rol ax, 8h
	call printSpace
	call printHexNumber
	call printSpace
	call printASCII
	call printNewLine
	cmp ah, 01h			; esc scan-code
	jne @loop
	ret
	
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
	
; prints ASCII symbol using code in al
printASCII proc
	push ax dx
	mov ah, 02h
	mov dl, al
	int 21h
	pop dx ax
	ret
printASCII endp

; prints hex number in al
printHexNumber proc
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
printHexNumber endp

; dx = $ terminated message offset 
printMsg proc
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
printMsg endp
end @entry