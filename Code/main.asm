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
; - VERLIEST 1 LEVEN ALS DEZE ER NOG HEEFT ANDERS IS HET SPEL GEDAAN)
; - BESTANDEN HERORGANISEREN
; - BAL TRAGER LATEN BEWEGEN

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
	ARG @@key:byte
	USES eax

@@waitForKeystroke:
	mov	ah, 00h
	int	16h
	cmp	al, [@@key]
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
	
	jnc SHORT @@no_error ; carry flag is set if error occurs, indien de CF dus niet geactieveerd is, is er geen error en springt men naar de no_error label

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
	
	jnc SHORT @@no_error ; carry flag is set if error occurs

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
	
	jnc SHORT @@no_error  	
	
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
	x			db BALLSTARTX ; min_x: 0, max_x: 78 (in cellen)
	y			db BALLSTARTY ; min_y: 0, max_y: 48
	active		db 0 ; 0 bal beweegt nog niet alleen (beweegt dus samen met paddle), 1 bal beweegt wel alleen
	x_sense		db LEFT
	y_sense		db UP
ENDS Ball

STRUC Paddle
	x 			db PADDLESTARTX
	y 			db PADDLESTARTY
	health 		db 3 
ENDS Paddle

STRUC Stone
	;index 			db 0	; index in array
	alive			db 1
	;color			db 0
ENDS Stone

PROC movePaddleLeft
	USES ebx
	mov ebx, offset paddle_object
	cmp [ebx + Paddle.x], 0
	je SHORT @@end
	dec [ebx + Paddle.x]
	mov ebx, offset ball_object			; checken of de bal mee moet bewegen
	cmp [ebx + Ball.active], 1
	je SHORT @@end
	dec [ebx + Ball.x]					; bal naar links bewegen
@@end:
	ret
ENDP movePaddleLeft

PROC movePaddleRight
	USES ebx
	mov ebx, offset paddle_object
	cmp [ebx + Paddle.x], BOARDWIDTH-PADDLEWIDTHCELL ; x-waarde van paddle-object vergelijken met grootst mogelijke x-waarde voor het paddle-object 
	je SHORT @@end
	inc [ebx + Paddle.x]
	; checken of de bal mee moet bewegen
	mov ebx, offset ball_object
	cmp [ebx + Ball.active], 1
	je SHORT @@end
	inc [ebx + Ball.x] ; bal naar rechts bewegen
@@end:
	ret
ENDP movePaddleRight

PROC moveBall

; TODO:

; ; VOOR LATER: NIET VERGETEN OM BIJ ELKE BEWEGINGSRICHTING TE CHECKEN OF DE BALL EEN STONE RAAKT!!!

;	decrement het aantal levens van de bal en check of het aantal levens = 0
	; => zo ja, het spel is gedaan (zorg ervoor dat men dit weet a.d.h.v. een return-waarde van moveBall zodat men weet dat de game-loop gedaan is)
	; => zo nee, plaats de paddle en de ball weer op hun startpositie

	USES eax, ebx, ecx, edx
	mov ebx, offset ball_object
	cmp [ebx + Ball.x_sense], RIGHT
	je SHORT @@handleMoveRight
	
@@handleMoveLeft:
	cmp [ebx + Ball.x], 0
	jg SHORT @@moveLeft
	mov [ebx + Ball.x_sense], RIGHT
	jmp SHORT @@handleMoveVertical
@@moveLeft:
	dec [ebx + Ball.x]
	jmp SHORT @@handleMoveVertical

@@handleMoveRight:
	cmp [ebx + Ball.x], BOARDWIDTH-BALLWIDTHCELL
	jl SHORT @@moveRight
	mov [ebx + Ball.x_sense], LEFT
	jmp SHORT @@handleMoveVertical
@@moveRight:
	inc [ebx + Ball.x]

@@handleMoveVertical:
	cmp [ebx + Ball.y_sense], UP
	je SHORT @@handleMoveUp
	jmp SHORT @@handleMoveDown
	
@@handleMoveUp:
	cmp [ebx + Ball.y], 0
	jg SHORT @@moveUp
	mov [ebx + Ball.y_sense], DOWN
	jmp SHORT @@end
@@moveUp:
	dec [ebx + Ball.y]
	jmp SHORT @@end
	
