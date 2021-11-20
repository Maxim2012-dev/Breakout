IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

;; 1 cel wordt voorgesteld als 4 pixels op 4 pixels.
CELLWIDTH EQU 4		; celbreedte
CELLHEIGHT EQU 4	; celhoogte
CELLSIZE EQU 16

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
	position dd 0	; position struct -> x -en y-coördinaat
	health db 3
	sprite dd 0		; pointer naar sprite image
ENDS paddle


STRUC ball
	position dd 0	; position struct -> x -en y-coördinaat
	sprite dd 0		; pointer naar sprite image
ENDS ball


STRUC stone
	index_position db 0		; index in grid
	color db 0
	sprite dd 0		; pointer naar sprite image
ENDS stone	

DATASEG

; -------------------------------------------------------------------
; STACK
; -------------------------------------------------------------------
STACK 100h

END start