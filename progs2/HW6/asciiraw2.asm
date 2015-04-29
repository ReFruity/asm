.model tiny
.code
org 100h

@entry:             jmp      @start

arg_s                  db 0ffh
arg_m                  db 0ffh
error                  dw 0                     
incorrectMsg		   db 'Incorrect arguments specified.', 0Dh, 0Ah,  'Try "asciiraw /v<video mode> /p<video page> [/b disables blinking]"', 0Dh, 0Ah, '$'
string                 db ?
column                 db ?

second_string          db ?
second_line_color      db 0

mode_str               db 'MODE: $'
page_str               db 'PAGE: $'

@start:             call    parseArguments
                    cmp     error, 0
                    jg      @has_error
                    cmp     arg_s, 0ffh
                    jne     @no_error1010
                    mov     error, 1010h
                    jmp     @has_error
@no_error1010:      cmp     arg_m, 0ffh
                    jne     @no_error1020
                    mov     error, 1020h
                    jmp     @has_error
@no_error1020:      cmp     arg_m, 0
                    je      @arg_m_7
                    cmp     arg_m, 1
                    je      @arg_m_7
                    cmp     arg_m, 2
                    je      @arg_m_3
                    cmp     arg_m, 3
                    je      @arg_m_3
                    cmp     arg_m, 7
                    je      @arg_m_0
                    mov     error, 1011h
                    jmp     @has_error

@arg_m_7:           cmp     arg_s, 7
                    jg      @error_1021
                    jmp     @afterValidation
@arg_m_3:           cmp     arg_s, 3
                    jg      @error_1021
                    jmp     @afterValidation
@arg_m_0:           cmp     arg_s, 0
                    jg      @error_1021
                    jmp     @afterValidation

@has_error:         call    printError
                    ret

@afterValidation:   call    setMode
                    call    printLegend
                    call    printAscii
                    call    setVideoPage
                    call    waitKeyPressed                 
                    ret

@error_1021:        mov     error, 1021h
                    jmp     @has_error

waitKeyPressed proc
                    xor    ax, ax
                    int    16h
                    xor    ax, ax
                    mov    al, 3
                    int    10h
                    ret
waitKeyPressed endp

printLegendString proc                                 ; bx - offset
                                                       ; cx - length
                                                       ; ax - coords
                                                       ; dl - value
                                                       ; dh - text attributes
                    push ax bx cx
                    push dx
@pLCycle:           mov  dl, byte ptr [bx]
                    inc  bx
                    call printChar
                    inc  ah
                    loop @pLCycle
                    pop  dx
                    call printChar
                    pop  cx bx ax
                    ret
printLegendString endp

printLegend proc
                    push ax bx cx dx
                    
                    mov  dh, 00000111b
                    mov  al, string
                    sub  al, 2
                    mov  ah, column
                    lea  bx, mode_str
                    mov  cx, 6h
                    mov  dl, arg_m
                    add  dl, '0'
                    call printLegendString

                    mov  al, string
                    sub  al, 1
                    lea  bx, page_str
                    mov  cx, 6h
                    mov  dl, arg_s
                    add  dl, '0'
                    call printLegendString

                    pop  dx cx bx ax
                    ret
printLegend endp

printAscii proc
                    push ax bx cx dx si di
                    mov  al, string
                    mov  ah, column
                    xor  dl, dl
                    mov  cl, arg_s
                    mov  si, 256
                    xor  di, di

@cloop:             cmp  al, string
                    jne  @pAnotBlink
                    cmp  di, 0                         ; first string
                    je   @pAnotBlink
                    call printBlueGreenBlinkChar
                    xor  di, di
                    jmp  @pAnotBlinkAfter

@pAnotBlink:        cmp  al, second_string
                    jne  @pAnotSecond

                    mov  dh, 00100000b                 ; second string
                    add  dh, second_line_color
                    inc  second_line_color
                    call printChar
                    jmp  @pAnotBlinkAfter

