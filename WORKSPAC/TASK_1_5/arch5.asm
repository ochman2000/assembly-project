;=============================================================================;
;                                                                             ;
; Plik           : arch5.asm                                                  ;
; Format         : COM                                                        ;
; Autor          : Dariusz Puchala                                            ;
; Data utworzenia: 11.05.2003                                                 ;
; Uwagi          : Program przykladowy wykorzystujacy mozliwosci trybu        ;
;                  graficznego 13h, wyswietlajacy efekt ognia.                ;
;                                                                             ;
;=============================================================================;

                .MODEL  TINY

        ESCAPE                  EQU     01

WczytajZnak     MACRO
; Dzialanie:
;       Makro wczytuje znak z klawiatury bez echa.
; Uzywane rejestry:
;       AH
                mov     ah, 08h
                int     21h
                ENDM

WlaczTrybGraf   MACRO
; Dzialanie:
;       Makro wlacza tryb graficzny 13h oraz umieszcza w rejestrze ES segment
;       pamieci obrazu.
; Wyjscie:
;       ES - segment pami?ci obrazu
; Uzywane rejestry:
;       AX

                mov     ax, 0013h
                int     10h
                mov     ax, 0A000h
                mov     es, ax
                ENDM

WlaczTrybText   MACRO
; Dzialanie:
;       Makro wlacza tryb tekstowy 03h.
; Uzywane rejestry:
;       AX

		mov	ax, 0003h
		int	10h
		ENDM

UstawPalete	MACRO
                LOCAL   Usp00, Usp01, Usp02, Usp03
; Dzialanie:
;       Makro ustawia palete kolorow korzystajac z portow karty VGA.
; Uzywane rejestry:
;       AX, CX, DX

		mov	dx, 03C8h
		xor	ax, ax
		out	dx, al
		inc	dx
		xor	cx, cx			;  R    G  B
Usp00:
		mov	al, cl			; 0-63, 0, 0
		out	dx, al
		xor	ax, ax
		out	dx, al
		out	dx, al
		inc	cx
		cmp	cx, 39h
		jb	Usp00				
		xor	cx, cx			;  R   G    B
Usp01:
		mov	al, 39h			; 63, 0-63, 0
		out	dx, al
		mov	al, cl				
		out	dx, al
		xor	ax, ax
		out	dx, al
		inc	cx
		cmp	cx, 39h
		jb	Usp01				
		xor	cx, cx			;  R   G   B
Usp02:
		mov	al, 39h			; 63, 63, 0-63
		out	dx, al				
		out	dx, al
		mov	al, cl
		out	dx, al
		inc	cx
		cmp	cx, 39h
		jb	Usp02
		xor	cx, cx			;  R   G   B		
Usp03:
		mov	al, 39h			; 63, 63, 63
		out	dx, al				
		out	dx, al				
		out	dx, al
		inc	cx
		cmp	cx, 39h
		jb	Usp03
		ENDM

Usrednij	MACRO
                LOCAL   Nastepny
; Dzialanie:
;       Makro wykonuje filtrowanie obrazu za pomoca prostego filtra
;       dolnoprzepustowego wyliczajacego nowe wartosci pikseli na podstawie
;       aktualnych wartosci pikseli sasiadujacych. Rozpatrywany obszar
;       sasiedztwa to kwadrat 3 na 3 piksele:
;       -----------------------------------
;       | (x-1,y-1) | (x,y-1) | (x+1,y-1) |
;       -----------------------------------
;       | (x-1,y)   |  (x,y)  | (x+1,y)   |
;       -----------------------------------
;       | (x-1,y+1) | (x,y+1) | (x+1,y+1) |
;       -----------------------------------
;       Nowa warto?? piksela (x,y) obliczana jest wg. nast?puj?cej zale?no?ci:
;               nowa(x,y) = S / 9
;       gdzie:
;               S = (x-1,y-1)+(x,y-1)+(x+1,y-1)+(x-1,y)+(x,y)+(x+1,y)+
;                 + (x-1,y+1)+(x,y+1)+(x+1,y+1)
; Wejscie:
;       ES - segment pamieci obrazu
; Uzywane rejestry:
;       AX, BX, CX, DX, SI
	
		mov	si, 0FC80h
		xor	ax, ax
		xor	bx, bx
Nastepny:
		xor	dx, dx
		mov	dl, es:[si - 001h]
		add	dl, es:[si + 13Fh]
		adc	dh, 00h
		add	dl, es:[si + 27Fh]
		adc	dh, 00h
		add	ax, bx
		add	ax, dx
		mov	cx, ax
		shr	cx, 1
		add	ax, cx
		shr	cx, 1
		add	ax, cx
		shr	ax, 4
		mov     es:[si], al
		mov	ax, bx
		mov	bx, dx
		dec	si		
		cmp	si, 0AF00h
		jae	Nastepny
                ENDM

Losuj		MACRO   Ziarno
; Dzialanie:
;       Makro generuje liczby pseudolosowe.
; Parametry:
;       Ziarno - zmienna zawierajaca wartosc ziarna
; Wyjscie:
;       DX - wygenerowana liczba pseudolosowa
; Uzywane rejestry:
;       AX, DX

		mov	ax, Ziarno
		mov	dx, 8405h
		mul	dx
		inc	ax
		mov	Ziarno, ax
		ENDM

                .CODE

                ORG     100h

Start:
                jmp     Poczatek

Ziarno          DW      ?

Poczatek:
                WlaczTrybGraf
		UstawPalete				
s01:
		xor	cx, cx
		mov	bx, 0FA00h				
s02:
		Losuj   Ziarno
		and	dx, 01h
		mov	ax, 00FFh
		mul	dl
		mov	es:[bx], al		; Rysowanie pikseli o losowych
		mov	es:[bx + 140h], al	; barwach.
		inc	bx
		inc	cx
		cmp	cx, 140h
		jb	s02
		Usrednij
		in	al, 60h			; Sprawdz, czy nacisnieto
		cmp	al, ESCAPE		; klawisz Esc.
		jne	s01
                WczytajZnak                
		WlaczTrybText
		mov	ax, 4C00h
		int	21h

                END     Start
