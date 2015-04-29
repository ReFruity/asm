.model tiny
.code
org 100h
@entry:
        jmp @start
		
		id dw 0BEEFh
		msg db "I'm custom interrupt handler!", 0Dh, 0Ah, '$'
		nextVector dw ?, ?
		
; if ax = 03C7h; dx = 1111h => return ax = 0 (already resident) else if dx = 2222h => return es bx of old vector
handler proc
        push bx cx dx ds
		cmp ax, 03c7h
		jne @hSound
		cmp dx, 1111h
		jne @hNextVec
		; already resident, return 0
		pop ds dx cx bx
		xor ax, ax
		iret 
@hNextVec:
		cmp dx, 2222h
		jne @hSound
		; return es bx of the next vector
		pop ds dx cx bx
		mov es, word ptr cs:[nextVector+2]
		mov bx, word ptr cs:[nextVector]
		iret
@hSound:
        call playSound
        pop ds dx cx bx
        push word ptr cs:[nextVector+2]		; segment
        push word ptr cs:[nextVector]		; offset
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

playSound proc
	push 	ax bx cx
	mov     al, 182         ; Prepare the speaker for the
	out     43h, al         ;  note.
	mov     ax, 4560        ; Frequency number (in decimal)
							;  for middle C.
	out     42h, al         ; Output low byte.
	mov     al, ah          ; Output high byte.
	out     42h, al 
	in      al, 61h         ; Turn on note (get value from
							;  port 61h).
	or      al, 00000011b   ; Set bits 1 and 0.
	out     61h, al         ; Send new value.
	mov     bx, 25          ; Pause for duration of note.
@pause1:
	mov     cx, 10000		; Duration
@pause2:
	dec     cx
	jne     @pause2
	dec     bx
	jne     @pause1
	in      al, 61h         ; Turn off note (get value from
							;  port 61h).
	and     al, 11111100b   ; Reset bits 1 and 0.
	out     61h, al         ; Send new value.
	pop 	cx bx ax
	ret
playSound endp

@dataStart:
        msgAbort db "Custom interrupt handler is already installed! Aborting.", 0Dh, 0Ah, '$'
		oldMsg db 'Old vector es bx: $'
		newMsg db 'New vector es bx: $'
		invalidMsg db 'Invalid arguments! Try /h$'
		helpMsg db '/s - installs custom interrupt handler', 0Dh, 0Ah, '/r - removes it safe way', 0Dh, 0Ah, '/x - removes it unconditionally$'
		removedMsg db 'Custom interrupt handler was removed.$'
		notRemovedMsg db 'Cannot remove handler, not installed.$'
		destroyedMsg db 'Resident was removed without any sanity check.$'
		nextVectorAddress dw offset nextVector
		argsNum dw 4
		args db '/s', '/r', '/h', '/x'
		intNum db 09h
		
@start:
		call readArgs
		cmp ax, 1
		je @check
		cmp ax, 2
		je @remove
		cmp ax, 3
		je @help
		cmp ax, 4
		je @destroyed
		; invalid arguments
		lea dx, invalidMsg
		call printMsg
		ret
		
@help:
		lea dx, helpMsg
		call printMsg
		ret
		
@remove:
		mov al, intNum
		call checkVector
		test ax, ax
		jnz @removeFail
		
		mov al, intNum
		call canBeRemoved
		test ax, ax
		jz @removeFail
		
@removeSuccess:
		lea dx, oldMsg
		call printMsg
		mov al, intNum
		call getVectorAddress
		call printInfo
		call printNewLine
		mov al, intNum
		call removeVector
		lea dx, removedMsg
		call printMsg
		ret
@removeFail:
		lea dx, notRemovedMsg
		call printMsg
		ret
		
@destroyed:
		lea dx, destroyedMsg
		call printMsg
		mov al, intNum
		call removeVector
		ret
		
@check:
		; check if already resident
		call checkVector
		test ax, ax
		jnz @install
		
        lea dx, msgAbort
		call printMsg
		ret

@install:
        mov al, intNum
		call saveVector
       
        ; printing old vector es:bx
		lea dx, oldMsg
		call printMsg
		call printInfo
       
        ; set new vector
        mov al, intNum
        lea bx, handler
		push cs 
		pop es
        call setVectorAddress
       
	    ; printing new vector es:bx
		call printNewLine
		lea dx, newMsg
		call printMsg
		mov al, intNum
		call getVectorAddress
		call printInfo
	   
        ; TSR
		mov ax, offset @dataStart
		call stayResident

