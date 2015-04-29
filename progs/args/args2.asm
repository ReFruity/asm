.model tiny
.code
org 100h
@entry:
	mov bl, ds:80h ; Test if empty
	cmp bx, 00h
	mov ah, 02h ; Character output
	mov cx, bx ; Set the counter
	dec cx
@loop:
	mov bl, ds:80h
	sub bx, cx
	add bx, 81h
	mov dl, [bx]
	int 21h
	loop @loop
	ret
end @entry