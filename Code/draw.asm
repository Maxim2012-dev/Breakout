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

; wait for @@framecount frames
PROC wait_VBLANK ; CODE NOG AANPASSEN, VBLANK MOET MAAR 1 KEER WACHTEN => PROCEDURE HEEFT GEEN ARGUMENT MEER NODIG, BIJ ONS IS GEEN LOOP NODIG, @@framecount vervangen door 1
	ARG @@framecount: word
	USES eax, ecx, edx
	mov dx, 03dah 					; Wait for screen refresh
	movzx ecx, [@@framecount]
	
@@VBlank_phase1:
	in al, dx 
	and al, 8
	jnz @@VBlank_phase1
@@VBlank_phase2:
	in al, dx 
	and al, 8
	jz @@VBlank_phase2
	loop @@VBlank_phase1
	
	ret 
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
	
	; wacht op het indrukken van een toets en geeft terug welke deze is, maar dat is niet van belang, daar wordt niets mee gedaan
	mov	 ah, 00h
	int	 16h
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
	
	mov	ah,00h
	int	16h
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

<<<<<<< HEAD
...
=======
	call setVideoMode, 03h
	mov  ah, 09h
	mov  edx, offset readErrorMsg
	int  21h
	
	mov	ah,00h
	int	16h
	call terminateProcess
	
@@no_error:
	ret
>>>>>>> e69bf7aa03a13ec3ceb692ab9f52447e400edf5b

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
	USES ; OPMERKING_A: VERGETEN VERMELDEN
	mov ebx, [@@STRUCT]
	mov edi, VIDMEMADR
	mov ecx, [ebx + [@@STRUCT].sprite]   	; ecx --> breedte van sprite, OPMERKING_A: VOLGENS MIJ WERKT DIT NIET ZO, ZIE WPO5 SLIDE 10
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

PROC drawBall ; OPMERKING_A: IS MISSCHIEN NIET NODIG EN KAN MEN RECHTSTREEKS OPROEPEN IN DRAWLOGISTIC
	
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
	ball_file 		db "ball", 0
	gblock_file 	db "greenstone", 0
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
