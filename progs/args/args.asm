.model tiny
.code
org 100h
@entry:
	mov bx, 80h ; Test if empty
	mov bx, [bx]
	mov bh, 00h
	cmp bx, 00h
	je @endprog
	mov ah, 02h ; Character output
	mov cx, 00h
@loop:
	add cx, 82h ; Points to the next char
	mov bx, cx
	mov dl, [bx] 
	int 21h
	inc cx
	sub cx, 82h ; Shows the number of printed chars
	mov bx, 80h
	mov bx, [bx]
	mov bh, 00h ; Shows the tail length
	cmp cx, bx
	jl @loop
@endprog:
	ret
end @entry