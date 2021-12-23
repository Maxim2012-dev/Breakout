PROC print_byte
	ARG	@@printval:byte
	USES eax, ebx, ecx, edx

	movzx eax, [@@printval]
	mov	ebx, 10		; divider
	xor ecx, ecx	; counter for digits to be printed

	; Store digits on stack
@@getNextDigit: 
	inc	ecx         ; increase digit counter
	xor edx, edx
	div	ebx   		; divide eax by 10
	push dx			; store remainder on stack
	test eax, eax	; check whether zero?
	jnz	@@getNextDigit

    ; Write all digits to the standard output
	mov	ah, 2h 		; Function for printing single characters.
@@printDigits:		
	pop dx
	add	dl,'0'      	; Add 30h => code for a digit in the ASCII table, ...
	int	21h            	; Print the digit to the screen, ...
	loop @@printDigits	; Until digit counter = 0.
	
	ret
ENDP print_byte

PROC print_array
	ARG	@@arraylength:word, @@arrayptr:dword
	USES eax, ebx, ecx, edx
	
	movzx ecx, [@@arraylength]
	mov ebx, [@@arrayptr]
	
	mov	ah, 2h 		; Function for printing single characters.
@@printInt:
	call print_byte, [dword ptr ebx] ; dit moet je vermelden aangezien de compiler niet weet hoe groot de waarde is
	mov dl, ','
	int	21h		; print comma
	mov dl, ' '
	int 21h		; print space
	inc ebx		; ga naar volgende integer, elke getal wordt bij ons voorgesteld a.d.h.v. één byte (dus ebx + 1)
	loop @@printInt	; loop over all integers
	
	mov	dl, 0Dh		; Carriage return.
	int	21h
	mov	dl, 0Ah		; New line.
	int 21h
	
	ret
ENDP print_array

;; Indexen juist zetten
PROC initStones
	USES ebx, ecx
	mov ecx, COLSTONES*ROWSTONES
	mov ebx, offset stones_array
	add ebx, COLSTONES*ROWSTONES*2
@@arrayLoop:	
	mov [ebx + Stone.index], cl
	sub ebx, 2				; naar vorige struct gaan (we lopen in omgekeerde richting door de array, om gebruik te maken van ecx)
	loop @@arrayLoop
	ret
ENDP initStones

PROC printStones
	USES eax, ebx, ecx
	mov ecx, COLSTONES*ROWSTONES
	mov ebx, offset stones_array
@@littleloop:
	movzx eax, [ebx + Stone.index]
	call print_byte, eax
	add ebx, 2
	loop @@littleloop
	ret
ENDP printStones

; PROCEDURE DIE OBJECTEN TEKENT (WERKT NOG MET PIXELS)
PROC drawObject ; TODO -- cellen omvormen naar pixels
	ARG @@XPOS:byte, @@YPOS:byte, @@SPRITE:dword	; herriner: x- en y-coördinaat worden voorgesteld in cellen, omzetting naar pixels moet nog gebeuren
	USES esi, eax, ebx, ecx, edx, edi
	mov edi, VIDMEMADR
	mov esi, [@@SPRITE]
	mov eax, SCRWIDTH
	movzx ebx, [@@YPOS]
	mul ebx
	add al, [@@XPOS]
	add edi, eax
	mov edx, BALLHEIGHT	 			; TODO -- Generisch maken
	
	@@row_loop:			; voor alle rijen in sprite	
		mov ecx, BALLWIDTH		; aantal bytes voor 'rep movsb'		; TODO -- Generisch maken
		rep movsb					; bytes van huidige rij in sprite kopiëren naar videogeheugen
			
		add edi, SCRWIDTH-BALLWIDTH	; naar volgende rij gaan in videogeheugen
		dec edx
		jnz @@row_loop
		
	ret
ENDP drawObject

