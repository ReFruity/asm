.model tiny
.code
org 100h
@entry:
	jmp @start
	savedMode db 0
	pausedMsg db 'Program is paused. Press any key to continue...', 0Dh, 0Ah, '$'
	incorrectMsg db 'Incorrect arguments specified. Try "ascii /v<video mode> /p<video page> [/b disables blinking]"', 0Dh, 0Ah, '$'
	marginTop db 5
	marginLeft db 0
	args db '/v', '/p'
	modesNum dw 4
	narrowModes db 0, 1, 4, 5
@start:
	; get current video mode
	mov ah, 0fh
	int 10h
	; save video mode
	mov savedMode, al
	
	call readArgs
	test ah, ah
	jz @error
	call calcMarginLeft
	; set video mode
	mov ah, 0h
	int 10h
	
	call clearscr
	call printTable
	call hideCursor
	call pause
	call exit
	ret
@error:
	lea dx, incorrectMsg
	call printMsg
	ret
	
; returns al = video mode and bh = video page from arguments
; returns if arguments are correct in ah
readArgs proc
	push cx dx si di
	xor ch, ch
	mov cl, byte ptr ds:[80h]
	cmp cl, 6
	jl @raIncorrect
	mov di, 82h
	
	call skipSpaces
	mov ax, 2
	mov si, offset args
	call compare
	test ax, ax
	jz @raIncorrect
	add di, 2
	; temporary store video mode in dl
	mov dl, byte ptr [di]
	cmp dl, '0'
	jl @raIncorrect
	cmp dl, '9'
	jg @raIncorrect
	sub dl, '0'
	inc di
	
	call skipSpaces
	mov ax, 2
	mov si, offset args + 2
	call compare
	test ax, ax
	jz @raIncorrect
	add di, 2
	; temporary store video page in dh
	mov dh, byte ptr[di]
	cmp dh, '0'
	jl @raIncorrect
	cmp dh, '9'
	jg @raIncorrect
	sub dh, '0'
	
	add cx, 80h
	cmp di, cx
	jg @raIncorrect
	
	jmp @raCorrect
@raCorrect:
	mov bh, dh
	mov al, dl
	call checkCorrectness
	jmp @raEnd
@raIncorrect:
	xor ah, ah
	jmp @raEnd
@raEnd:
	pop di si dx cx
	ret
readArgs endp
	
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

; incs di while it points to space
skipSpaces proc
@ssLoop:
	cmp byte ptr [di], ' '
	jne @ssEnd
	inc di
	jmp @ssLoop
@ssEnd:
	ret
skipSpaces endp
	
; bh = video page
printTable proc
	push ax bx cx dx
	xor ax, ax
	mov al, 0			; character to print
	mov dh, marginTop
	dec dh
	mov cl, 32			; right border of the table
	add cl, marginLeft
	dec cl				; last symbol should not be space
	mov ch, 16			; bottom border of the table
	add ch, marginTop
	mov bl, 00011100b 	; attribute = red on blue
@ptRowLoop:
	inc dh
	cmp dh, ch
	jge @ptEnd
	mov dl, marginLeft
	; only first line is red
	cmp dh, marginTop
	je @ptColumnLoop
	mov bl, 00011110b 	; attribute = yellow on blue
@ptColumnLoop:
	call writeChar
	inc al
	inc dl
	cmp dl, cl
	jge @ptRowLoop
	push ax
	mov al, ' '
	call writeChar
	pop ax
	inc dl
	jmp @ptColumnLoop
@ptEnd:
	pop dx cx bx ax
	ret
printTable endp

; (dh, dl) = (row, column), bh = page number, bl = attribute, al = char to write
writeChar proc
	push ax bx cx
	call setCursor
	mov ah, 09h
	mov cx, 1
	int	10h
	pop cx bx ax
	ret
writeChar endp

; al = video mode, bh = video page
; returns result in ah
checkCorrectness proc
	cmp al, 7
	je @ccPage0
	cmp al, 1
	jle @ccPage7
	cmp al, 3
	jle @ccPage3
	jmp @ccIncorrect
@ccPage0:
	test bh, bh
	jz @ccCorrect
	jmp @ccIncorrect
@ccPage3:
	cmp bh, 3
	jle @ccCorrect
	jmp @ccIncorrect
@ccPage7:
	cmp bh, 7
	jle @ccCorrect
	jmp @ccIncorrect
@ccCorrect:
	mov ah, 1
	jmp @ccEnd
@ccIncorrect:
	xor ah, ah
	jmp @ccEnd
@ccEnd:
	ret
checkCorrectness endp

calcMarginLeft proc
	push cx di
	mov cx, modesNum
	mov di, offset narrowModes
@cmlLoop:
	cmp byte ptr [di], al
	je @cmlNarrow
	inc di
	loop @cmlLoop
	jmp @cmlWide
@cmlWide:
	mov marginLeft, 25
	jmp @cmlEnd
@cmlNarrow:
	mov marginLeft, 5
	jmp @cmlEnd
@cmlEnd:
	pop di cx
	ret
calcMarginLeft endp

clearscr proc
	push ax bx cx dx
	mov ah, 06h
	mov al, 00h
	mov cx, 00h
	mov dh, 30
	mov dl, 80
	mov bh, 0fh 	; colour
	int 10h
	pop dx cx bx ax
	ret
clearscr endp

hideCursor proc
	push bx dx
	mov bh, 00
	mov dx, 1900h
	call setCursor
	pop dx bx
	ret
hideCursor endp

; (dh, dl) = (row, column); bh = page number
setCursor proc
	push ax
	mov ah, 02h
	int 10h
	pop ax
	ret
setCursor endp

pause proc
	push ax dx
	; set cursor position
	xor bh, bh
	; mov dx, 1700h
	; call setCursor
	; lea dx, pausedMsg
	; call printMessage
	mov ah, 0
	int 16h
	pop dx ax
	ret
pause endp

; dx = $ terminated message offset 
printMsg proc
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
printMsg endp

exit proc
	; restore video mode
	mov ah, 0h
	mov al, savedMode
	int 10h
	int 20h
exit endp
end @entry

; video mode 3h
; text 80 x 25 16 color 