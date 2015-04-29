.model tiny
.code
org 100h
@entry: jmp @start
	base db 10d
	divisor db 3d
	buffer db 512 dup('$')
@start:
	mov cl, ds:[80h]
	dec cx
	mov si, 82h
	mov di, offset buffer
	mov ah, 00h ; remainder
@loop:
	lodsb
	sub al, '0' ; dividend
	call mult
	div divisor
	add al, '0'
	stosb
	loop @loop
	; printing
	mov ah, 09h
	mov dx, offset buffer
	; no leading zeros
	mov bx, dx
	mov bl, [bx]
	xor bh, bh
	sub bx, '0'
	test bx, bx
	jnz @nozero
	mov bx, ds:[80h]
	xor bh, bh
	sub bx, 02h
	test bx, bx
	jz @nozero
	inc dx
@nozero:
	int 21h
	ret
mult proc ; al += ah*base; ah = 0
	push bx
	mov bx, ax
	mov al, ah
	xor ah, ah
	mul base
	add al, bl
	pop bx
	ret
mult endp

end @entry