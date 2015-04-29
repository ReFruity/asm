.model tiny
.code
org 100h
@entry:
        jmp @start
        msg db "I'm custom interrupt handler from homework 2!", 0Dh, 0Ah, '$'
        msg2 db "Custom interrupt handler is already installed! Aborting.", 0Dh, 0Ah, '$'
		oldMsg db 'Old vector es bx: $'
		newMsg db 'New vector es bx: $'
        nextVector dw ?, ?
@start:
		; check if already resident
		mov ax, 03c7h
		mov dx, 3333h
		int 2fh
		test ax, ax
		jnz @install
		mov ah, 09h
        lea dx, msg2
        int 21h
		ret

@install:
        ; save old vector
        mov ah, 35h
        mov al, 2Fh
        int 21h
        mov [nextVector], bx
        mov [nextVector + 2], es       
       
        ; printing old vector es:bx
		lea dx, oldMsg
		call printMsg
		call printInfo
       
        ; set new vector
        mov ah, 25h
        mov al, 2Fh
        lea dx, handler
        int 21h
       
	    ; printing new vector es:bx
		call printNewLine
		lea dx, newMsg
		call printMsg
		mov ah, 35h
		mov al, 2Fh
		int 21h
		call printInfo
	   
        ; TSR
        mov ah, 31h
        xor al, al
        mov dx, 0FFh                   
        int 21h
       
handler proc
        push ax bx cx dx ds
		cmp ax, 03c7h
		jne @hMsg
		cmp dx, 3333
		jne @hMsg
		; already resident, return 0
		pop ds dx cx bx ax
		xor ax, ax
		iret 
@hMsg:
        mov ah, 09h
		push cs
        pop ds
        lea dx, msg
        int 21h
        pop ds dx cx bx ax
        push word ptr [cs:nextVector + 2] ; segment
        push word ptr [cs:nextVector]     ; offset
        retf
handler endp

; dx = $ terminated message offset 
printMsg proc
		push ax
		mov ah, 09h
		int 21h
		pop ax
		ret
printMsg endp
       
printInfo proc
		push ax
		mov ax, es                             
        call printHexNumber
        call printSpace
        mov ax, bx
        call printHexNumber
		pop ax
		ret
printInfo endp
	   
printSpace proc
        push ax dx
        mov ah, 02h
        mov dl, ' '
        int 21h
        pop dx ax
        ret
printSpace endp

printNewLine proc
        push ax dx
        mov ah, 02h
        mov dl, 0Dh
        int 21h
		mov dl, 0Ah
		int 21h
        pop dx ax
        ret
printNewLine endp
 
printHexNumber proc
        push bx cx dx
        mov bx, ax                         ; arg
        mov cx, 4
@k:            
        rol bx, 4                          ; 4 left bits to the right
        mov al, bl
        and al, 0Fh
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