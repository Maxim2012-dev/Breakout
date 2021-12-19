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
; INCLUDE "KEYB.asm"		; library custom keyboard handler

; -------------------------------------------------------------------
; CODE
; -------------------------------------------------------------------
CODESEG

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
	sprite 			dd 0
ENDS Stone	

; PROC gamelogistic

	; mov al, [offset __keyb_keyboardState + 4Dh]		; state van rechterpijl bijhouden
	; cmp al, 1
	; je @@moveRight
		
	; mov al, [offset __keyb_keyboardState + 4Bh]		; state van linkerpijl bijhouden
	; cmp al, 1
	; je @@moveLeft
		
	; @@moveRight:
		; ; call movePaddleRight
		
	; @@moveLeft:
		; ; call movePaddleLeft
 
; ENDP gamelogistic 

; ; Generische tekenprocedure die struct verwacht
PROC drawObject
	ARG 	@@STRUCT:dword, @@SPRITE:dword
	USES esi, ebx, ecx, edx, edi
	mov ebx, [@@STRUCT]
	mov edi, VIDMEMADR
	mov edx, BALLHEIGHT	 			; TODO -- Generisch maken
	mov esi, [@@SPRITE]
	add edi, 20*320+100
		
	; TODO -- Tekenen op basis van x -en y-coördinaat	
		
	mov ecx, BALLWIDTH				; aantal bytes voor 'rep movsb'
	
	@@row_loop:						; voor alle rijen in sprite	

		rep movsb					; bytes van huidige rij in sprite kopiëren naar videogeheugen
			
		add edi, SCRWIDTH-BALLWIDTH	; naar volgende rij gaan in videogeheugen
		dec edx
		jnz @@row_loop
	
	ret

ENDP drawObject


PROC drawlogistic
	
	call drawObject, offset ball_object, offset ball_array
	; call drawObject, offset paddle_object, offset paddle_array
	ret

ENDP drawlogistic


PROC main
	sti
	cld
	
	push ds
	pop	es           

	call setVideoMode, 13h
	call fillBackground, 0
	
	; call __keyb_installKeyboardHandler
	
	call openFile, offset ball_file
	call readChunk, BALLSIZE, offset ball_array
	call closeFile
	
	call drawlogistic
	 
	; ; Alle spelcomponenten tekenen (pedel, bal, grid van stenen).
	; ; Vervolgens in de spellus gaan.
	 
	; @@gameloop:
		
		; ; ; call gamelogistic
		; call drawlogistic
		
	; loop @@gameloop
	
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
	ball_object 	Ball <155, 80>
	paddle_object 	Paddle <150,100>
	
	ball_file 		db "ball", 0
	paddle_file		db "paddle", 0
	bstone_file		db "bstone", 0
	gstone_file 	db "gstone", 0
	rstone_file		db "rstone", 0
	ystone_file		db "ystone", 0
	
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
	ystone_array db STONESIZE dup (?)
; -------------------------------------------------------------------
; STACK
; -------------------------------------------------------------------
STACK 100h

END main
