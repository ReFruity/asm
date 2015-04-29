.model tiny
.code
org 100h
@entry: jmp @start
	string db 'abcdef'
	strend dw 20h
@start:
	mov cl, ds:[80h]
	dec cx
	mov si, 82h
	mov di, offset string
	mov ax, offset strend
	sub ax, di
	cmp ax, cx
	jne @nequal
@loop:
	lodsb
	cmp al, byte ptr [di]
	jne @nequal
	inc di
	loop @loop
@equal:
	mov dl, '1'
	call print
	ret
@nequal:
	mov dl, '0'
	call print
	ret
print proc ; print dl
	push ax
	mov ah, 02h
	int 21h
	pop ax
	ret
print endp
end @entry