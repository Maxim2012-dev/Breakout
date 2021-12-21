; -------------------------------------------------------------------
; 80386
; 32-bit x86 assembly language
; TASM
;
; author:	Maxim Brabants, Alexandre Fernandes Medeiros
; date:		
; program:	Breakout game
; -------------------------------------------------------------------

IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

INCLUDE "global.asm"
INCLUDE "keyb.inc"		; library custom keyboard handler

; -------------------------------------------------------------------
; CODE
; -------------------------------------------------------------------
CODESEG

; # TODO LIJST #
; - extra veld ball zodat deze in het begin met de paddle beweegt
; - 

; video mode aanpassen
PROC setVideoMode
	ARG @@VM:byte
	USES eax

	movzx ax,[@@VM] ; movzx = move zero extend
	int 10h

	ret
ENDP setVideoMode

; programma beïndigen
PROC terminateProcess
	USES eax
	call setVideoMode, 03h
	mov	ax,04C00h
	int 21h
	ret
ENDP terminateProcess

; Wait for a specific keystroke.
PROC waitForSpecificKeystroke
	ARG 	@@key:byte
	USES 	eax

@@waitForKeystroke:
	mov	ah,00h
	int	16h
	cmp	al,[@@key]
	jne	@@waitForKeystroke

	ret
ENDP waitForSpecificKeystroke

; wait for @@framecount frames
PROC wait_VBLANK
	USES eax, edx
	mov dx, 03dah ; Wait for screen refresh
	
@@VBlank_phase1: ; wait for end
	in al, dx 
	and al, 8
	jnz @@VBlank_phase1
@@VBlank_phase2: ; wait for begin
	in al, dx 
	and al, 8
	jz @@VBlank_phase2
	
	ret 
ENDP wait_VBLANK

PROC openFile ; de offset van een variabele neemt 32 bits in beslag
	ARG	@@file:dword ; @@file ==> adres van bestandsnaam/verwijzing naar nodige bestand in DATASEG
	USES eax, ecx, edx
	mov al, 0 ; read only
	mov edx, [@@file] ; adres van bestandsnaam/verwijzing naar bestand in edx stoppen, register gebruikt voor I/O operaties
	mov ah, 3dh ; mode om een bestand te openen
	int 21h
	
	jnc @@no_error ; carry flag is set if error occurs, indien de CF dus niet geactieveerd is, is er geen error en springt men naar de no_error label

	; Print string.
	call setVideoMode, 03h ; plaatst mode weer in text mode 
	mov  ah, 09h ; om een string te kunnen printen
	mov  edx, offset openErrorMsg ; string die geprint moet worden
	int  21h
	
	; wacht op het indrukken van een toets en geeft terug welke deze is, maar dat is niet van belang, daar wordt niets mee gedaan, VRAAG: WAAROM WACHT DIT EIGENLIJK OP EEN TOETS INVOER? IK MOET TOCH NIET OP EEN TOETS DRUKKEN.
	mov	 ah, 00h
	int	 16h
	call terminateProcess ; proces beïndigen aangezien er een error was
	
@@no_error:
	mov [filehandle], ax ; INT 21h (AH=3Dh) zal in AX de filehandle teruggeven, variabele "filehandle" herbruiken voor de verschillende bestanden 
	ret
ENDP openFile

PROC closeFile
	USES eax, ebx, ecx, edx ; VRAAG: REGISTER ECX TOCH NIET NODIG? (WANT DEZE WORDT GEPRESERVED IN DANCER)
	mov bx, [filehandle]
	mov ah, 3Eh ; mode om een bestand te sluiten
	int 21h
	
	jnc @@no_error ; carry flag is set if error occurs

	call setVideoMode, 03h
	mov  ah, 09h
	mov  edx, offset closeErrorMsg
	int  21h
	
	mov	ah,00h
	int	16h
	call terminateProcess
	
@@no_error:
	ret
ENDP closeFile

PROC readChunk
	ARG @@sprite_size:word, @@arrayptr:dword ; @@sprite_size ==> getal die overeenkomt met aantal pixels van sprite, @@arrayptr ==> adres van array die de indices van de nodige kleuren voor elke pixel zal bijhouden
	USES eax, ebx, ecx, edx
	mov bx, [filehandle]
	mov cx, [@@sprite_size]
	mov edx, [@@arrayptr] 
	mov ah, 3fh								
	int 21h
	
	jnc @@no_error  	
	
	call setVideoMode, 03h
	mov  ah, 09h
	mov  edx, offset readErrorMsg
	int  21h
	
	mov	ah,00h
	int	16h
	call terminateProcess
	
@@no_error:
	ret
ENDP readChunk

