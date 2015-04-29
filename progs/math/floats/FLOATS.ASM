.model tiny
.386
.code
org 100h
@entry:
	jmp @start
	x dd 12.75
	y dd 1.25
@start:
	mov ax, offset x
	mov bx, offset y
	xor cx, cx
	mov cl, ds:[82h]
@add:
	cmp cl, '+'
	jnz @sub
	call sum
	jmp @end
@sub:
	cmp cl, '-'
	jnz @mul
	call subtr
	jmp @end
@mul:
	cmp cl, '*'
	jnz @div
	call mult
	jmp @end
@div:
	cmp cl, '/'
	jnz @sin
	call divis
	jmp @end
@sin:
	cmp cl, 's'
	jnz @xcosy
	call sin
	jmp @end
@xcosy:
	cmp cl, 'c'
	jnz @lnxpy
	call xcosy
	jmp @end
@lnxpy:
	cmp cl, 'l'
	jnz @end
	call lnxpy
@end:
	mov ax, word ptr [x+2]
	call printHexNumber
	mov ax, word ptr [x]
	call printHexNumber
	ret
sum proc
	push ax bx cx dx
	finit
	fld dword ptr[bx]
	mov bx, ax
	fld dword ptr[bx]
	fadd
	fst dword ptr[bx]
	pop dx cx bx ax
	ret
sum endp
subtr proc ; [ax] = [bx] - [ax]
	push ax bx cx dx
	finit
	fld dword ptr[bx]
	mov bx, ax
	fld dword ptr[bx]
	fsub
	fst dword ptr[bx]
	pop dx cx bx ax
	ret
subtr endp
mult proc
	push ax bx cx dx
	finit
	fld dword ptr[bx]
	mov bx, ax
	fld dword ptr[bx]
	fmul
	fst dword ptr[bx]
	pop dx cx bx ax
	ret
mult endp
divis proc ; [ax] = [bx] / [ax]
	push ax bx cx dx
	finit
	fld dword ptr[bx]
	mov bx, ax
	fld dword ptr[bx]
	fdiv
	fst dword ptr[bx]
	pop dx cx bx ax
	ret
divis endp
sin proc
	push ax bx cx dx
	finit
	mov bx, ax
	fld dword ptr[bx]
	fsin
	fst dword ptr[bx]
	pop dx cx bx ax
	ret
sin endp
xcosy proc ; [ax] = [ax] * cos[bx]
	push ax bx cx dx
	finit
	fld dword ptr[bx]
	fcos
	fst dword ptr[bx]
	call mult
	pop dx cx bx ax
	ret
xcosy endp
lnxpy proc ; [ax] = ln[ax] + [bx]
	push ax bx cx dx
	call lnx
	call sum
	pop dx cx bx ax
	ret
lnxpy endp
lnx proc ; [ax] = ln[ax]
	jmp @body
	one dd 1.0
@body:
	push ax bx cx dx
	finit
	mov bx, ax
	fld one
	fld dword ptr[bx]
	fyl2x
	fldl2e
	fdiv
	fst dword ptr[bx]
	pop dx cx bx ax
	ret
lnx endp
printHexNumber proc
        push bx cx dx
        mov bx, ax 
        mov cx, 4
@k:		rol bx, 4 
        mov al, bl
        and al, 0fh
        cmp al, 10
        sbb al, 69h
        das
        mov dh, 02h
        xchg ax, dx
        int 21h
        loop @k
        pop dx cx bx
        ret
printHexNumber endp
end @entry