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

; oproep call print_array, PADDLESIZE, offset paddle_array