; al = interrupt number
; returns 0 in ax if resident, 03C7h if not
checkVector proc
		push dx cx
		mov ax, 03C7h
		mov dx, 1111h
		int 09h
		pop cx dx
		ret
checkVector endp

; al = vector number
; returns result in ax
canBeRemoved proc
		push es bx
		call getVectorAddress
		mov bx, es:id
		cmp bx, 0BEEFh
		je @cbrTrue
		xor ax, ax
		jmp @cbrEnd
@cbrTrue:
		mov ax, 1
@cbrEnd:
		pop bx es
		ret
canBeRemoved endp

; al = vector number
; returns es bx of next vector
getNextVector proc
		push ax cx dx
		mov ax, 03C7h
		mov dx, 2222h
		int 09h
		pop dx cx ax
		ret
getNextVector endp

; al = vector number
removeVector proc
		push ax bx es
		call getVectorAddress
		call clearMemory
		
		; es = next vector segment, bx = offset
		call getNextVector
		call setVectorAddress

		pop es bx ax
		ret
removeVector endp

; es - segment to release with it's variables memory block
; returns ax - error code
clearMemory proc
		mov ah, 49h		
		push es
		mov es, es:[2Ch]
		int 21h
		mov ah, 49h
		pop es
		int 21h
		ret
clearMemory endp

; al = vector number, es = vector segment, bx = vector offset
setVectorAddress proc
		push ax cx ds di
		push 0
		pop ds
		xor ah, ah
		mov cl, 4
		mul cl
		mov di, ax
		cli
		mov ds:[di], bx
		mov ds:[di+2], es
		sti
		pop di ds cx ax
		ret
setVectorAddress endp

; al = vector number 
; returns es bx
getVectorAddress proc
		push ax si ds
		push 0
		pop ds
		xor ah, ah
		mov bl, 4
		mul bl
		mov si, ax
		cli
		mov bx, ds:[si]
		push ds:[si+2]
		pop es
		sti
		pop ds si ax
		ret
getVectorAddress endp
	
; al = vector number
saveVector proc  
		call getVectorAddress
        mov [nextVector], bx
        mov [nextVector+2], es     
		ret
saveVector endp  

; ax = offset at which next program can be loaded
stayResident proc
		mov dl, 4
		div dl
		xor ah, ah
		mov dx, ax
		inc dx
		mov ah, 31h
        xor al, al
        int 21h
stayResident endp

; READING

; returns ax = 0, if args are invalid, otherwise number of arg
readArgs proc
		push cx si di
		
		mov cx, ds:[80h]
		xor ch, ch
		cmp cx, 3
		jl @rasInvalid
		
		mov cx, argsNum
@rasLoop:
		mov ax, argsNum
		sub ax, cx
		inc ax
		push ax
		call readArg
		test ax, ax
		pop ax
		jnz @rasEnd
		loop @rasLoop
		
@rasInvalid:
		xor ax, ax				; invalid arg
		jmp @rasEnd
@rasEnd:
		pop di si cx
		ret
readArgs endp

; ax = argument number
; returns search result in ax
readArg proc
		push bx cx di
		mov cx, ds:[80h]
		xor ch, ch
		sub cx, 2
		
		mov di, offset args
		dec ax
		mov bl, 2
		mul bl
		add di, ax
		
		mov si, 82h
@raLoop:
		mov ax, 2
		call compare
		test ax, ax
		jnz @raSuccess
		inc si
		loop @raLoop
		jmp @raFailure
@raSuccess:
		mov ax, 1
		jmp @raEnd
@raFailure:
		xor ax, ax
@raEnd:
		pop di cx bx
		ret
readArg endp

; compares string starting at address si with string at address di, length of ax
; returns compare result in ax
compare proc
	push cx si di
	mov cx, ax
	rep cmpsb
	jne @cNequal
	mov ax, 1h
	jmp @cEnd
@cNequal:
	xor ax, ax
@cEnd:
	pop di si cx
	ret
compare endp

; PRINTING
	 
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