; Fill the background (for mode 13h)
; (faster, uses stosd optimization)
PROC fillBackground
	ARG @@fillcolor:byte ; input color, index van kleur in kleurenpalet
	USES eax, ecx, edi

	; Initialize video memory address.
	mov	edi, VIDMEMADR
	
	; copy color value across all bytes of eax
	mov al, [@@fillcolor]	; ???B
	mov ah, al				; ??BB
	mov cx, ax			
	shl eax, 16				; BB00
	mov ax, cx				; BBBB

	; Scan the whole video memory and assign the background colour.
	mov	ecx, SCRWIDTH*SCRHEIGHT/4 ; delen door 4 omdat we in elke iteratie 4 pixels vullen
	rep	stosd ; Fill (E)CX doublewords at ES:[(E)DI] with EAX

	ret
ENDP fillBackground

STRUC Ball
	x			db 0 ; (in cellen)
	y			db 0
	breadth		db BALLWIDTH/CELLWIDTH ; (in cellen)
	height		db BALLHEIGHT/CELLHEIGHT
	active		db 0
	x_sense		db 0
	y_sense		db 0
ENDS Ball

STRUC Paddle
	x 			db 0
	y 			db 0
	breadth 	db PADDLEWIDTH/CELLWIDTH ; aangezien width een keyword is, gebruiken we breadth
	height 		db PADDLEHEIGHT/CELLHEIGHT
	health 		db 3 
ENDS Paddle

STRUC Stone
	index_position 	db 0		; index in grid
	breadth			db STONEWIDTH/CELLWIDTH
	height			db STONEHEIGHT/CELLHEIGHT
ENDS Stone	 

PROC movePaddleLeft
	USES eax, ebx
	mov ebx, offset paddle_object
	movzx eax, [ebx + Paddle.x]
	dec eax ; MISSCHIEN NOG VERBETEREN
	cmp eax, 0
	jl @@end
	mov [ebx + Paddle.x], al
@@end:
	ret
ENDP movePaddleLeft	

PROC movePaddleRight
	USES eax, ebx, ecx, edx
	mov ebx, offset paddle_object
	mov eax, SCRWIDTH
	sub eax, PADDLEWIDTH
	mov ecx, CELLWIDTH
	xor edx, edx
	div ecx
	movzx ecx, [ebx + Paddle.x]
	inc ecx
	cmp ecx, eax
	jg @@end
	mov [ebx + Paddle.x], cl
@@end:
	ret
ENDP movePaddleRight

; PROC movePaddleRight
	; USES eax, ebx, edx
	; mov ebx, offset paddle_object
	; movzx eax, [ebx + Paddle.x]
	; mov edx, SCRWIDTH
	; sub edx, PADDLEWIDTH
	; div edx, CELLWIDTH
	; inc eax
	; cmp eax, edx
	; jg @@end
	; mov [ebx + Paddle.x], al
	; @@end:
	; ret
; ENDP movePaddleRight

;; SPELLOGICA
PROC gamelogistic
	USES eax

	mov al, [offset __keyb_keyboardState + 4Dh]		; state van rechterpijl bijhouden
	cmp al, 1
	je @@moveRight
		
	mov al, [offset __keyb_keyboardState + 4Bh]		; state van linkerpijl bijhouden
	cmp al, 1
	je @@moveLeft
	
	jmp @@end
		
@@moveRight:
	call movePaddleRight
	jmp @@end
		
@@moveLeft:
	call movePaddleLeft
	
@@end:
	ret
ENDP gamelogistic 

; ; Generische tekenprocedure die struct verwacht
PROC drawObject
	ARG @@XPOS:byte, @@YPOS:byte, @@SPRITE:dword, @@WIDTH:byte, @@HEIGHT:byte	; x en y coördinaat in cellen, breedte en hoogte in pixels
	USES eax, ebx, ecx, edx, esi, edi ; MOGELIJKE VERBETERING EDX WORDT SOWIESO GEBRUIKT DOOR MUL, MAAR DOOR NIETS ANDERS DUS MISSCHIEN EEN ANDERE REGISTER DOOR DEZE VERVANGEN ZODAT IK ÉÉN REGISTER MINDER GEBRUIK
	mov edi, VIDMEMADR
	mov esi, [@@SPRITE]
	; begin: positie van eerste pixel op scherm bepalen (omzetting van cellen naar pixels, x en y hebben als "eenheid" cellen)
	movzx eax, [@@YPOS]
	mov ebx, CELLHEIGHT*SCRWIDTH
	mul ebx
	mov ebx, eax
	movzx eax, [@@XPOS]
	mov ecx, CELLWIDTH 
	mul ecx
	add eax, ebx
	add edi, eax
	; einde
	mov eax, SCRWIDTH
	movzx ebx, [@@WIDTH]
	sub eax, ebx 					; eax in row_loop gebruikt om naar de volgende rij te gaan in het videogeheugen
	movzx ebx, [@@HEIGHT] 			; ebx bepaalt in de volgende loop hoeveel keer we nog moeten itereren
	
