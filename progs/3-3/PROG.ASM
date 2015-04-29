.model tiny
.code
.386
org 100h
@entry: 
	jmp @start
	base dw 10d
	string db 'ma'
	FileName db 0Fh dup(0)
	ErrorMsg db 'Error while reading file.','$'
@start:
	mov cx, ds:[80h]
	xor ch, ch
	test cx, cx
	jz @error
	dec cx
	mov si, 82h
	mov di, offset FileName
	rep movsb

	mov ah, 3Dh
	mov al, 0h
	mov dx, offset FileName
	int 21h
	jc @error
	
	mov bx, ax
	mov ah, 3Fh
	mov cx, 0FC00h
	mov dx, offset buffer
	int 21h
	jc @error
	
	lea dx, FileName
	sub dx, offset string ; string length
	mov cx, ax ; how many bytes were read
	sub cx, dx
	xor bx, bx ; answer
	mov si, offset buffer
	mov di, offset string
@loop:
	mov ax, dx
	call compare
	add bx, ax
	inc si
	loop @loop
	
	mov ax, bx
	call print_num
	ret
	
compare proc
	push bx cx dx si di
	mov cx, ax
	rep cmpsb
	jne @nequal
	mov ax, 1h
	jmp @cend
@nequal:
	mov ax, 0h
@cend:
	pop di si dx cx bx
	ret
compare endp
	
print_num proc
	push ax bx cx dx
	mov cx, 0
@ploop:
	xor dx, dx
	div base
	push dx
	inc cx
	test ax, ax
	jne @ploop
@pend:
	mov ah, 02h
	pop dx
	add dx, '0'
	int 21h
	loop @pend
	pop dx cx bx ax
	ret
print_num endp
	
@error:
	mov dx, offset ErrorMsg
	mov ah, 09h
	int 21h
	ret
	buffer db 0FC00h dup(?)
end @entry