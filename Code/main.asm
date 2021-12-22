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
	x			db 0 ; (in cellen)
	y			db 0
	breadth		db BALLWIDTH/CELLWIDTH ; (in cellen)
	height		db BALLHEIGHT/CELLHEIGHT
	active		db 0 ; 0 bal beweegt nog niet alleen (beweegt dus samen met paddle), 1 bal beweegt wel alleen
	x_sense		db LEFT
	y_sense		db UP
ENDS Ball

STRUC Paddle
	x 			db 0
	y 			db 0
	breadth 	db PADDLEWIDTH/CELLWIDTH ; aangezien width een keyword is, gebruiken we breadth
	height 		db PADDLEHEIGHT/CELLHEIGHT
	health 		db 3 
ENDS Paddle

STRUC Stone
	index 			db 0	; index in array
	breadth			db STONEWIDTH/CELLWIDTH
	height			db STONEHEIGHT/CELLHEIGHT
	alive			db 1
ENDS Stone

PROC movePaddleLeft
	USES eax, ebx, edx
	mov ebx, offset paddle_object
	movzx eax, [ebx + Paddle.x]
	cmp eax, 0
	je SHORT @@end
	dec eax
	mov [ebx + Paddle.x], al
	mov ebx, offset ball_object			; checken of de bal mee moet bewegen
	movzx eax, [ebx + Ball.active]
	cmp eax, 1
	je SHORT @@end
	call moveBallLeft
@@end:
	ret
ENDP movePaddleLeft	

PROC movePaddleRight
	USES eax, ebx, ecx, edx
	mov ebx, offset paddle_object
	mov eax, BOARDWIDTH
	movzx ecx, [ebx + Paddle.breadth]
	sub eax, ecx 						; grootst mogelijke x-waarde voor het paddle-object 
	movzx ecx, [ebx + Paddle.x]
	cmp ecx, eax
	je SHORT @@end
	inc ecx
	mov [ebx + Paddle.x], cl
	mov ebx, offset ball_object			; checken of de bal mee moet bewegen
	movzx eax, [ebx + Ball.active]
	cmp eax, 1
	je SHORT @@end
	call moveBallRight
@@end:
	ret
ENDP movePaddleRight

PROC moveBallDown
	USES eax, ebx
	mov ebx, offset ball_object
	movzx eax, [ebx + Ball.y]
	inc eax 						;; Het checken op spelranden doen we in moveBall
	mov [ebx + Ball.y], al
	ret
ENDP moveBallDown

PROC moveBallUp
	USES eax, ebx
	mov ebx, offset ball_object
	movzx eax, [ebx + Ball.y]
	dec eax 						;; Het checken op spelranden doen we in moveBall
	mov [ebx + Ball.y], al
	ret
ENDP moveBallUp

PROC moveBallLeft
	USES eax, ebx
	mov ebx, offset ball_object
	movzx eax, [ebx + Ball.x]
	dec eax 						;; Het checken op spelranden doen we in moveBall
	mov [ebx + Ball.x], al
	ret
ENDP moveBallLeft

PROC moveBallRight
	USES eax, ebx
	mov ebx, offset ball_object
	movzx eax, [ebx + Ball.x]
	inc eax							;; Het checken op spelranden doen we in moveBall
	mov [ebx + Ball.x], al
	ret
ENDP moveBallRight

; PROC moveBall

; ; TODO:

; ;; STAP1: ball houdt enkel rekening met schermgrenzen

; ; ; VOOR LATER: NIET VERGETEN OM BIJ ELKE BEWEGINGSRICHTING TE CHECKEN OF DE BALL EEN STONE RAAKT!!!

; ; ; ; DOWN:
; ; ; checken of de bal zich onder de denkbeeldige lijn bevindt (zie oranje lijn tekening)
		; ; ; => zo ja, check of deze zich juist boven de paddle bevindt
				; ; ; => zo ja, check of er een match is tussen het bereik van da ball en de paddle volgens de x-as
						; ; ; => zo ja, wijzig de beweginsrichting volgens de y-as, de ball beweeegt nu terug naar boven
						; ; ; => zo nee, beweeg de ball volgens zijn huidige richting 
				; ; ; => zo nee (dan bevindt deze zich onder of naast de paddle), check of deze de onderkant van de scherm raakt 
						; ; ; => zo ja, decrement het aantal levens van de bal en check of het aantal levens = 0
								; ; ; => zo ja, het spel is gedaan (zorg ervoor dat men dit weet a.d.h.v. een return-waarde van moveBall zodat men weet dat de game-loop gedaan is)
								; ; ; => zo nee, plaats de paddle en de ball weer op hun startpositie

