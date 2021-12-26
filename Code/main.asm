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
INCLUDE "algeproc.asm"
; -------------------------------------------------------------------
; CODE
; -------------------------------------------------------------------
CODESEG

;; # SPELLOGICA #

PROC movePaddleLeft
	USES ebx
	mov ebx, offset paddle_object
	cmp [ebx + Paddle.x], 0 			; Paddle linkergrens scherm?
	je SHORT @@end
	dec [ebx + Paddle.x]
	mov ebx, offset ball_object			
	cmp [ebx + Ball.active], 1			; Beweegt bal mee? Dit gebeurt enkel wanneer de bal nog niet actief is.
	je SHORT @@end
	dec [ebx + Ball.x]					; bal mee bewegen
@@end:
	ret
ENDP movePaddleLeft

PROC movePaddleRight
	USES ebx
	mov ebx, offset paddle_object
	cmp [ebx + Paddle.x], BOARDWIDTH-PADDLEWIDTHCELL	; Paddle rechtergrens scherm? 
	je SHORT @@end
	inc [ebx + Paddle.x]
	mov ebx, offset ball_object
	cmp [ebx + Ball.active], 1
	je SHORT @@end
	inc [ebx + Ball.x]									; bal naar rechts bewegen
@@end:
	ret
ENDP movePaddleRight

; Blijven er nog stenen over?
; Ja => eax = 0, doorgeven aan moveBall die het doorgeeft aan gamelogistic zodat de gameloop uiteindelijk niet stopt
; Nee => eax = 2 (waarde van macro WON), gameloop wordt onderbroken, aangezien de speler dan heeft gewonnen en het spel gedaan is

PROC StonesAlive  
	ARG RETURNS eax
	USES ebx, ecx, edx
	mov ebx, offset stones_array
	xor ecx, ecx						; counter initialiseren
	mov edx, ROWSTONES * COLSTONES	
@@loop:
	cmp [ebx + Stone.alive], 0			; Steen "levend"? Indien een steen "levend" is, weten we dat alle stenen nog niet werden vernietigd en heeft de speler dus nog niet gewonnen.
	je SHORT @@nextIteration
	xor eax, eax
	ret
@@nextIteration:
	inc ebx								; ga naar volgende steen-object
	inc ecx
	cmp ecx, edx
	jl @@loop
@@end:
	mov eax, WON
	ret

ENDP StonesAlive

; Index van bijhorende steen in array bepalen a.d.h.v. volgende formule: ((xPos - STONESSTARTX)  / STONEWIDTHCELL) + COLSTONES * ((yPos - STONESSTARTY) / STONEHEIGHTCELL), waarbij xPos en yPos de coördinaten van een "hoekpunt" van de bal voorstellen
; Wanneer we vervolgens het bijhorend steen-object vast hebben, controleren we of deze nog "levend" is of niet.
; Het resultaat geven we vervolgens in register eax terug: 
;	1 staat voor de steen bestaat
;   0 staat voor de steen is al vernietigd geweest

PROC StoneAlive 
	ARG @@xPos:byte, @@yPos:byte RETURNS eax
	USES ebx, ecx, edx
	movzx eax, [@@xPos]
	sub eax, STONESSTARTX
	mov ecx, STONEWIDTHCELL
	xor edx, edx
	div ecx
	mov ebx, eax 						; eerst gedeelte van bewerking in ebx steken
	movzx eax, [@@yPos]
	sub eax, STONESSTARTY
	mov ecx, STONEHEIGHTCELL
	xor edx, edx
	div ecx 							; quotiënt komt in eax
	mov edx, COLSTONES
	mul edx
	add eax, ebx 						; index van steen zit in eax 
	mov ebx, offset stones_array
	add ebx, eax 						; juiste stone-object accessen (elke stone-object is maar 1 byte groot)
	movzx eax, [ebx + Stone.alive] 		; resultaat in eax steken
	mov [ebx + Stone.alive], 0			; steen vernietigen (misschien was deze al vernietigd, maar dit kan geen kwaad, dan wordt gwn dezelfde waarde weer geschreven)
	ret
ENDP StoneAlive

; Is er overlapping tussen de bal en minstens één steen?
; We controleren eerst of de bal zich binnen de grote blok van stenen bevindt.
; Zo ja, dan controleren we of de steen op die plaats nog "levend" is of niet a.d.h.v. de procedure "StoneAlive"
; Zo nee, dan is er geen botsing mogelijk en wordt de waarde 0 in eax gestoken

