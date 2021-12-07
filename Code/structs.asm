IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

INCLUDE "global.asm"

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

STRUC Position ; (in cellen)
	x db 0		
	y db 0
ENDS Position

STRUC Ball
	position 	Position < 0, 0 >
	breadth		db BALLWIDTH/CELLWIDTH ; (in cellen)
	height		db BALLHEIGHT/CELLHEIGHT
	sprite 		dd 0
ENDS Ball

STRUC Paddle
	position 	Position < 0, 0 > ;  x- en y-coördinaat
	breadth 	db PADDLEWIDTH/CELLWIDTH ; aangezien width een keyword is, gebruiken we breadth
	height 		db PADDLEHEIGHT/CELLHEIGHT
	health 		db 3
	sprite 		dd 0	; pointer naar sprite image
ENDS Paddle

STRUC Stone
	index_position 	db 0		; index in grid
	breadth			db STONEWIDTH/CELLWIDTH
	height			db STONEHEIGHT/CELLHEIGHT
	color 			db 0
	sprite 			dd 0
ENDS Stone	

DATASEG

; INSTANTIES VAN STRUCTS MAKEN

x position 10 dup < 1, 2 > ; een lijst van 10 position structs
y position < , > ; een position struct met de standaardwaarden (d.w.z. 0 en 0)

; -------------------------------------------------------------------
; STACK
; -------------------------------------------------------------------
STACK 100h

END start