model tiny
.code
org 100h

entry: 
	jmp start
	mymsg db 'Press any key$'
	old_08_seg dw 0
	old_08_off dw 0
	index dw 0
	m dw 0
	tt db 100
	tone dw 0
	oldSegment 		dw 0
	oldOffset 		dw 0

	delay dw 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4
	chast dw 262, 440, 440, 392, 440, 349, 262, 262, 262, 440, 440, 466, 392, 523, 523, 523, 294, 294, 466, 466, 440, 392, 349, 262, 440, 440, 392, 440, 349;частоты

start:
	call saveOld09
	;-----замена прерывания от таймера------
	call setNew09

	mov ah,9h
	lea dx,mymsg
	int 21h
	xor ah,ah ;ждём нажатия клавиши, пока не нажата, играет музыка
	int 16h

	;------восстанавливаю вектор прерывания от таймера------
	call setOld09

	;-----выключение динамика------
	in al,61h
	and al,11111100b
	out 61h,al

	mov ax,4c00h ;выход в ДОС
	int 21h


IsrTimer proc ;обработчик прерывания от таймера
	push ax si ds dx

    push cs
    pop ds    

    inc m    
    cmp index,58
    jl TimerMet1
    mov index,0 ;обнуление счётчика
TimerMet1:    
    lea si,delay
    add si,index
    mov cx,[si]    
    cmp m,cx
    jl TimerMet2
	pop ds    
    mov al,10110110b
    out 43h,al

    in al,61h
    or al,00000011b
    out 61h,al
	push ds
	push cs
	pop ds
    xor dx,dx    
    lea si,chast
    add si,index
    mov ax,[si]
    mov tone,ax    
    mov ax,11900
    div tone
    mul tt

    out 42h,al
    mov al,ah
    out 42h,al
    mov m,0    
    add index,2
TimerMet2:    
    
    ;inc m            
    mov al,20h ;разрешить другие прерывания
	out 20h, al

	pop dx ds si ax

	iret
IsrTimer endp

saveOld09 proc
				mov  ah, 35h
				mov  al, 08h
				int  21h
				mov  oldSegment, es
				mov  oldOffset, bx
				ret
saveOld09 endp

setNew09 proc
				mov  ah, 25h
				mov  al, 08h
				mov  dx, offset IsrTimer
				int  21h
				ret
setNew09 endp

setOld09 proc
				mov  ax, 2508h
				mov  dx, oldOffset
				push ds
				mov  ds, oldSegment
				int  21h
				pop  ds
				ret
setOld09 endp

; code ends
end entry