IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

; constants a.d.h.v. macro's
VIDMEMADR EQU 0A0000h	; videogeheugenadres
SCRWIDTH EQU 320		; schermbreedte (in pixels)
SCRHEIGHT EQU 200		; schermhoogte

BALLWIDTH EQU 8 									; breedte van sprite (in pixels)
BALLHEIGHT EQU 8 									; hoogte van sprite (in pixels)
BALLSIZE EQU BALLWIDTH*BALLHEIGHT 					; (in pixels)
BALLSTARTX EQU (SCRWIDTH-BALLWIDTH) / (2*CELLWIDTH) ; startpositie x-coördinaat (in cellen) 
BALLSTARTY EQU PADDLESTARTY - BALLHEIGHT/CELLHEIGHT ; startpositie y-coördinaat (in cellen)

PADDLEWIDTH EQU 40 											; breedte van sprite (in pixels)
PADDLEHEIGHT EQU 8 											; hoogte van sprite (in pixels)
PADDLESIZE EQU PADDLEWIDTH*PADDLEHEIGHT 					; (in pixels)
PADDLESTARTX EQU (SCRWIDTH-PADDLEWIDTH) / (2*CELLWIDTH) 	; startpositie x-coördinaat (in cellen) 
PADDLESTARTY EQU (SCRHEIGHT-PADDLEHEIGHT)/CELLHEIGHT - 4 	; startpositie y-coördinaat (in cellen)

STONEWIDTH EQU 32	; breedte van sprite (in pixels)
STONEHEIGHT EQU 12 	; hoogte van sprite (in pixels)
STONESIZE EQU STONEWIDTH*STONEHEIGHT
; coördinaten van eerste steen 
STONESSTARTX EQU (SCRWIDTH - COLSTONES*STONEWIDTH) / (2*CELLWIDTH) ; startpositie x-coördinaat (in cellen) 
STONESSTARTY EQU 4 	; startpositie y-coördinaat (in cellen) 
COLSTONES EQU 6
ROWSTONES EQU 6
NRCOLOURS EQU 3
ROWSPERCOLOUR EQU ROWSTONES/NRCOLOURS

;; 1 cel wordt voorgesteld als 4 pixels x 4 pixels.
CELLWIDTH EQU 4		; celbreedte
CELLHEIGHT EQU 4	; celhoogte

BOARDWIDTH EQU SCRWIDTH/CELLWIDTH ; spelbord breedte (in cellen)
BOARDHEIGHT EQU SCRHEIGHT/CELLHEIGHT

; -------------------------------------------------------------------
; CODE
; -------------------------------------------------------------------
CODESEG

; -------------------------------------------------------------------
; DATA
; -------------------------------------------------------------------
DATASEG

; -------------------------------------------------------------------
; STACK
; -------------------------------------------------------------------
STACK 100h

