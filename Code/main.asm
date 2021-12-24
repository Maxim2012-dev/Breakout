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
; - BESTANDEN HERORGANISEREN
; - cmp met 0 vervangen door test
; - eventueel checkcollisionpaddle

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
	lives 		db 3 
ENDS Paddle

STRUC Stone
	alive			db 1
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

; PROC CheckCollisionStone
	; USES
	
	; ret
; ENDP CheckCollisionStone

PROC moveBall

; TODO:

; ; VOOR LATER: NIET VERGETEN OM BIJ ELKE BEWEGINGSRICHTING TE CHECKEN OF DE BALL EEN STONE RAAKT!!!

;	decrement het aantal levens van de bal en check of het aantal levens = 0
	; => zo ja, het spel is gedaan (zorg ervoor dat men dit weet a.d.h.v. een return-waarde van moveBall zodat men weet dat de game-loop gedaan is)
	; => zo nee, plaats de paddle en de ball weer op hun startpositie
	ARG RETURNS eax
	USES ebx, ecx, edx
	xor eax, eax
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
	mov edx, offset paddle_object
	cmp [ebx + Ball.y], PADDLESTARTY-BALLHEIGHTCELL
	jg SHORT @@belowPaddle
	jl SHORT @@moveDown
	movzx ecx, [edx + Paddle.x]
	sub ecx, BALLWIDTHCELL 						; x-coördinaat van de ball met BALLWIDTHCELL verhogen is equivalent met de x-coördinaat van de paddle met BALLWIDTHCELL te verminderen
	cmp [ebx + Ball.x], cl
	jl SHORT @@moveDown								; er is geen botsing, de ball zit links van de paddle
	movzx ecx, [edx + Paddle.x]
	add ecx, PADDLEWIDTHCELL
	cmp [ebx + Ball.x], cl
	jg SHORT @@moveDown								; er is geen botsing, de ball zit rechts van de paddle
	mov [ebx + Ball.y_sense], UP
	jmp SHORT @@end
@@moveDown:
	inc [ebx + Ball.y]
	jmp SHORT @@end
@@belowPaddle:
	cmp [ebx + Ball.y], BOARDHEIGHT-BALLHEIGHTCELL
	jne @@moveDown
	dec [edx + Paddle.lives]
	cmp [edx + Paddle.lives], 0
	jg @@newChance
	mov eax, 1
	jmp @@end
@@newChance:
	mov [ebx + Ball.x], BALLSTARTX
	mov [ebx + Ball.y], BALLSTARTY
	mov [ebx + Ball.active], 0
	mov [edx + Paddle.x], PADDLESTARTX
	mov [edx + Paddle.y], PADDLESTARTY
	
@@end:
	ret
ENDP moveBall

;; SPELLOGICA
PROC gamelogistic
	ARG RETURNS eax
	USES ebx
	xor eax, eax
	
	mov ebx, offset ball_object
	cmp [ebx + Ball.active], 0
	je SHORT @@handle_input
	and cl, 1
	jnz @@handle_input								; zodat de bal minder snel beweegt (beweegt maar één op de twee keer)
	call moveBall									; bal beweegt enkel alleen als deze actief is (en de counter even is)
	cmp eax, 1
	je @@end

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

PROC drawStones
	USES eax, ebx, ecx, edx
	mov ebx, offset stones_array		; hebben we later miss nog nodig om te checken of de stenen 'alive' zijn
	xor ecx, ecx	; counter op 0 zetten	
