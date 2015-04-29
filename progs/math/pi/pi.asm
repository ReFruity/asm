.model tiny
.386
.code
org 100h
@entry:
	jmp @start
	num dd 0
	base dw 10d
@start:
	call readNumber
	mov word ptr [num], ax
	finit
	fldpi
	fild num
	fmul
	fist num
	mov ax, word ptr [num]
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
readNumber proc
        push bx cx dx di si
        xor di, di
        mov cx, cs:80h
        xor ch, ch
        dec cl
        mov si, 82h
        mov bx, 0ah
        xor ax, ax
        xor dx, dx
@loop:  lodsb
        sub al, 30h
        xchg ax, di
        mul bx
        add ax, di
        xchg ax, di
        loop @loop
        mov ax, di
        pop si di dx cx bx
        ret
readNumber endp
end @entry