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
; BALL: (255, 255, 255)
;
; PADDLE: (7, 177, 238) 
;
; RECTANGLES:
;
; lichtere blauw = (12, 61, 178), donkerdere blauw = (5, 32, 96)
; lichtere rood = (154, 6, 32), donkerdere rood = (99, 7, 24)
; lichtere groen = (10, 111, 3), donkerdere groen = (6, 67, 2)
; lichtere oranje = (191, 112, 6), donkerdere oranje = (141, 84, 7)


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