; ; ; ; UP:
; ; ; checken of de bal de bovenkant raakt => zo ja, wijzig de beweginsrichting volgens de y-as, de ball beweeegt nu naar beneden
; ; ; ; LEFT:
; ; ; checken of de bal de linkerkant raakt => zo ja, wijzig de beweginsrichting volgens de x-as, de ball beweeegt nu naar rechts
; ; ; ; RIGHT:
; ; ; checken of de bal de rechterkant raakt => zo ja, wijzig de beweginsrichting volgens de x-as, de ball beweeegt nu naar links

	; USES eax, ebx, ecx, edx
	; mov ebx, offset ball_object
	; movzx eax, [ebx + Ball.x_sense]
	; cmp al, 0
	; je @@moveLeft
	; jmp @@moveRight
	
; @@moveLeft:



; @@moveRight:



	
; @@yCheckx1:
	; call moveBallRight
	; movzx eax, [ebx + Ball.y_sense]
	; cmp al, 0
	; je @@up
	; call moveBallDown
	; jmp SHORT @@end
; @@yCheckx0:
	; call moveBallLeft
	; movzx eax, [ebx + Ball.y_sense]
	; cmp al, 0
	; je @@up
	; call moveBallDown
	; jmp SHORT @@end
; @@up:
	; call moveBallUp
	; jmp SHORT @@end
	
; ;; LINKERRAND GERAAKT					(MISSCHIEN BETER CHECKEN OP RANDEN IN DE MOVE PROCEDURES)
; @@leftEdge:
	; mov [ebx + Ball.x_sense], 1		;; bal beweegt naar rechts (y_sense kan 1 of 0 zijn)
; ;; BOVENRAND GERAAKT
; @@topEdge:
	; mov [ebx + Ball.y_sense], 1		;; bal beweegt naar onder (x_sense kan 1 of 0 zijn)
; ;; RECHTERRAND GERAAKT
; @@rightEdge:
	; mov [ebx + Ball.x_sense], 0		;; bal beweegt naar links (y_sense kan 1 of 0 zijn)
	
; ;; Als de bal dan de paddle raakt, dan moet y_sense op 0 gezet worden	
; @@end:
	; ret
; ENDP moveBall

;; SPELLOGICA
PROC gamelogistic
	USES eax, ebx
	
	mov ebx, offset ball_object
	mov al, [ebx + Ball.active]
	cmp al, 0
	je SHORT @@handle_input 
	;call moveBall									; bal beweegt enkel alleen als deze actief is

@@handle_input:
	mov al, [offset __keyb_keyboardState + 39h]		; state van spatiebalk bijhouden 
	cmp al, 1										; (kan misschien beter, aangezien deze later ook nog kan getriggerd worden)
	je SHORT @@makeBallActive

	mov al, [offset __keyb_keyboardState + 4Dh]		; state van rechterpijl bijhouden
	cmp al, 1
	je SHORT @@moveRight
		
	mov al, [offset __keyb_keyboardState + 4Bh]		; state van linkerpijl bijhouden
	cmp al, 1
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
	USES eax, ebx, ecx, edx
	mov ebx, offset stones_array
	mov ecx, COLSTONES*ROWSTONES
	mov eax, STONESSTARTX
	mov edx, STONESSTARTY
@@drawLoop:
	call drawObject, eax, edx, offset bstone_array, STONEWIDTH, STONEHEIGHT
	; TODO
	loop @@drawLoop
	ret
ENDP drawStones

;; Indexen juist zetten
PROC initStones
	USES eax, ebx, ecx
	mov ecx, COLSTONES*ROWSTONES
	xor eax, eax
	mov ebx, offset stones_array
@@arrayLoop:	
	mov [ebx + Stone.index], al
	add ebx, 4					; naar volgende struct gaan
	inc eax
	loop @@arrayLoop
	ret
ENDP initStones
	
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
	
	call initStones
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