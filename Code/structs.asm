IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

;; 1 cel wordt voorgesteld als 4 pixels op 4 pixels.
CELLWIDTH EQU 4		; celbreedte
CELLHEIGHT EQU 4	; celhoogte
CELLSIZE EQU CELLWIDTH*CELLHEIGHT

; -------------------------------------------------------------------
; CODE
; -------------------------------------------------------------------
CODESEG

start:
     sti            
     cld            
	  
; -------------------------------------------------------------------
; DATA
; -------------------------------------------------------------------

STRUC position
	x dw 0		
	y dw 0		; 1 byte/8 bits zou voldoende zijn, maar bij een schermhoogte groter dan 255 pixels niet meer.
ENDS position

	
STRUC paddle
<<<<<<< HEAD
	position dd 0	; position struct -> x -en y-coördinaat
	health db 3
	width db 0 		; VRAAG: IS WIDTH MISSCHIEN EEN KEYWORD IN ASSEMBLY, AANGEZIEN DEZE ANDERS KLEURT? JA
	height db 0
	sprite dd 0		; pointer naar sprite image, OPMERKING: DIT IS VOLGENS MIJ (ALEXANDRE) NIET NODIG, KLOPT HET? WANT HET WORDT WEL OP SLIDE 10 VAN WPO5 GEBRUIKT, DAARDOOR DAT WE NIET ZEKER ZIJN.
=======
	position 	dd 0	; position struct -> x -en y-coördinaat
	health 		db 3
	width 		db 0 		; VRAAG: IS WIDTH MISSCHIEN EEN KEYWORD IN ASSEMBLY, AANGEZIEN DEZE ANDERS KLEURT?
	height 		db 0
	sprite 		dd 0		; pointer naar byte array (sprite)
>>>>>>> e69bf7aa03a13ec3ceb692ab9f52447e400edf5b
ENDS paddle


STRUC ball
	position 	dd 0
	sprite 		dd 0
ENDS ball


STRUC stone
	index_position 	db 0		; index in grid
	color 			db 0
	sprite 			dd 0
ENDS stone	

DATASEG

; INSTANTIES VAN STRUCTS MAKEN

x postion 10 dup < 1, 2 > ; een lijst van 10 position structs
y position < , > ; een position struct met de 

; -------------------------------------------------------------------
; STACK
; -------------------------------------------------------------------
STACK 100h

END start