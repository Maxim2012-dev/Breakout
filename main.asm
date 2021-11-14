; -------------------------------------------------------------------
; 80386
; 32-bit x86 assembly language
; TASM
;
; auteurs:		Fernandes Medeiros Alexandre,
;				Lino Brabants Maxim
; programma:	Breakout
; -------------------------------------------------------------------

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
	

; -------------------------------------------------------------------
; DATA
; -------------------------------------------------------------------
DATASEG

; -------------------------------------------------------------------
; STACK
; -------------------------------------------------------------------
STACK 100h

END start
