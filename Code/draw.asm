IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

INCLUDE "keyb.inc"		; library custom keyboard handler

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

...

ENDP wait_VBLANK

PROC openFile
	ARG		@@FILE:byte, @@FILEHANDLE:word ; @@FILE ==> pointer naar nodige bestand, @@FILEHANDLE ==> pointer naar cursor voor nodige bestand, zie bijhorende offset in datasegment
	USES eax, ebx, ecx, edx
	mov al, 0 ; read only
	mov edx, [@@FILE] ; pointer naar bestand in edx stoppen, register gebruikt voor I/O operaties
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

...

ENDP readChunk

;;; Kan generieker gemaakt worden door een algemene move PROC met richting als argument

; PROC movePaddleLeft

; ...

; ENDP movePaddleLeft

; PROC movePaddleRight

; ...

; ENDP movePaddleRight

PROC main
	sti            
    cld            

	 call setVideoMode, 13h
	 call __keyb_installKeyboardHandler
	 
	 mov EDI, 0A0000h
	 
	 ; Alle spelcomponenten tekenen (pedel, bal, grid van stenen).
	 ; Vervolgens in de spellus gaan.
	 
	 @@gameloop:
		
		mov al, [offset __keyb_keyboardState + 4Dh]		; state van rechterpijl bijhouden
		cmp al, 1
		je moveRight
		
		mov al, [offset __keyb_keyboardState + 4Bh]		; state van linkerpijl bijhouden
		cmp al, 1
		je moveLeft
		
		moveRight:
		; call movePaddleRight
		mov bl, 15
		add edi, 2*320+10
		mov [edi], bl
		
		moveLeft:
		; call movePaddleLeft
		mov bl, 15
		add edi, 2*320+10
		mov [edi], bl
		
		
	 loop @@gameloop
	
ENDP main
	  

; -------------------------------------------------------------------
; DATA
; -------------------------------------------------------------------
DATASEG
	openErrorMsg db "could not open file", 13, 10, '$'
	closeErrorMsg db "error during file closing", 13, 10, '$'
	
UDATASEG

; -------------------------------------------------------------------
; STACK
; -------------------------------------------------------------------
STACK 100h

END main
