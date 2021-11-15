
IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

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
	
	mov EDI, 0A0000h
	mov AL, 15
	mov [EDI], AL
	add EDI, 2*320+10
	mov [EDI], AL
	
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