@@row_loop:						; voor alle rijen in sprite	
	movzx ecx, [@@WIDTH]		; aantal bytes/kleurindexen voor 'rep movsb'
	rep movsb					; bytes/kleurindexen van huidige rij in sprite kopiëren naar videogeheugen
	add edi, eax				; naar volgende rij gaan in videogeheugen
	dec ebx
	jnz @@row_loop
		
	ret
ENDP drawObject

PROC drawBall
	USES eax, ebx
	mov ebx, offset ball_object
	movzx eax, [ebx + Ball.x]
	movzx ebx, [ebx + Ball.y]
	call drawObject, eax, ebx, offset ball_array, BALLWIDTH, BALLHEIGHT
	ret
ENDP drawBall

PROC drawPaddle
	USES eax, ebx
	mov ebx, offset paddle_object
	movzx eax, [ebx + Paddle.x]
	movzx ebx, [ebx + Paddle.y]
	call drawObject, eax, ebx, offset paddle_array, PADDLEWIDTH, PADDLEHEIGHT
	ret
ENDP drawPaddle

PROC drawStones

	ret
ENDP drawStones
	
PROC drawlogistic
	call drawBall
	call drawPaddle
	ret
ENDP drawlogistic

PROC main
	sti
	cld
	
	push ds
	pop	es           

	call setVideoMode, 13h
	call fillBackground, 0
	
	call __keyb_installKeyboardHandler
	
	call openFile, offset ball_file
	call readChunk, BALLSIZE, offset ball_array
	call closeFile
	
	call openFile, offset paddle_file
	call readChunk, PADDLESIZE, offset paddle_array
	call closeFile
	
	call openFile, offset bstone_file
	call readChunk, STONESIZE, offset bstone_array
	call closeFile
	
	call openFile, offset gstone_file
	call readChunk, STONESIZE, offset gstone_array
	call closeFile
	
	call openFile, offset rstone_file
	call readChunk, STONESIZE, offset rstone_array
	call closeFile
	
	call drawlogistic
	
	; Handmatig loop maken, we kennen bijvoorbeeld aan eax waarde 1 toe juist voor onze loop.
	; We blijven iteren zolang eax niet gelijk is aan 0 (jump if not zero).
	; De procedure gamelogistic geeft bijvoorbeeld steeds een waarde terug die we aan eax kennen, het geeft 0 terug als het spel gedaan is, de speler heeft verloren of gewonnen.
	 
	;; ------ GAME LOOP ------
@@gameloop:
	
	call wait_VBLANK
	call fillBackground, 0
	call gamelogistic
	call drawlogistic
		
	loop @@gameloop
	
	call	waitForSpecificKeystroke, 001Bh ; wacht tot de escape-toets wordt ingedrukt
	call terminateProcess
ENDP main
	  

; -------------------------------------------------------------------
; DATA
; -------------------------------------------------------------------

; INSTANTIES VAN STRUCTS MAKEN, behouden zodat we weten hoe het moet!

;x position 10 dup < 1, 2 > ; een lijst van 10 position structs
;y position < , > ; een position struct met de standaardwaarden (d.w.z. 0 en 0)

DATASEG
	ball_object 	Ball <BALLSTARTX, BALLSTARTY> ; min_pos: (0,0), max_pos: (78, 48)
	paddle_object 	Paddle <PADDLESTARTX, PADDLESTARTY>
	stones_array    Stone COLSTONES*ROWSTONES dup (< >)
	
	ball_file 		db "ball", 0
	paddle_file		db "paddle", 0
	bstone_file		db "bstone", 0
	gstone_file 	db "gstone", 0
	rstone_file		db "rstone", 0
	;ystone_file		db "ystone", 0
	
	openErrorMsg 	db "could not open file", 13, 10, '$'
	readErrorMsg 	db "could not read data", 13, 10, '$'
	closeErrorMsg 	db "error during file closing", 13, 10, '$'
	
UDATASEG ; unitialised datasegment, zoals declaratie in C
	filehandle dw ? ; Één filehandle is volgens mij genoeg, aangezien je deze maar één keer nodig zal hebben per bestand kan je die hergebruiken, VRAAG: WAAROM dw ALS DATATYPE?
	ball_array db BALLSIZE dup (?)
	paddle_array db PADDLESIZE dup (?)
	bstone_array db STONESIZE dup (?)
	gstone_array db STONESIZE dup (?)
	rstone_array db STONESIZE dup (?)
	;ystone_array db STONESIZE dup (?)
; -------------------------------------------------------------------
; STACK
; -------------------------------------------------------------------
STACK 100h

END main
