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

; VRAAG: HOE MAAK JE EEN STRUC INSTANTIE AAN IN ASSEMBLY? 

STRUC position
	x dw 0		
	y dw 0		; 1 byte/8 bits zou voldoende zijn, maar bij een schermhoogte groter dan 255 pixels niet meer.
ENDS position

	
STRUC paddle
	position 	dd 0	; position struct -> x -en y-coördinaat
	health 		db 3
	width 		db 0 		; VRAAG: IS WIDTH MISSCHIEN EEN KEYWORD IN ASSEMBLY, AANGEZIEN DEZE ANDERS KLEURT?
	height 		db 0
	sprite 		dd 0		; pointer naar byte array (sprite)
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

; -------------------------------------------------------------------
; STACK
; -------------------------------------------------------------------
STACK 100h

END start