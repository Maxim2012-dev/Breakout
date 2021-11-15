; Vragen voor assistent:

; 1. Moeten we onze code opdelen in verschillende bestanden of is het oké als we dit goed organiseren in één bestand, zoals u het doet voor de WPO-oefeninge? 
;    Want we hebben eigenlijk toch nog niet gezien hoe je procedure/macro's moet providen en importeren.
; 2. Hoe kunnen we een afbeelding kopiëren naar onze scherm, bestaat daar een instructie voor?
; 3. Mag de collision-check tussen de verschillende spelelementen gebeuren a.d.h.v. de bitmaps en zo controleren of er pixels overlappen, is moeilijk of valt het mee?


IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

; constants a.d.h.v. macro's
VIDMEMADR EQU 0A0000h	; videogeheugenadres
SCRWIDTH EQU 320		; schermbreedte
SCRHEIGHT EQU 200		; schermhoogte

; -------------------------------------------------------------------
; CODE
; -------------------------------------------------------------------
CODESEG

start:
     sti            
     cld            

	; Video mode 13h instellen (320x200 pixels)
	mov ah, 0
	mov al, 13h
	int 10h
	
	; 1 pixel op scherm = 1 byte in videogeheugen
	; videogeheugen ---> 0A0000h ---> array van bytes/pixels
	
	mov edi, VIDMEMADR
	mov al, 15
	mov [edi], al
	add edi, 2*SCRWIDTH+10
	mov [edi], al
	
	; Procedure om bal te tekenen
	; twee argumenten in de vorm van een y-waarde en x-waarde
	; ===>	add EDI, y_val * 320 + x_val
	PROC drawBall
	  ARG @@y_val:word, @@x_val:word
	  USES ebx, ecx, edx
	  
	  ...
	  
	ENDP drawBall
	  
	; Procedure om peddel te tekenen  
	PROC drawPaddle
	  ARG @@y_val:word, @@x_val:word
	  USES ebx, ecx, edx
	  
	  ...
	  
	ENDP drawPaddle
	  

; -------------------------------------------------------------------
; DATA
; -------------------------------------------------------------------
DATASEG

; -------------------------------------------------------------------
; STACK
; -------------------------------------------------------------------
STACK 100h

END start