PROC CheckCollisionStone
	ARG @@xPosBall:byte, @@yPosBall:byte RETURNS eax
	USES ebx, ecx, edx
	cmp [@@yPosBall], STONESSTARTY			; we vergelijken eerst de y-coördinaten omdat er minder kans is dat deze matchen, aangezien de blok stenen breder is dan dat ze hoog is
	jl SHORT @@noCollision
	cmp [@@yPosBall], STONESSTARTY + STONEHEIGHTCELL*ROWSTONES
	jge SHORT @@noCollision				
	cmp [@@xPosBall], STONESSTARTX			; als men hier terecht komt, weet men al dat de y-coördinaten matchen, nu checkt men de x-coördinaten
	jl SHORT @@noCollision
	cmp [@@xPosBall], STONESSTARTX + STONEWIDTHCELL*COLSTONES
	jge SHORT @@noCollision
	movzx eax, [@@xPosBall] 				; als men hier terecht komt, hebben we een volledige match, de bal bevindt zich dus in de grote blok stenen (misschien is de steen op die plaats wel al verdwenen)
	movzx ebx, [@@yPosBall]
	call StoneAlive, eax, ebx				; controleren of de steen op die plaats nog "levend" is
	ret

@@noCollision:
	xor eax, eax
	ret
ENDP CheckCollisionStone

; Bal laten bewegen, hier worden alle condities voor het bewegen van een bal gecontroleerd.
; Geldt voor alle bewegingsrichtingen:
; 		- Checken of de bal niet tegen de bijhorende schermgrens botst (linker schermgrens voor linkse beweging enz.)
;		- Checken of de bal niet een steen vernietigde door deze te raken, zo ja => checken of er nog stenen overblijven
; 				- Voor deze collision check moeten we steeds te werk gaan met de twee bijhorende "hoekpunten" van de bal (twee linkse "hoekpunten" voor linkse beweging enz.) zie verduidelijking verslag indien nodig 
; Beweging naar beneden is een speciaal geval:
;		- Indien men zich juist boven de paddle bevindt dan checkt 
; Resultaat:
; 	- eax bevat waarde 0 indien het spel verder gaat
;	- eax bevat waarde 1 indien de speler heeft verloren
;	- eax bevat waarde 2 indien de speler heeft gewonnen

PROC moveBall

	ARG RETURNS eax
	USES ebx, ecx, edx
	mov ebx, offset ball_object
	movzx ecx, [ebx + Ball.x]
	movzx edx, [ebx + Ball.y]
	cmp [ebx + Ball.x_sense], RIGHT
	je SHORT @@handleMoveRight
	
@@handleMoveLeft:
	test ecx, ecx 							; equivalent aan "comp ecx, 0", checken of er geen botsing is met de linker schermgrens
	jz SHORT @@leftToRight 					; gevolgd door "je SHORT @@leftToRight"
	dec ecx 								; simulatie van beweging naar links, zodat men controleert of er een overlapping zou zijn bij beweging, voordat men de beweging echt uitvoert
	call CheckCollisionStone, ecx, edx
	push eax 								; resultaat van eerste call OP STACK plaatsen
	add edx, BALLHEIGHTCELL 				; zie indien nodig verantwoording figuur1 deel 3.5 van verslag 
	call CheckCollisionStone, ecx, edx
	pop ecx 								; resultaat van eerste call VAN STACK halen
	or eax, ecx
	test eax, eax 							; Heeft minstens één van de 2 hoekpunten van de bal een steen geraakt/vernietigd? Zo nee, beweeg
	jz SHORT @@moveLeft
	call StonesAlive 						; checken of er nog stenen overblijven, aangezien er minstens één werd vernietigd
	test eax, eax
	jz SHORT @@leftToRight					; Zo nee, dan bevat eax waarde 1 (komt overeen met waarde van macro "WON") en is de spel gedaan
	ret
@@moveLeft:
	dec [ebx + Ball.x]
	jmp SHORT @@handleMoveVertical
@@leftToRight:
	mov [ebx + Ball.x_sense], RIGHT
	jmp SHORT @@handleMoveVertical

@@handleMoveRight:
	cmp ecx, BOARDWIDTH-BALLWIDTHCELL
	je SHORT @@rightToLeft
	inc ecx 								; simulatie van beweging naar rechts
	add ecx, BALLWIDTHCELL 					; zie indien nodig verantwoording figuur1 deel 3.5 van verslag
	call CheckCollisionStone, ecx, edx
	push eax
	add edx, BALLHEIGHTCELL 				; zie indien nodig verantwoording figuur1 deel 3.5 van verslag
	call CheckCollisionStone, ecx, edx
	pop ecx
	or eax, ecx
	test eax, eax
	jz SHORT @@moveRight
	call StonesAlive
	test eax, eax
	jz SHORT @@rightToLeft
	ret
@@moveRight:
	inc [ebx + Ball.x]
	jmp SHORT @@handleMoveVertical