@@drawLoop:
	cmp [ebx + Stone.alive], 1
	jne SHORT @@nextIteration
	push ebx				; pointer naar volgende struct OP STACK
	push ecx				; counter OP STACK
	; posx = STONESSTARTX + (counter%COLSTONES) * STONEWIDTHCELL
	mov eax, ecx 
	mov ecx, COLSTONES
	xor edx, edx			; op 0 zetten vóór deling, anders error
	div ecx					; modulo in edx
	mov eax, STONEWIDTHCELL
	mul edx
	add eax, STONESSTARTX
	pop ecx					; counter VAN STACK, aangezien de waarde van ecx ondertussen werd gewijzigd
	push eax				; x-coördinaat OP STACK
	push ecx				; counter terug OP STACK
	; posy = STONESSTARTY + (counter/COLSTONES) * STONEHEIGHTCELL
	mov eax, ecx
	mov ecx, COLSTONES
	xor edx, edx			
	div ecx					; quotiënt in eax
	mov edx, STONEHEIGHTCELL
	mul edx
	add eax, STONESSTARTY 
	pop ecx					; counter VAN STACK, aangezien de waarde van ecx ondertussen werd gewijzigd
	push eax				; y-coördinaat OP STACK
	push ecx				; counter terug OP STACK
	; FORMULE NOG TOEVOEGEN
	mov eax, ecx
	mov ecx, COLSTONES*ROWSPERCOLOUR
	xor edx, edx
	div ecx							; quotiënt in eax
	mov ebx, offset bstone_array	; offset eerste sprite in geheugen
	mov ecx, STONESIZEPX
	mul ecx
	add ebx, eax			; ebx bevat nu de pointer naar de gepaste sprite-array
	pop ecx					; counter VAN STACK, aangezien de waarde van ecx ondertussen werd gewijzigd
	pop eax					; y-coördinaat OP STACK
	pop edx					; x-coördinaat VAN STACK
	call drawObject, edx, eax, ebx, STONEWIDTHPX, STONEHEIGHTPX
	pop ebx					; pointer naar volgende struct VAN STACK
@@nextIteration:
	inc ebx				; naar volgende struct gaan
	inc ecx
	cmp ecx, COLSTONES*ROWSTONES
	jl @@drawLoop
	ret
ENDP drawStones

;; Levens displayen (zie compendium)
PROC displayString
ARG @@row:dword, @@column:dword, @@offset:dword
USES eax, ebx, edx
	mov edx, [@@row]
	mov ebx, [@@column]
	mov ah, 02h
	shl edx, 08h
	mov dl, bl
	mov bh, 0
	int 10h
	mov ah, 09h
	mov edx, [@@offset]
	int 21h
	ret
ENDP displayString
	
PROC drawlogistic
	call displayString, 0, 0, offset levens_string
	call drawStones 
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
	
	; Handmatig loop maken, we kennen bijvoorbeeld aan eax waarde 1 toe juist voor onze loop.
	; We blijven iteren zolang eax niet gelijk is aan 0 (jump if not zero).
	; De procedure gamelogistic geeft bijvoorbeeld steeds een waarde terug die we aan eax kennen, het geeft 0 terug als het spel gedaan is, de speler heeft verloren of gewonnen.
	 
	
	xor eax, eax		; eax gebruikt om te checken of het spel verder gaat (ja = 0 en nee = 1)
	xor ecx, ecx		; gebruikt zodat onze bal trager beweegt (beweegt maar één op de twee keer)
	
	;; ------ GAME LOOP ------
@@gameloop:
	
	call wait_VBLANK
	call fillBackground, 0
	call gamelogistic
	call drawlogistic
	
	inc ecx
	cmp eax, 0
	je @@gameloop
	;; ------------------------
	
	cmp eax, 1			; eax = 1 => game-over
	je SHORT @@displayGameOver
	cmp eax, 2			; eax = 2 => you won
	je SHORT @@displayWin

@@displayGameOver:
	call displayString, MESSAGEROW, MESSAGECOL, offset game_over_string
	jmp SHORT @@waitForEscape
@@displayWin:
	call displayString, MESSAGEROW, MESSAGECOL, offset winning_string
@@waitForEscape:	
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
	
	openErrorMsg 		db "could not open file", 13, 10, '$'
	readErrorMsg 		db "could not read data", 13, 10, '$'
	closeErrorMsg 		db "error during file closing", 13, 10, '$'
	levens_string		db "Levens:", 7, 10, '$'
	game_over_string	db "GAME OVER!", 10, 10, '$'
	winning_string		db "YOU WON!", 8, 10, '$'
	
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