PROC drawStones ; PROCEDURE MAXIM
	USES eax, ebx, ecx, edx
	;mov ebx, offset stones_array		; hebben we later miss nog nodig om te checken of de stenen 'alive' zijn
	mov ecx, COLSTONES*ROWSTONES	
@@drawLoop:
	push ecx				; counter OP STACK
	; posx = STONESSTARTX + (index_position%COLSTONES) * STONEWIDTHCELL					
	mov eax, COLSTONES*ROWSTONES			; huidige index in stones_array (in begin : 36-36 = 0)
	sub eax, ecx
	push eax				; index OP STACK
	mov ecx, COLSTONES
	xor edx, edx			; niet op 0 zetten = error
	div ecx
	mov eax, STONEWIDTHCELL
	mul edx
	add eax, STONESSTARTX
	pop ecx					; index VAN STACK
	push eax				; x-coördinaat OP STACK
	; posy = STONESSTARTY + (index_position/COLSTONES) * STONEHEIGHTCELL
	mov eax, ecx
	push ecx				; index terug OP STACK
	mov ecx, COLSTONES
	xor edx, edx			; niet op 0 zetten = error
	div ecx
	mov edx, STONEHEIGHTCELL
	mul edx
	add eax, STONESSTARTY   ; eax bevat y-coördinaat
	pop ecx					; index VAN STACK
	push eax				; y-coördinaat OP STACK
	xor edx, edx
	mov eax, ecx
	mov ecx, COLSTONES*ROWSPERCOLOUR
	div ecx							; index / 12 ---> eax
	mov ebx, offset bstone_array	; offset eerste sprite in geheugen
	mov ecx, STONESIZEPX
	mul ecx
	add ebx, eax
	pop eax
	pop edx							; x-coördinaat VAN STACK
	call drawObject, edx, eax, ebx, STONEWIDTHPX, STONEHEIGHTPX
	pop ecx							; counter VAN STACK
	;inc ebx				; naar volgende struct gaan
	loop @@drawLoop
	ret
ENDP drawStones

PROC drawStones ; EERSTE POGING (SLECHTE) VERBETERING ALEXANDRE
	USES eax, ebx, ecx, edx
	;mov ebx, offset stones_array		; hebben we later miss nog nodig om te checken of de stenen 'alive' zijn
	mov ecx, COLSTONES*ROWSTONES - 1	
@@drawLoop:
	push ecx				; counter OP STACK
	; posx = STONESSTARTX + (index_position%COLSTONES) * STONEWIDTHCELL
	mov eax, ecx
	mov ecx, COLSTONES
	xor edx, edx			; op 0 zetten voor deling, moet gebeuren anders error
	div ecx
	mov eax, STONEWIDTHCELL
	mul edx
	add eax, STONESSTARTX
	pop ecx					; counter VAN STACK
	push eax				; x-coördinaat OP STACK
	; posy = STONESSTARTY + (index_position/COLSTONES) * STONEHEIGHTCELL
	mov eax, ecx
	push ecx				; counter terug OP STACK
	mov ecx, COLSTONES
	xor edx, edx
	div ecx
	mov edx, STONEHEIGHTCELL
	mul edx
	add eax, STONESSTARTY 
	pop ecx					; counter VAN STACK
	push ecx				; counter OP STACK
	push eax				; y-coördinaat OP STACK
	mov eax, ecx
	mov ecx, COLSTONES*ROWSPERCOLOUR
	xor edx, edx
	div ecx
	mov ebx, offset bstone_array	; offset eerste sprite in geheugen
	mov ecx, STONESIZEPX
	mul ecx
	add ebx, eax
	pop eax					; y-coördinaat VAN STACK
	pop ecx					; counter VAN STACK
	pop edx					; x-coördinaat VAN STACK
	call drawObject, edx, eax, ebx, STONEWIDTHPX, STONEHEIGHTPX
	;inc ebx					; naar volgende struct gaan
	dec ecx
	cmp ecx, 0
	jge @@drawLoop
	ret
ENDP drawStones