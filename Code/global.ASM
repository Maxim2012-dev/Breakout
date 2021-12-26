IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

; constants a.d.h.v. macro's
VIDMEMADR	EQU 0A0000h		; videogeheugenadres
SCRWIDTH 	EQU 320			; schermbreedte (in pixels)
SCRHEIGHT 	EQU 200			; schermhoogte

BALLWIDTHPX 	EQU 8 											; breedte van sprite (in pixels)
BALLHEIGHTPX 	EQU 8 											; hoogte van sprite (in pixels)
BALLSIZEPX 		EQU BALLWIDTHPX*BALLHEIGHTPX 					; (in pixels)
BALLWIDTHCELL 	EQU BALLWIDTHPX/CELLWIDTH
BALLHEIGHTCELL 	EQU BALLHEIGHTPX/CELLHEIGHT
BALLSTARTX 		EQU (BOARDWIDTH-BALLWIDTHCELL)/2				; startpositie x-coördinaat (in cellen)
BALLSTARTY 		EQU PADDLESTARTY - BALLHEIGHTCELL				; startpositie y-coördinaat (in cellen)

PADDLEWIDTHPX 		EQU 40 										; breedte van sprite (in pixels)
PADDLEHEIGHTPX 		EQU 8 										; hoogte van sprite (in pixels)
PADDLESIZEPX		EQU PADDLEWIDTHPX*PADDLEHEIGHTPX 			; (in pixels)
PADDLEWIDTHCELL 	EQU PADDLEWIDTHPX/CELLWIDTH
PADDLEHEIGHTCELL	EQU PADDLEHEIGHTPX/CELLHEIGHT
PADDLESTARTX 		EQU (BOARDWIDTH-PADDLEWIDTHCELL)/2		 	; startpositie x-coördinaat (in cellen) 
PADDLESTARTY 		EQU BOARDHEIGHT-PADDLEHEIGHTCELL-4			; startpositie y-coördinaat (in cellen)

STONEWIDTHPX 	EQU 32											; breedte van sprite (in pixels)
STONEHEIGHTPX 	EQU 12 											; hoogte van sprite (in pixels)
STONESIZEPX 	EQU STONEWIDTHPX*STONEHEIGHTPX
STONEWIDTHCELL	EQU STONEWIDTHPX/CELLWIDTH
STONEHEIGHTCELL EQU STONEHEIGHTPX/CELLHEIGHT
; coördinaten van eerste steen 
STONESSTARTX 	EQU (BOARDWIDTH - COLSTONES*STONEWIDTHCELL)/2 	; startpositie x-coördinaat (in cellen) 
STONESSTARTY 	EQU 4 											; startpositie y-coördinaat (in cellen) 
COLSTONES 		EQU 6
ROWSTONES 		EQU 6
NRCOLOURS 		EQU 3
ROWSPERCOLOUR 	EQU ROWSTONES/NRCOLOURS

; 1 cel wordt voorgesteld als 4 pixels x 4 pixels.
CELLWIDTH 	EQU 4	; celbreedte
CELLHEIGHT 	EQU 4	; celhoogte

BOARDWIDTH 	EQU SCRWIDTH/CELLWIDTH ; spelbord breedte (in cellen)
BOARDHEIGHT EQU SCRHEIGHT/CELLHEIGHT

; gebruikt bij het displayen van een message
MESSAGEROW EQU 13
MESSAGECOL EQU 15	

GAMEOVER 	EQU 1
WON 		EQU 2

; bewegingsrichtingen

LEFT 	EQU 0
RIGHT 	EQU 1
UP 		EQU 2
DOWN 	EQU 3

; -------------------------------------------------------------------
; CODE
; -------------------------------------------------------------------
CODESEG

STRUC Ball
	x			db BALLSTARTX ; min_x: 0, max_x: 78 (in cellen)
	y			db BALLSTARTY ; min_y: 0, max_y: 48
	active		db 0 ; 0 bal beweegt nog niet alleen (beweegt dus samen met paddle), 1 bal beweegt wel alleen
	x_sense		db LEFT
	y_sense		db UP
ENDS Ball

STRUC Paddle
	x 			db PADDLESTARTX
	y 			db PADDLESTARTY
	lives 		db 3 
ENDS Paddle

STRUC Stone
	alive			db 1
ENDS Stone

; -------------------------------------------------------------------
; DATA
; -------------------------------------------------------------------
DATASEG

; -------------------------------------------------------------------
; STACK
; -------------------------------------------------------------------
STACK 100h