@pAnotSecond:       call printBlueGreenChar
                    mov  di, 1

@pAnotBlinkAfter:   inc  ah
                    push dx
                    mov  dl, 20h
                    call printBlueGreenChar
                    pop  dx

                    inc  dl
                    inc  ah
                    test dl, 0Fh
                    jnz  @continue_loop

                    mov  ah, column
                    inc  al

@continue_loop:     dec  si      
                    jnz  @cloop
                    pop di si dx cx bx ax
                    ret     
printAscii endp

setVideoPage proc
                    mov ah, 05h
                    mov al, arg_s
                    int 10h
                    ret
setVideoPage endp

printBlueGreenChar proc
                    push    dx
                    mov     dh, 00100001b
                    cmp     arg_m, 7
                    jne     @pRBtmp
                    mov     dh, 00101101b
@pRBtmp:            call    printChar
                    pop     dx
                    ret
printBlueGreenChar endp

printBlueGreenBlinkChar proc
                    push    dx
                    mov     dh, 10100001b
                    cmp     arg_m, 7
                    jne     @pRBBtmp
                    mov     dh, 10101101b
@pRBBtmp:            
					call    printChar
                    pop     dx
                    ret
printBlueGreenBlinkChar endp

printChar proc                                  ; ah, al - horizontal and vertical 
                                                ; coordinates respectively
                                                ; dl - ascii code
                    push cx                     ; dh - char attributes
                    mov cl, arg_s               ; cl - Page number (starting from 0)
                    push es di
                    call getBufferStart
                    call getCharAddr
                    mov  es:[di], dx            ; putting char with attributes to memory
                    pop  di es cx
                    ret
printChar endp

getCharAddr proc
                    push ax cx dx
                    mov  ch, ah
                    xor  ah, ah
                    inc  al
                    mov  dx, ax
                    call getColumnsCount
                    mul  dx

                    push cx
                    mov  cl, ch
                    xor  ch, ch
                    add  ax, cx
                    pop  cx


                    shl  ax, 1                  ; * 2
                    sub  ax, 2                  ; Moving offset to the beginning 
                                                ; of the word
                    mov  di, ax                 ; Offset to di
                    call getPageSize
                    xor  ch, ch 
                    mul  cx                     ; calculate page offset

                    add  di, ax
                    pop  dx cx ax
                    ret
getCharAddr ENDP

getBufferStart proc
                    push ax
                    cmp  arg_m, 7h
                    jne  @gBSNotSeven
                    mov  ax, 0B000h
                    jmp  @gBSafter
@gBSNotSeven:       mov  ax, 0B800h
@gBSafter:          push ax
                    pop  es ax
                    ret
getBufferStart endp

getPageSize proc
                    push es
                    push 0h
                    pop  es
                    mov  ax, es:[44Ch]
                    pop es
                    ret
getPageSize endp

getColumnsCount proc
                    push es
                    push 0h
                    pop  es
                    mov ax, es:[44Ah]
                    pop es
                    ret
getColumnsCount endp

printSpace proc
                    push    ax
                    mov     al, 32
                    call    printBlueGreenChar
                    pop     ax
                    ret
printSpace endp

setMode proc
                    push    ax
                    mov     string, 4
                    mov     al, string
                    mov     second_string, al
                    inc     second_string
                    
                    cmp     arg_m, 2
                    jl      @sMMode1
                    mov     column, 24
                    jmp     @sMAfterMode
@sMMode1:           mov     column, 4

@sMAfterMode:       mov     al, arg_m                                   
                    mov     ah, 0
                    int     10h
                    pop     ax
                    ret
setMode endp



printError proc
                    push    dx
                    lea     dx, incorrectMsg
                    call    printString
                    
                    ; mov     ax, error
                    ; call    printNumber

                    pop     dx
                    ret
printError endp

printString proc
                    mov    ah, 09h
                    int    21h
                    ret
printString endp

printLine proc
                    push   ax dx
                    mov    dl, 10
                    mov    ah, 02h
                    int    21h
                    mov    dl, 13
                    int    21h
                    pop    dx ax
                    ret
