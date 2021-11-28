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

;INCLUDE "keyb.inc"		; library custom keyboard handler
;INCLUDE "structs.asm"

; constants a.d.h.v. macro's
VIDMEMADR EQU 0A0000h	; videogeheugenadres
SCRWIDTH EQU 320		; schermbreedte
SCRHEIGHT EQU 200		; schermhoogte

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
	ARG	@@FILE:dword ; @@FILE ==> adres van bestandsnaam/verwijzing naar nodige bestand in DATASEG
	USES eax, ebx, ecx, edx
	mov al, 0 ; read only
	mov edx, [@@FILE] ; adres van bestandsnaam/verwijzing naar bestand in edx stoppen, register gebruikt voor I/O operaties
	mov ah, 3dh ; mode om een bestand te openen
	int 21
	
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
	mov [filehandle], ax ; INT 21 (AH=3Dh) zal in AX de filehandle teruggeven, variabele "filehandle" herbruiken voor de verschillende bestanden 
	ret
ENDP openFile

PROC closeFile
	USES eax, ebx, edx ; VRAAG: REGISTER ECX TOCH NIET NODIG? (WANT DEZE WORDT GEPRESERVED IN DANCER)
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
	ARG @@SPRITE_SIZE:word, @@ARRAY_BYTES:dword ; @@SPRITE_SIZE ==> getal die overeenkomt met aantal pixels van sprite, @@ARRAY_BYTES ==> adres van array die de indices van de nodige kleuren voor elke pixel zal bijhouden
	USES eax, ebx, ecx, edx
	mov bx, [filehandle]
	mov cx, [@@SPRITE_SIZE]
	mov edx, [@@ARRAY_BYTES] 
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
; ; breedte en hoogte van sprite worden in respectievelijk de eerste en tweede positie van array gestoken
; PROC drawObject
	; ARG 	@@STRUCT:byte
	; USES ; OPMERKING_A: VERGETEN VERMELDEN
	; mov ebx, [@@STRUCT]
	; mov edi, VIDMEMADR
	; mov ecx, [ebx + [@@STRUCT].sprite]   	; ecx --> breedte van sprite, OPMERKING_A: VOLGENS MIJ WERKT DIT NIET ZO, ZIE WPO5 SLIDE 10
	; mov eax, [ecx] + 1			 			; eax --> hoogte van sprite
	; mov al, [ecx] + 2
		
	; ; voor alle rijen in sprite	
	; row_loop:
		; ; bytes van huidige rij in sprite kopiëren naar videogeheugen
		; copy_loop:
			; stosb					; [edi] vullen met al
			; inc al
			; loop copy_loop
		
		; mov ecx, [ebx + [@@STRUCT].sprite]		; ecx opnieuw initialiseren met breedte sprite
		; add edi, 320 - [ecx]					; naar volgende rij gaan in videogeheugen
		; dec eax
		; test eax, eax
		; jnz row_loop

; ENDP drawObject

; PROC drawBall ; OPMERKING_A: IS MISSCHIEN NIET NODIG EN KAN MEN RECHTSTREEKS OPROEPEN IN DRAWLOGISTIC
	
	; call drawObject, ; STRUC ball		; Hier moet een ball structure worden meegegeven
	
; ENDP drawBall


; PROC drawlogistic
	
	; call drawBall, 

; ENDP drawlogistic

PROC main
	sti
	cld
	
	push ds
	pop	es           

	call setVideoMode, 13h
	call fillBackground, 0
	; call __keyb_installKeyboardHandler
	 
	; ; Alle spelcomponenten tekenen (pedel, bal, grid van stenen).
	; ; Vervolgens in de spellus gaan.
	 
	; @@gameloop:
		
	; ; call gamelogistic
	; ; call drawlogistic
		
	; loop @@gameloop
	call	waitForSpecificKeystroke, 001Bh ; wacht tot de escape-toets wordt ingedrukt
	call terminateProcess
ENDP main
	  

; -------------------------------------------------------------------
; DATA
; -------------------------------------------------------------------
DATASEG
	;ball_struct 	ball < position <150, 100>, ball_sprite >
	
	ball_file 		db "ball", 0
	paddle_file		db "paddle", 0
	bstone_file		db "bluestone", 0
	gstone_file 	db "greenstone", 0
	rstone_file		db "redstone", 0
	ystone_file		db "yellowstone", 0
	
	openErrorMsg 	db "could not open file", 13, 10, '$'
	readErrorMsg 	db "could not read data", 13, 10, '$'
	closeErrorMsg 	db "error during file closing", 13, 10, '$'
	
UDATASEG ; unitialised datasegment, zoals declaratie in C
	filehandle dw ? ; Één filehandle is volgens mij genoeg, aangezien je deze maar één keer nodig zal hebben per bestand kan je die hergebruiken, VRAAG: WAAROM dw ALS DATATYPE?  
	; ball_sprite db FRAMESIZE dup (?)
; -------------------------------------------------------------------
; STACK
; -------------------------------------------------------------------
STACK 100h

END main
