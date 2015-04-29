.model tiny
.code
org 100h
@entry:
	mov ax, 1h
	mov bx, 2h
@loop:
	xor ax, ax
	je @loop
	ret
end @entry