@@handleMoveDown:
	movzx eax, [ebx + Ball.y]
	cmp eax, PADDLESTARTY-BALLHEIGHTCELL
	jg SHORT @@belowPaddle
	jl SHORT @@moveDown
	movzx ecx, [ebx + Ball.x]
	mov edx, offset paddle_object
	movzx edx, [edx + Paddle.x]
	sub edx, BALLWIDTHCELL 						; x-coördinaat van de ball met BALLWIDTHCELL verhogen is equivalent met de x-coördinaat van de paddle met BALLWIDTHCELL te verminderen
	cmp ecx, edx
	jl SHORT @@moveDown								; er is geen botsing, de ball zit links van de paddle
	mov edx, offset paddle_object
	movzx edx, [edx + Paddle.x]
	add edx, PADDLEWIDTHCELL
	cmp ecx, edx
	jg SHORT @@moveDown								; er is geen botsing, de ball zit rechts van de paddle
	mov [ebx + Ball.y_sense], UP
	jmp SHORT @@end
@@moveDown:
	inc eax
	mov [ebx + Ball.y], al
	jmp SHORT @@end
@@belowPaddle:
	cmp eax, BOARDHEIGHT-BALLHEIGHTCELL
	jne @@moveDown
	mov [ebx + Ball.x], BALLSTARTX
	mov [ebx + Ball.y], BALLSTARTY
	mov [ebx + Ball.active], 0
	mov edx, offset paddle_object
	mov [edx + Paddle.x], PADDLESTARTX
	mov [edx + Paddle.y], PADDLESTARTY
	
@@end:
	ret
ENDP moveBall

;; SPELLOGICA
PROC gamelogistic
	USES eax, ebx
	
	mov ebx, offset ball_object
	cmp [ebx + Ball.active], 0
	je SHORT @@handle_input 
	call moveBall									; bal beweegt enkel alleen als deze actief is

@@handle_input:
	cmp [offset __keyb_keyboardState + 39h], 1		; spatiebalk ingedrukt? 
	je SHORT @@makeBallActive
		
	cmp [offset __keyb_keyboardState + 4Dh], 1		; rechterpijl ingedrukt?
	je SHORT @@moveRight
		
	cmp [offset __keyb_keyboardState + 4Bh], 1		; linkerpijl ingedrukt?
	je SHORT @@moveLeft
	
	jmp SHORT @@end

@@makeBallActive:
	mov [ebx + Ball.active], 1		; op actief zetten
	jmp SHORT @@end
@@moveRight:
	call movePaddleRight
	jmp SHORT @@end
@@moveLeft:
	call movePaddleLeft
	
@@end:
	ret
ENDP gamelogistic 

;; Generische tekenprocedure
PROC drawObject
	ARG @@XPOS:byte, @@YPOS:byte, @@SPRITE:dword, @@WIDTH:byte, @@HEIGHT:byte	; x en y coördinaat in cellen, breedte en hoogte in pixels
	USES eax, ebx, ecx, edx, esi, edi
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
	call drawObject, eax, ebx, offset ball_array, BALLWIDTHPX, BALLHEIGHTPX
	ret
ENDP drawBall

PROC drawPaddle
	USES eax, ebx
	mov ebx, offset paddle_object
	movzx eax, [ebx + Paddle.x]
	movzx ebx, [ebx + Paddle.y]
	call drawObject, eax, ebx, offset paddle_array, PADDLEWIDTHPX, PADDLEHEIGHTPX
	ret
ENDP drawPaddle

;; kleur van huidige steen bepalen op basis van counter
; PROC determineColor
	; ARG @@COUNTER:byte RETURNS ebx
	; USES eax, edx, ecx, ebx
	; xor edx, edx
	; movzx eax, [@@COUNTER]
	; mov ecx, ROWSTONES
	; div ecx
	; cmp al, 0
	; je @@onelbl
	; cmp al, 1
	; je @@onelbl
	; cmp al, 2
	; je @@threelbl
	; cmp al, 3
	; je @@threelbl
	; cmp al, 4
	; je @@fivelbl
	; cmp al, 5
	; je @@fivelbl
; @@onelbl:
	; mov ebx, offset gstone_array
	; jmp @@endlbl
; @@threelbl:
	; mov ebx, offset rstone_array
	; jmp @@endlbl
; @@fivelbl:
	; mov ebx, offset bstone_array
; @@endlbl:	
	; ret
; ENDP determineColor

; PROC drawStones
	; USES eax, ebx, ecx, edx
	; mov ebx, offset stones_array
	; mov ecx, COLSTONES*ROWSTONES
; @@drawLoop:
	; ; posx = STONESSTARTX + (index_position%COLSTONES) * STONEWIDTHCELL
	; push ecx				; counter OP STACK
	; xor edx, edx
	; movzx eax, [ebx + Stone.index]
	; mov ecx, COLSTONES
	; div ecx
	; mov eax, STONEWIDTHCELL
	; mul edx
	; add eax, STONESSTARTX
	; push eax				; x-coördinaat OP STACK
	; ; posy = STONESSTARTY + (index_position/COLSTONES) * STONEHEIGHTCELL
	; xor edx, edx
	; movzx eax, [ebx + Stone.index]
	; div ecx
	; mov edx, STONEHEIGHTCELL
	; mul edx
	; add eax, STONESSTARTY   ; eax bevat y-coördinaat
	; pop edx					; x-coördinaat VAN STACK
	; pop ecx					; counter VAN STACK
	; ;call determineColor, ecx 	; returnt pointer naar nodige sprite in ebx
	; call drawObject, edx, eax, offset gstone_array, STONEWIDTHPX, STONEHEIGHTPX
	; add ebx, 3				; naar volgende struct gaan
	; loop @@drawLoop
	; ret
