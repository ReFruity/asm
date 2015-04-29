.model tiny
.code
org 100h
@entry: jmp @start
	base dw 10d
	divisor dw 4d
	base2 dw 16d
	hex db '0123456789ABCDEF'
@start:
	mov si, 82h
	mov cl, ds:[80h]
	dec cx
	xor bx, bx
@loop:
	lodsb
	sub ax, '0'
	call mult
	loop @loop
	mov ax, bx
	div divisor
	xor cx, cx
@loop2:
	xor dx, dx
	div base2
	push dx
	inc cx
	test ax, ax
	jnz @loop2
@loop3:
	pop ax
	call print
	loop @loop3
	ret
mult proc ; bx = bx*base + ax
	push ax
	mov ax, bx
	mul base
	mov bx, ax
	pop ax
	add bx, ax
	ret
mult endp
print proc ; print num in al as hex
	push ax bx dx si
	mov si, offset hex
	xor bh, bh
	mov bl, al
	mov dl, [si + bx]
	mov ah, 02h
	int 21h
	pop si dx bx ax
	ret
print endp
end @entry