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

INCLUDE "keyb.inc"		; library custom keyboard handler
INCLUDE "structs.asm"

; constants a.d.h.v. macro's
VIDMEMADR EQU 0A0000h	; videogeheugenadres
SCRWIDTH EQU 320		; schermbreedte
SCRHEIGHT EQU 200		; schermhoogte

; EVENTUEEL NOG MACRO'S, ZIE DANCER BESTAND

; -------------------------------------------------------------------
; CODE
; -------------------------------------------------------------------
CODESEG

; video mode aanpassen
PROC setVideoMode
	ARG 	@@VM:byte
	USES 	eax

	movzx ax,[@@VM]
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

PROC wait_VBLANK

... ; VRAAG: IK BEGRIJP DEZE PROCEDURE UIT HET BESTAND DANCER NIET HELEMAAL EN WEET DUS NIET OF HIER EXACT HETZELFDE MOET GEBEUREN OF NIET (IK HEB HET COMPENDIUM GELEZEN MAAR HEEFT NIET GEHOLPEN) 

ENDP wait_VBLANK

PROC openFile
	ARG		@@FILE:byte, @@FILEHANDLE:word ; @@FILE ==> pointer naar nodige bestand, @@FILEHANDLE ==> pointer naar cursor voor nodige bestand, zie bijhorende offset in datasegment
	USES eax, ebx, ecx, edx
	mov al, 0 ; read only
	mov edx, [[@@FILE]] ; pointer naar bestand in edx stoppen, register gebruikt voor I/O operaties  (VERBETERING NODIG!!!)
	mov ah, 3dh ; mode om een bestand te openen
	int 21
	
	jnc @@no_error ; carry flag is set if error occurs, indien de CF dus niet geactieveerd is, is er geen error en springt men naar de no_error label

	; Print string.
	call setVideoMode, 03h ; plaatst mode weer in text mode 
	mov  ah, 09h ; om een string te kunnen printen
	mov  edx, offset openErrorMsg ; string die geprint moet worden
	int  21h
	
	; VRAAG: ZIJN DE VOLGENDE TWEE LIJNEN CODE NODIG EN ZO JA, WAAROM?
	;mov	 ah, 00h
	;int	 16h
	call terminateProcess ; proces beïndigen aangezien er een error was
	
@@no_error:
	mov [@@FILEHANDLE], ax ; INT 21 (AH=3Dh) zal in AX de file handle teruggeven
	ret
ENDP openFile

PROC closeFile
	ARG		@@FILEHANDLE:word
	USES eax, ebx, edx
	mov bx, [@@FILEHANDLE]
	mov ah, 3Eh ; mode om een bestand te sluiten
	int 21h
	
	jnc @@no_error ; carry flag is set if error occurs

	call setVideoMode, 03h
	mov  ah, 09h
	mov  edx, offset closeErrorMsg
	int  21h
	
	;mov	ah,00h
	;int	16h
	call terminateProcess
	
@@no_error:
	ret
ENDP closeFile

PROC readChunk
	ARG		@@FILEHANDLE:word
	USES eax, ebx, ecx, edx
	mov bx, [filehandle]
	mov cx, FRAMESIZE
	mov edx, offset packedframe
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


PROC gamelogistic

	mov al, [offset __keyb_keyboardState + 4Dh]		; state van rechterpijl bijhouden
	cmp al, 1
	je @@moveRight
		
	mov al, [offset __keyb_keyboardState + 4Bh]		; state van linkerpijl bijhouden
	cmp al, 1
	je @@moveLeft
		
	@@moveRight:
		; call movePaddleRight
		
	@@moveLeft:
		; call movePaddleLeft

ENDP gamelogistic 

; Generische tekenprocedure die struct verwacht
; breedte en hoogte van sprite worden in respectievelijk de eerste en tweede positie van array gestoken
PROC drawObject
	ARG 	@@STRUCT:byte
	mov ebx, [@@STRUCT]
	mov edi, VIDMEMADR
	mov ecx, [ebx + [@@STRUCT].sprite]   	; ecx --> breedte van sprite
	mov eax, [ecx] + 1			 			; eax --> hoogte van sprite
	mov al, [ecx] + 2
		
	; voor alle rijen in sprite	
	row_loop:
		; bytes van huidige rij in sprite kopiëren naar videogeheugen
		copy_loop:
			stosb					; [edi] vullen met al
			inc al
			loop copy_loop
		
		mov ecx, [ebx + [@@STRUCT].sprite]		; ecx opnieuw initialiseren met breedte sprite
		add edi, 320 - [ecx]					; naar volgende rij gaan in videogeheugen
		dec eax
		test eax, eax
		jnz row_loop

ENDP drawObject

PROC drawBall
	
	call drawObject, ; STRUC ball		; Hier moet een ball structure worden meegegeven
	
ENDP drawBall


PROC drawlogistic
	
	call drawBall, 

ENDP drawlogistic

PROC main
	sti            
    cld            

	call setVideoMode, 13h
	call __keyb_installKeyboardHandler
	 
	; Alle spelcomponenten tekenen (pedel, bal, grid van stenen).
	; Vervolgens in de spellus gaan.
	 
	@@gameloop:
		
	; call gamelogistic
	; call drawlogistic
		
	loop @@gameloop
	
ENDP main
	  

; -------------------------------------------------------------------
; DATA
; -------------------------------------------------------------------
DATASEG
	ball_struct 	ball < position <150, 100>, ball_sprite >
	ball_file 		db "ball.bin", 0
	gblock_file 	db "green_rectangle.bin", 0
	openErrorMsg 	db "could not open file", 13, 10, '$'
	closeErrorMsg 	db "error during file closing", 13, 10, '$'
	
UDATASEG
	filehandle dw ?
	ball_sprite db FRAMESIZE dup (?)
; -------------------------------------------------------------------
; STACK
; -------------------------------------------------------------------
STACK 100h

END main
