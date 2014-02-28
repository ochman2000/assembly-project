;=============================================================================;
;                                                                             ;
; Plik           : test01.asm                                                   ;
; Format         : EXE                                                        ;
; Cwiczenie      : Czyszczenie ekranu
; Autor        : £ukasz Ochmañski
; Data zaliczenia: 25.01.2014                                                 ;
;                                                                             ;
;=============================================================================;
		
		.MODEL	SMALL

WysNap	MACRO	Napis ;<-Makro do wyswietlania napisów

	mov 	dx, offset Napis
	mov 	ah, 09h
	int 	21h
	
	ENDM
	
;---------------------------------------------------------------;

Koniec_M	MACRO ;<- makro koñca programu

	mov	ax, 4C00h
	int	21h
	
	ENDM
	
;---------------------------------------------------------------;
ZmOCW2	MACRO	priorytet
		
		mov	al,priorytet
		out	20h, al;
		
		ENDM

;---------------------------------------------------------------;

Wyczysc_ekran MACRO

		mov ax,0B800h	;wyczysc ekran
		mov es,ax 
		mov cx,25*80	;licznik=25 linii po 80 pol (bx porusza sie co 2 pola)
		xor bx,bx 	;wyzerowanie bx
wyczysc: 
		mov byte ptr es:[bx],0 ;czyscimy odpowiednie pola
		add bx,2 
		loop wyczysc
		
		ENDM
		
;---------------------------------------------------------------;
WczytajZnak     MACRO
               	mov     ah, 08h
                int     21h
                ENDM
;---------------------------------------------------------------;		
Zainicjalizuj_stos MACRO
		mov ax, Dane
		mov ds, ax
				ENDM
;---------------------------------------------------------------;
Znajdz_przerwanie_zegara MACRO
		mov ah, 35h	;pobranie wektora przerwañ (f.35h), w al nr przerwania, 									;po wykonaniu w es:bx adres starej procedury obs³ugi przerwania
		mov al, 08h	;1CH=0000:0070 lub mov al, 1CH
		int 21h
		ENDM
;---------------------------------------------------------------;
Zapisz_przerwanie_zegara MACRO
		mov WORD PTR OrgProcZeg, bx 	; zapamiêtaj aktualny wektor (offset bx)
		mov WORD PTR OrgProcZeg +2, es 	; zapamiêtaj aktualny wektor (seg es)

		;copy cs (:KOD) to ds (:DANE)
		push cs		;push on stack :KOD (Copy cs to [ss:sp])
		pop ds		;pop from stack :DANE (Copy [ss:sp] to ds)
		ENDM
;---------------------------------------------------------------;
Podmien_adres_procedury MACRO
		lea dx, MojaProcZeg	;dx=offset adresu nowej procedury

		mov ah, 25h		;zapisanie nowego wektora przerwañ
		mov al, 08h		;w al nr nowego przerwania (1CH), w ds:dx adres

		int 21h
		ENDM
;---------------------------------------------------------------;

;---------------------------------------------------------------;

;---------------------------------------------------------------;
				
Dane            SEGMENT

	Czestotliwosc	EQU	8000h 	;32768
	OrgProcZeg 		dd	?		;tablica do przechowania dotychczasowej procedury
	poz				dw	40		;pozycja
	przes			dw	0002h	;przesuniêcie
	kierunek		db	0		;0 - przód; 1-wstecz

Dane            ENDS



Kod             SEGMENT
                ASSUME  CS:Kod, DS:Dane, SS:Stosik




MojaProcZeg	PROC FAR
		sti
		push ds
		push bx
		push es
		push si
		push ax

		mov bx, SEG Dane 			; ustawiamy segment danych
               	mov ds, bx 
		mov bx, 0B800h   			; do bx pocz¹tek ekranu (pierwszy kwadracik ekranu)
               	mov es, bx			; do es wpisujemy adres ekranu
		
		cmp kierunek, 0
		je do_przodu
		jmp do_tylu
		
do_przodu:
		mov si, poz					; si=0,2,4,6,8,...
		cmp poz, 120				; czy nie jest na koñcu 
		je odwroc_do_tylu
		mov BYTE PTR es:[si-2], ' '
		mov BYTE PTR es:[si-1], 00000000B
		mov BYTE PTR es:[si], 15	; 15='*' w tablicy ASCII
		mov BYTE PTR es:[si+1], 1Eh	; zó³ta litera na niebieskim tle
		mov bx, przes				; pozycja+2
		add poz, bx
		jmp koniec_procedury

do_tylu:
		mov si, poz			; si=120,118,116,...
		cmp poz, 40			; czy nie jest na pocz¹tku
		je odwroc_do_przodu
		mov BYTE PTR es:[si+2], ' '
		mov BYTE PTR es:[si+3], 00000000B
		mov BYTE PTR es:[si], 15	; 15='*' w tablicy ASCII
		mov BYTE PTR es:[si+1], 1Eh	; zó³ta litera na niebieskim tle
		mov bx, przes
		sub poz, bx
		jmp koniec_procedury

odwroc_do_przodu:
		mov kierunek, 0
		mov poz, 40
		mov si, poz
		jmp koniec_procedury

odwroc_do_tylu:
		mov kierunek, 1
		mov poz, 120
		mov si, poz
		jmp koniec_procedury

koniec_procedury:
		pushf
		call OrgProcZeg

		pop ax
		pop si
		pop es
		pop bx
		pop ds

		iret
MojaProcZeg ENDP


Start:
		Zainicjalizuj_stos
		Wyczysc_ekran
		Znajdz_przerwanie_zegara
		Zapisz_przerwanie_zegara
		Podmien_adres_procedury
		Zainicjalizuj_stos
		;przerwanie przejête!!!!!
		
;;;
klawisz1:
		WczytajZnak
		cmp al, 1Bh	;je¿eli ESC, to pobierz znak raz jeszcze
		je klawisz1

		
		;mov ah, 01h	sprawdz bufor klawiatury, jesli pusty-skocz do klawisz
		;int 16h
		;jz klawisz1
		
;;;przestawZegar:
		mov	al, 36h		;al=00110110
		out	43h, al		;wyœlij 00110110 na port 43h
		;mov	dx, 4Ah		;1193->4A9 (dx=4Ah, ax=9h)
		;mov	ax, 9h		
		mov	ax, Czestotliwosc ;ax=32768(8000h)
		;div	bx		;1193/36 (wspolczynnik podzialu)
		out	40h, al		;wyœlij m³odszy bajt wartoœci pocz¹tkowej
		mov	al, ah		;wyœlij starszy bajt (128) wartoœci pocz¹tkowej
		out	40h, al		;do licznika 0
		
klawisz2:
		WczytajZnak
		cmp al, 1Bh
		je klawisz2

;;;przywrocZegar:
		mov	al, 36h		;al=00110110
		out	43h, al		;wyœlij 00110110 na port 43h
		mov	al, 0
		out	40h, al	
		out	40h, al	
		;mov	licznik, 0
		;mov	max_licznik, 1

klawisz3:
		WczytajZnak
		cmp al, 1Bh
		je klawisz3

;;;KONIEC PROGRAMU:

		push	ds
		mov	ah, 25h			;odtwórz oryginalny wektor
		mov	al, 08h			;przerwania zegara
		lds	dx, OrgProcZeg
		int	21h
		pop	ds


               	mov     ax, 4C00h       ; funkcja konczaca program, kod zakoczenia programu
               	int     21h             ; wywolanie przerwania systemowego


Kod            ENDS

Stosik         SEGMENT     STACK

               DB      100h DUP (?)

Stosik         ENDS

               END     Start