printLine endp

printNumber proc                                ; prints hex number from ax
                    push   ax bx cx dx
                    xor    cx, cx
                    xor    dx, dx
                    mov    bx, 10h
@pNCount:           div    bx
                    push   dx
                    inc    cx
                    xor    dx, dx
                    test   ax, ax
                    jnz    @pNCount

                    mov    ah, 02h
                    mov    bx, cx
                    mov    cx, 4
                    sub    cx, bx
                    mov    dl, '0'
@pNZeroes:          test   cx, cx
                    jz     @pNPrintBefore
                    int    21h
                    loop   @pNZeroes

@pNPrintBefore:     mov    cx, bx
@pNPrint:           pop    dx
                    mov    dh, 0
                    cmp    dx, 9
                    jg     @pNSymbol
                    add    dl, '0'
                    jmp    @pNAfter
@pNSymbol:          add    dl, 55
                    jmp    @pNAfter
@pNAfter:           int    21h
                    loop   @pNPrint

                    pop    dx cx bx ax
                    ret
printNumber endp

parseArguments proc                             ; cx - how many symbols 
                                                ; left in the main loop
                                                ; ax - the current state
                    push    bx cx dx si
                    xor     cx, cx
                    xor     ax, ax
                    mov     cl, ds:[80h]
                    mov     bx, 81h
                    add     bx, cx
                    inc     cx
                    jmp     @pArgLoopStart

@pArgLoop:     
                    mov     si, bx              ; going by current symbol
                    sub     si, cx
                    mov     dl, [si]            ; go to the next state
                    cmp     dl, '/'             ; / - 1
                    je      @pArgSymbolSl       ; /s - 10 /s+SPACe - 11
                    cmp     dl, 's'             ; /s NUMBER - 12
                    je      @pArgSymbols        ; /w - 20 /w+SPACE - 21
                    cmp     dl, 'S'             ; /w NUMBER - 22
                    je      @pArgSymbols
                    cmp     dl, 'm'
                    je      @pArgSymbolm
                    cmp     dl, 'M'
                    je      @pArgSymbolm
                    cmp     dl, ' '
                    je      @pArgSymbolSpace
                    cmp     dl, 30h
                    jl      @pArgError
                    cmp     dl, 39h
                    jg      @pArgError
                    jmp     @pArgSymbolN

@pArgLoopStart:     loop    @pArgLoop
                    pop     si dx cx bx
                    ret

@pArgSymbolSl:      mov     ax, 1                ; changing state
                    jmp     @pArgLoopStart

@pArgSymbols:       cmp     ax, 1
                    jne     @pArgClear
                    mov     ax, 10
                    je      @pArgLoopStart

@pArgSymbolm:       cmp     ax, 1
                    jne     @pArgClear
                    mov     ax, 20
                    je      @pArgLoopStart

@pArgSymbolSpace:   cmp     ax, 11
                    je      @pArgLoopStart
                    cmp     ax, 21
                    je      @pArgLoopStart
                    cmp     ax, 10
                    jne     @pArgSymbolSpaceM
                    mov     ax, 11
                    je      @pArgLoopStart
@pArgSymbolSpaceM:  cmp     ax, 20
                    jne     @pArgClear
                    mov     ax, 21
                    je      @pArgLoopStart

@pArgSymbolN:       cmp     ax, 11
                    jne     @pArgSymbolN21
                    mov     arg_s, dl
                    mov     ax, 12
                    sub     arg_s, '0'
                    jmp     @pArgLoopStart
@pArgSymbolN21:     cmp     ax, 21
                    jne     @pArgError
                    mov     ax, 22
                    mov     arg_m, dl
                    sub     arg_m, '0'
                    jmp     @pArgLoopStart

@pArgError:         mov     error, 1001h

@pArgClear:         xor     ax, ax
                    jmp     @pArgLoopStart
parseArguments endp

end @entry