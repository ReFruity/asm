.model tiny
.code
.386
org 100h
@entry:
        jmp @start
        msg db "I'm custom interrupt handler!", 0Dh, 0Ah, '$'
        nextVector dw ?, ?
@start:
        ; save old vector
		call saveOldVector
       
        ; printing info
        mov ax, es                             
        call printHexNumber
        call printSpace
        mov ax, bx
        call printHexNumber
       
        ; set new vector
		call setNewVector
       
        ; TSR
        call stayResident
       
handler proc
        push ax bx cx dx ds cs
        mov ah, 09h
        ; push ds cs
        pop ds
        lea dx, msg
        int 21h
        pop ds dx cx bx ax
        push word ptr [cs:nextVector + 2] ; segment
        push word ptr [cs:nextVector]     ; offset
        retf
handler endp

saveOldVector proc
		push ax
		mov ah, 35h
        mov al, 2Fh
        int 21h
        mov [nextVector], bx
        mov [nextVector + 2], es      
		pop ax
		ret
saveOldVector endp
 
setNewVector proc
		push ax dx
		mov ah, 25h
        mov al, 2Fh
        lea dx, handler
        int 21h
		pop dx ax
		ret
setNewVector endp
 
stayResident proc
		mov ah, 31h
        xor al, al
        mov dx, 0FFh                   
        int 21h
stayResident endp
 
printSpace proc
        push ax dx
        mov ah, 02h
        mov dl, ' '
        int 21h
        pop dx ax
        ret
printSpace endp
 
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