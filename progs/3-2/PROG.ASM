.model tiny
.code
org 100h
@entry: 
	jmp @start
	base dw 10d
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
	
	mov cx, ax
	xor ax, ax
	xor bx, bx
	mov si, offset buffer
@loop:
	lodsb
	cmp al, 0Ah
	jne @endc
	inc bx
@endc:
	loop @loop
	
	mov ax, bx
	call print_num
	ret
	
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