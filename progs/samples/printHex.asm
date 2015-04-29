.model tiny
.code
org 100h
@entry:
mov ax, 4C3Bh
call printHexNumber
ret
printHexNumber proc
        push bx cx dx
        mov bx, ax ; arg
        mov cx, 4
@k:		  rol bx, 4 ; 4 left bits to the right
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