@@rightToLeft:
	mov [ebx + Ball.x_sense], LEFT

@@handleMoveVertical:
	movzx ecx, [ebx + Ball.x]
	movzx edx, [ebx + Ball.y]
	cmp [ebx + Ball.y_sense], UP
	je SHORT @@handleMoveUp
	jmp SHORT @@handleMoveDown
	
@@handleMoveUp:
	test edx, edx
	jz SHORT @@upToDown
	dec edx 								; simulatie van beweging naar boven
	call CheckCollisionStone, ecx, edx
	push eax
	add ecx, BALLWIDTHCELL 					; zie indien nodig verantwoording figuur1 deel 3.5 van verslag
	call CheckCollisionStone, ecx, edx
	pop ecx
	or eax, ecx
	test eax, eax
	jz SHORT @@moveUp
	call StonesAlive
	test eax, eax
	jz SHORT @@upToDown
	ret
@@moveUp:
	dec [ebx + Ball.y]
	jmp @@end
@@upToDown:
	mov [ebx + Ball.y_sense], DOWN
	jmp @@end
	
@@handleMoveDown:
	cmp [ebx + Ball.y], PADDLESTARTY-BALLHEIGHTCELL
	jg SHORT @@belowPaddle
	jl SHORT @@checkCollisionStone
	; collision met paddle checken, volgens x-coördinaat aangezien we dankzij de bovenstaande checks al weten dat de y-coördinaat matcht
	mov edx, offset paddle_object
	movzx ecx, [edx + Paddle.x]
	sub ecx, BALLWIDTHCELL 						; x-coördinaat van de ball met BALLWIDTHCELL verhogen is equivalent met de x-coördinaat van de paddle met BALLWIDTHCELL verminderen
	cmp [ebx + Ball.x], cl
	jl SHORT @@moveDown							; er is geen botsing, de ball zit links van de paddle
	movzx ecx, [edx + Paddle.x]
	add ecx, PADDLEWIDTHCELL
	cmp [ebx + Ball.x], cl
	jg SHORT @@moveDown							; er is geen botsing, de ball zit rechts van de paddle
	jmp SHORT @@downToUp
@@checkCollisionStone:
	inc edx 									; simulatie van beweging naar beneden
	add edx, BALLHEIGHTCELL 					; zie indien nodig verantwoording figuur1 deel 3.5 van verslag
	call CheckCollisionStone, ecx, edx
	push eax
	add ecx, BALLWIDTHCELL 						; zie indien nodig verantwoording figuur1 deel 3.5 van verslag
	call CheckCollisionStone, ecx, edx
	pop ecx
	or eax, ecx
	test eax, eax
	jz SHORT @@moveDown
	call StonesAlive
	test eax, eax
	jz SHORT @@downToUp
	ret
@@moveDown:
	inc [ebx + Ball.y]
	jmp SHORT @@end
@@downToUp:
	mov [ebx + Ball.y_sense], UP
	jmp SHORT @@end
@@belowPaddle:
	mov edx, offset paddle_object
	cmp [ebx + Ball.y], BOARDHEIGHT-BALLHEIGHTCELL 	; checken of er geen botsing is met de onder schermgrens
	jne @@moveDown
	dec [edx + Paddle.lives]						; indien er wel een botsing was, verminder het aantal levens van de speler/peddel en ga na of deze er nog heeft
	cmp [edx + Paddle.lives], 0
	jg SHORT @@newChance
	mov eax, GAMEOVER
	ret
@@newChance:										; indien de speler/peddel nog levens had, krijgt deze een nieuwe kans en wordt de bal en peddel weer op de startpositie geplaatst 
	mov [ebx + Ball.x], BALLSTARTX
	mov [ebx + Ball.y], BALLSTARTY
	mov [ebx + Ball.active], 0
	mov [edx + Paddle.x], PADDLESTARTX
	mov [edx + Paddle.y], PADDLESTARTY
	
@@end:
	xor eax, eax
	ret
ENDP moveBall

PROC gamelogistic
	ARG RETURNS eax
	USES ebx
	xor eax, eax
	
	mov ebx, offset ball_object
	cmp [ebx + Ball.active], 0
	je SHORT @@handle_input							; indien de bal niet actief is, slaag het gedeelte waar men deze laat bewegen over
	and cl, 1
	jnz SHORT @@handle_input						; zodat de bal minder snel beweegt (beweegt maar één op de twee keer)
	call moveBall									; bal beweegt enkel alleen als deze actief is (en de counter even is)
	test eax, eax
	jnz SHORT @@end

