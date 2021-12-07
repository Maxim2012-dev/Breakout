IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

; constants a.d.h.v. macro's
VIDMEMADR EQU 0A0000h	; videogeheugenadres
SCRWIDTH EQU 320		; schermbreedte (in pixels)
SCRHEIGHT EQU 200		; schermhoogte

BALLWIDTH EQU 8 ; (in pixels)
BALLHEIGHT EQU 8
BALLSIZE EQU BALLWIDTH*BALLHEIGHT

PADDLEWIDTH EQU 40
PADDLEHEIGHT EQU 8
PADDLESIZE EQU PADDLEWIDTH*PADDLEHEIGHT

STONEWIDTH EQU 32
STONEHEIGHT EQU 12
STONESIZE EQU STONEWIDTH*STONEHEIGHT

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

