.model tiny
.386
.code
org 100h
@entry:
	jmp @start
	savedMode db 0
	num dw 180
	buf dd 0
	zoom dw 20
	hx dw 160
	hy dw 100
	maxy dw 200
	cfunc db 0
	funcs dw offset square, offset sin, offset cos, offset lnx, offset tang
	keys dw 011bh, 3920h, 0d3dh, 0c2dh
	handlers dw offset exit, offset switch, offset zoomin, offset zoomout
	nop 
	nop 
	nop
@start:
	; get current video mode
	mov ah, 0fh
	int 10h
	; save video mode
	mov savedMode, al
	; set video mode
	mov ah, 0h
	mov al, 13h
	int 10h
	call draw
@mainloop:
	; read symbol
	xor ax, ax
	int 16h
	call findhandler
	jnz @mainloop
	mov bx, ax
	add bx, offset handlers
	mov ax, word ptr [bx]
	call ax
	jmp @mainloop
	ret
	
putPixel proc ; coords = (cx,dx)
	push ax cx dx
	mov ah, 0ch ; putting pixel
	mov al, 0h ; colour
	; mov cx, 100 ; horizontal
	; mov dx, 50 ; vertical
	int 10h
	pop dx cx ax
	ret
putPixel endp
	
clearscr proc
	push ax bx cx dx
    mov ah, 06h
    mov al, 00h
    mov cx, 00h
    mov dh, 30
    mov dl, 80
    mov bh, 0fh ; colour
    int 10h
	pop dx cx bx ax
	ret
clearscr endp
	
drawAxes proc
	push ax bx cx dx
	mov ah, 0ch
	mov al, 2h ; colour (green)
	
	mov cx, 200 ; counter
	mov dx, 0
@vertical:
	push cx
	mov cx, 160
	int 10h
	call vertMarkHere
	jz @novertmark
	call vertMark
@novertmark:
	pop cx
	inc dx
	loop @vertical
	
	mov bx, 0 
	mov dx, 100
	mov cx, 320 ; counter
@horizontal:
	xchg bx, cx
	int 10h
	call horMarkHere ; pasted
	jz @nohormark
	call horMark
@nohormark: ; till this mark
	inc cx
	xchg bx, cx
	loop @horizontal
	pop dx cx bx ax
	ret
drawAxes endp

vertMarkHere proc ; arg = dx
	push ax bx cx dx
	mov ax, hy
	cmp ax, dx
	jg @vmhupper
	xchg ax, dx
@vmhupper:
	sub ax, dx
	jz @vmhret0
	xor dx, dx
	div zoom
	test dx, dx
	jz @vmhret1
@vmhret0:
	xor ax, ax
	pop dx cx bx ax
	ret
@vmhret1:
	or ax, 1
	pop dx cx bx ax
	ret
vertMarkHere endp

horMarkHere proc ; arg = cx
	push ax bx cx dx
	mov ax, hx
	cmp ax, cx
	jg @hmhleft
	xchg ax, cx
@hmhleft:
	sub ax, cx
	jz @hmhret0
	xor dx, dx
	div zoom
	test dx, dx
	jz @hmhret1
@hmhret0:
	xor ax, ax
	pop dx cx bx ax
	ret
@hmhret1:
	or ax, 1
	pop dx cx bx ax
	ret
horMarkHere endp

vertMark proc
	push ax bx cx dx
	mov ah, 0ch
	mov al, 1h ; colour (blue)
	dec cx
	int 10h
	inc cx
	int 10h
	inc cx
	int 10h
	pop dx cx bx ax
	ret
vertMark endp

horMark proc
	push ax bx cx dx
	mov ah, 0ch
	mov al, 1h ; colour (blue)
	dec dx
	int 10h
	inc dx
	int 10h
	inc dx
	int 10h
	pop dx cx bx ax
	ret
horMark endp

draw proc
	push ax bx cx dx
	call clearscr
	call drawAxes
	mov cx, 320
@draw:
	dec cx
	mov word ptr[buf], cx
	mov word ptr[buf+2], 0
	mov ax, offset buf
	call fromCoord
	mov bx, offset funcs
	add bl, byte ptr[cfunc]
	mov bx, [bx]
	call bx
	call toCoord
	mov dx, word ptr[buf]
	cmp dx, 199
	ja @outofbounds
	call putPixel
@outofbounds:
	inc cx
	loop @draw
	pop dx cx bx ax
	ret
draw endp

square proc
	push ax bx cx dx
	finit
	mov bx, ax
	fld dword ptr[bx]
	fld dword ptr[bx]
	fmul
	; fldpi ; debug
	; fsubr
	fst dword ptr[bx]
	pop dx cx bx ax
	ret
square endp

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

cos proc
	push ax bx cx dx
	finit
	mov bx, ax
	fld dword ptr[bx]
	fcos
	fst dword ptr[bx]
	pop dx cx bx ax
	ret
cos endp

lnx proc ; [ax] = ln[ax]
	jmp @lnxcode
	one dd 1.0
@lnxcode:
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

tang proc ; [ax] = tang[ax]
	push ax bx cx dx
	finit
	mov bx, ax
	fld dword ptr[bx]
	fptan
	fst dword ptr[bx]
	fst dword ptr[bx]
	pop dx cx bx ax
	ret
tang endp
	
toCoord proc
	push ax bx cx dx
	finit
	mov bx, ax
	fld dword ptr[bx]
	fxam
	fstsw ax
	cmp ax, 03b00h ; st(0) = infinity ; xxxx x011 ...
	jz @tcinf
	fild word ptr [zoom]
	fmul
	fild word ptr[hy]
	fsubr
	fist dword ptr[bx]
	; mov ax, word ptr [hy]
	; sub ax, word ptr[bx]
	; mov word ptr[bx], ax
	pop dx cx bx ax
	ret
@tcinf:
	mov ax, maxy ; just value that is not drawn
	mov word ptr[bx], ax
	mov word ptr[bx+2], 0
	pop dx cx bx ax
	ret
toCoord endp

fromCoord proc
	push bx
	finit
	mov bx, ax
	fild dword ptr[bx]
	fild hx
	fsub
	fild word ptr [zoom]
	fdiv
	fst dword ptr[bx]
	pop bx
	ret
fromCoord endp

findhandler proc
	push cx di
	mov cx, 4
	mov di, offset keys
	repne scasw 
	pushf
	sub di, 2
	mov ax, di
	sub ax, offset keys
	popf
	pop di cx
	ret
findhandler endp

switch proc
	push ax
	xor ax, ax
	mov al, byte ptr[cfunc]
	add ax, 2
	mov bx, offset keys
	mov cx, offset funcs
	add cx, ax
	cmp cx, bx
	jl @notswitchcycle
	xor ax, ax
@notswitchcycle:
	mov byte ptr[cfunc], al
	call draw
	pop ax
	ret
switch endp

zoomin proc
	push ax
	mov ax, zoom
	add ax, 10
	jno @zoominok
	sub ax, 10
@zoominok:
	mov zoom, ax
	call draw
	pop ax
	ret
zoomin endp

zoomout proc
	push ax
	mov ax, zoom
	sub ax, 10
	cmp ax, 0
	jg @zoomoutok
	add ax, 10
@zoomoutok:
	mov zoom, ax
	call draw
	pop ax
	ret
zoomout endp

exit proc
	; restore video mode
	mov ah, 0h
	mov al, savedMode
	int 10h
	int 20h
exit endp
end @entry
; 12h
; 640x480
; 80x30

; 13h
; 320x200
; 40x25