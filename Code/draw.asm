; Vragen voor assistent:

; 1. Moeten we onze code opdelen in verschillende bestanden of is het oké als we dit goed organiseren in één bestand, zoals u het doet voor de WPO-oefeninge? 
;    Want we hebben eigenlijk toch nog niet gezien hoe je procedure/macro's moet providen en importeren.
; 2. Hoe kunnen we een afbeelding kopiëren naar onze scherm, bestaat daar een instructie voor?
; 3. Mag de collision-check tussen de verschillende spelelementen gebeuren a.d.h.v. de bitmaps en zo controleren of er pixels overlappen, is moeilijk of valt het mee?
; 4. Waar kunnen we het standaard kleurenpalet terugvinden, zodat we weten welke index met welke kleur overeenkomt?
; 5. Hoe moeten we ons spellogica en tekenlogica van mekaar scheiden? 
; 	 Want bij ons pp1 stelde ik een cel in mijn spellogica voor als bv. 20x20 pixels en aangezien al mijn spelelementen dezelfde grootte hadden, namelijk 1 cel was het niet te moeilijk,
;    maar we zien hier nog niet goed hoe we aan de slag moeten  

; Mogelijke oplossingen:
; 1. het moet niet, maar moet wel georganiseerd zijn 
; 2. C code omvormen naar binary file
; 3. we zullen het a.d.h.v. cellen checken
; 4. zie compendium
; 5. Ik dacht misschien om hetzelfde te doen en 1 cel voor te stellen als 4x4 pixels


; Gebruikte kleuren voor sprites:
;
; BALL: (255, 255, 255) wordt (63, 63, 63) DENK AAN OMWISSELING => index 15
;
; PADDLE: (21, 63, 63) => index 11
;
; RECTANGLES:
;
; blauw = (0, 0, 63) => index 32
; rood = (63, 0, 0) => index 40
; groen = (0, 63, 0) => index 48
; geel = (63, 63, 0) => index 44


IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

INCLUDE "keyb.inc"		; library custom keyboard handler

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

...

ENDP openFile

PROC closeFile

...

ENDP closeFile

PROC readChunk

...

ENDP readChunk

PROC main
	sti            
    cld            

	 call setVideoMode, 13h
	 call __keyb_installKeyboardHandler
	 
	 mov EDI, 0A0000h
	 xor ax ax
	 
	 ; Alle spelcomponenten tekenen (pedel, bal, grid van stenen).
	 ; Vervolgens in de spellus gaan.
	 
	 @@gameloop
		
		mov al, [offset __keyb_keyboardState + 4Dh]		; state van rechterpijl bijhouden
		cmp al 1
		je moveRight
		
		mov al, [offset __keyb_keyboardState + 4Bh]		; state van linkerpijl bijhouden
		cmp al 1
		je moveLeft
		
		moveRight:
		; call movePaddleRight
		mov bl, 15
		add edi, 2*320+[ax]
		mov [edi], bl
		
		moveLeft:
		; call movePaddleLeft
		mov bl, 15
		add edi, 2*320+[ax]
		mov [edi], bl
		
		
	 loop @@gameloop
	
ENDP main
	  

; -------------------------------------------------------------------
; DATA
; -------------------------------------------------------------------
DATASEG

; -------------------------------------------------------------------
; STACK
; -------------------------------------------------------------------
STACK 100h

END main