@@handle_input:
	cmp [offset __keyb_keyboardState + 39h], 1		; spatiebalk ingedrukt? 
	je SHORT @@makeBallActive
		
	cmp [offset __keyb_keyboardState + 4Dh], 1		; rechterpijl ingedrukt?
	je SHORT @@moveRight
		
	cmp [offset __keyb_keyboardState + 4Bh], 1		; linkerpijl ingedrukt?
	je SHORT @@moveLeft
	
	jmp SHORT @@end

@@makeBallActive:
	mov [ebx + Ball.active], 1						; bal activeren
	jmp SHORT @@end
@@moveRight:
	call movePaddleRight
	jmp SHORT @@end
@@moveLeft:
	call movePaddleLeft
	
@@end:
	ret
ENDP gamelogistic

;; # TEKENLOGICA #

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
	mov ebx, offset stones_array
	xor ecx, ecx			; counter op 0 zetten	
@@drawLoop:
	cmp [ebx + Stone.alive], 1
	jne SHORT @@nextIteration	; indien de steen niet meer "levend" is, mag je deze niet meer tekenen
	push ebx				; pointer naar struct OP STACK
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
	mov eax, ecx
	mov ecx, COLSTONES*ROWSPERCOLOUR
	; (offset_eerste_sprite + kleur_index * grootte_sprite)
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
	pop ebx					; pointer naar struct VAN STACK
@@nextIteration:
	inc ebx					; naar volgende struct gaan
	inc ecx
	cmp ecx, COLSTONES*ROWSTONES
	jl @@drawLoop
	ret
ENDP drawStones

; gebruikt om messages te displayen
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

; aantal levens van speler/peddel in de linkerbovenhoek van het scherm displayen
PROC displayLives
	USES ebx, edx
	mov ebx, offset paddle_object
	movzx edx, [ebx + Paddle.lives]
	add dl, '0'										; omzetten naar karakter
	mov [levens_string + 8], dl
	call displayString, 0, 0, offset levens_string
	ret
ENDP displayLives
	
PROC drawlogistic
	call displayLives
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
	
	xor eax, eax		; eax gebruikt om te checken of het spel verder gaat (ja = 0 en nee = andere)
	xor ecx, ecx		; gebruikt zodat onze bal trager beweegt (beweegt maar één op de twee keer)
	
	;; ------ GAME LOOP ------
	; De procedure gamelogistic geeft een waarde terug in eax, indien deze gelijk is aan 0 gaat het spel verder,
	;														   indien deze gelijk is aan 1 heeft de speler verloren,
	;														   anders (indien deze gelijk is aan 2) heeft de speler gewonnen 
@@gameloop:
	
	call wait_VBLANK
	call fillBackground, 0 ; achtegrond zwart maken
	call gamelogistic
	call drawlogistic
	
	inc ecx
	test eax, eax
	jz @@gameloop
	;; ------------------------
	
	cmp eax, GAMEOVER
	je SHORT @@displayGameOver
	
@@displayWin:
	call displayString, MESSAGEROW, MESSAGECOL, offset winning_string
	jmp SHORT @@waitForEscape
@@displayGameOver:
	call displayString, MESSAGEROW, MESSAGECOL, offset game_over_string
@@waitForEscape:	
	call waitForSpecificKeystroke, 001Bh ; wacht tot de escape-toets wordt ingedrukt
	call terminateProcess
ENDP main
	  

; -------------------------------------------------------------------
; DATA
; -------------------------------------------------------------------

DATASEG
	ball_object 	Ball < >
	paddle_object 	Paddle < >
	stones_array    Stone COLSTONES*ROWSTONES dup (< >)
	
	ball_file 		db "ball", 0
	paddle_file		db "paddle", 0
	bstone_file		db "bstone", 0
	gstone_file 	db "gstone", 0
	rstone_file		db "rstone", 0
	
	openErrorMsg 		db "could not open file", 13, 10, '$'
	readErrorMsg 		db "could not read data", 13, 10, '$'
	closeErrorMsg 		db "error during file closing", 13, 10, '$'
	levens_string		db "Levens: ", 7, 10, '$'
	game_over_string	db "GAME OVER!", 10, 10, '$'
	winning_string		db "YOU WON!", 8, 10, '$'
	
UDATASEG ; unitialised datasegment, zoals declaratie in C
	filehandle dw ? ; Één filehandle, herbruikt voor de verschillende bestanden
	ball_array db BALLSIZEPX dup (?)
	paddle_array db PADDLESIZEPX dup (?)
	bstone_array db STONESIZEPX dup (?)
	gstone_array db STONESIZEPX dup (?)
	rstone_array db STONESIZEPX dup (?)
; -------------------------------------------------------------------
; STACK
; -------------------------------------------------------------------
STACK 100h

END main