; ENDP drawStones

; ;; Indexen juist zetten
; PROC initStones
	; USES eax, ebx, ecx
	; mov ecx, COLSTONES*ROWSTONES
	; mov ebx, offset stones_array
	; xor eax, eax
; @@arrayLoop:	
	; mov [ebx + Stone.index], al
	; add ebx, 3					; naar volgende struct gaan
	; inc eax
	; loop @@arrayLoop
	; ret
; ENDP initStones

PROC drawStones
	USES eax, ebx, ecx, edx
	mov ebx, offset stones_array
	mov ecx, COLSTONES*ROWSTONES
@@drawLoop:
	; posx = STONESSTARTX + (index_position%COLSTONES) * STONEWIDTHCELL
	push ecx				; counter OP STACK
	xor edx, edx
	movzx eax, [ebx + Stone.index]
	mov ecx, COLSTONES
	div ecx
	mov eax, STONEWIDTHCELL
	mul edx
	add eax, STONESSTARTX
	push eax				; x-coördinaat OP STACK
	; posy = STONESSTARTY + (index_position/COLSTONES) * STONEHEIGHTCELL
	xor edx, edx
	movzx eax, [ebx + Stone.index]
	div ecx
	mov edx, STONEHEIGHTCELL
	mul edx
	add eax, STONESSTARTY   ; eax bevat y-coördinaat
	pop edx					; x-coördinaat VAN STACK
	pop ecx					; counter VAN STACK
	;call determineColor, ecx 	; returnt pointer naar nodige sprite in ebx
	call drawObject, edx, eax, offset gstone_array, STONEWIDTHPX, STONEHEIGHTPX
	inc ebx				; naar volgende struct gaan
	loop @@drawLoop
	ret
ENDP drawStones

;; Levens displayen (zie compendium)
PROC displayString
USES eax, ebx, edx
	mov edx, 0
	mov ebx, 0
	mov ah, 02h
	shl edx, 08h
	mov dl, bl
	mov bh, 0
	int 10h
	mov ah, 09h
	mov edx, offset levens_string
	int 21h
	ret
ENDP displayString
	
PROC drawlogistic
	call displayString
	;call drawStones 
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
	call readChunk, BALLSIZEPX, offset ball_array
	call closeFile
	
	call openFile, offset paddle_file
	call readChunk, PADDLESIZEPX, offset paddle_array
	call closeFile
	
	call openFile, offset bstone_file
	call readChunk, STONESIZEPX, offset bstone_array
	call closeFile
	
	call openFile, offset gstone_file
	call readChunk, STONESIZEPX, offset gstone_array
	call closeFile
	
	call openFile, offset rstone_file
	call readChunk, STONESIZEPX, offset rstone_array
	call closeFile
	
	;call initStones
	
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
	
	call waitForSpecificKeystroke, 001Bh ; wacht tot de escape-toets wordt ingedrukt
	call terminateProcess
ENDP main
	  

; -------------------------------------------------------------------
; DATA
; -------------------------------------------------------------------

; INSTANTIES VAN STRUCTS MAKEN, behouden zodat we weten hoe het moet!

;x position 10 dup < 1, 2 > ; een lijst van 10 position structs
;y position < , > ; een position struct met de standaardwaarden (d.w.z. 0 en 0)

DATASEG
	ball_object 	Ball < >
	paddle_object 	Paddle < >
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
	levens_string	db "Levens:", 7, 10, '$' 
	
UDATASEG ; unitialised datasegment, zoals declaratie in C
	filehandle dw ? ; Één filehandle is volgens mij genoeg, aangezien je deze maar één keer nodig zal hebben per bestand kan je die hergebruiken, VRAAG: WAAROM dw ALS DATATYPE?
	ball_array db BALLSIZEPX dup (?)
	paddle_array db PADDLESIZEPX dup (?)
	bstone_array db STONESIZEPX dup (?)
	gstone_array db STONESIZEPX dup (?)
	rstone_array db STONESIZEPX dup (?)
	;ystone_array db STONESIZEPX dup (?)
; -------------------------------------------------------------------
; STACK
; -------------------------------------------------------------------
STACK 100h

END main