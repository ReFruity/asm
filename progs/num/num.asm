.model tiny
.code
org 100h
@entry: jmp @start
	var dw 65535d
	c10 dw 10d
@start:
	mov ax, var
	mov cx, 0
@loop:	
	xor dx, dx
	div c10
	push dx
	inc cx
	test ax, ax
	jne @loop
@end:
	mov ah, 02h
	pop dx
	add dx, '0'
	int 21h
	loop @end
	ret
end @entry