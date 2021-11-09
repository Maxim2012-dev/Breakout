IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

; -------------------------------------------------------------------
; CODE
; -------------------------------------------------------------------
CODESEG

start:
     sti  ; Set the interrupt flag => enable interrupts.
     cld  ; Clear the direction flag => auto-increment source
          ; and destination indices.

	mov	eax, 43512  ; eax holds input integer
	mov	ebx, 10		; divider
	xor ecx, ecx	; counter for digits to be printed

	; Store digits on stack
getNextDigit:
	inc	ecx         ; increase digit counter
	xor edx, edx
	div	ebx   		; divide by 10
	push dx			; store remainder on stack
	test eax, eax	; {cmp eax, 0} check whether zero?
	jnz	getNextDigit

    ; Write all digits to the standard output
	mov	ah, 2h 		; Function for printing single characters.
printDigits:		
	pop dx
	add	dl,'0'      	; Add 30h => code for a digit in the ASCII table, ...
	int	21h            	; Print the digit to the screen, ...
	loop printDigits	; Until digit counter = 0.
	
	mov	dl, 0Dh		; Carriage return.
	int	21h
	mov	dl, 0Ah		; New line.
	int 21h

terminate:
	; Wait for keystroke and read character.
    mov ah,0h
    int 16h

	; Terminate process with return code in response to a keystroke.
	mov	ax,4C00h
	int 21h

; -------------------------------------------------------------------
; DATA
; -------------------------------------------------------------------
DATASEG

; -------------------------------------------------------------------
; STACK
; -------------------------------------------------------------------
STACK 100h

END start
