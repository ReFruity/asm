.model tiny
.386
.code
org 100h
@entry:
	xor ax, ax
	div ax
	ret
end @entry