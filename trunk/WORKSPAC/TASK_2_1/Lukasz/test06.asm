;=============================================================================;
;                                                                             ;
; Plik           	: test05.asm                                                   ;
; Format         	: EXE                                                        ;
; Cwiczenie			: Zmiana częstotliwości zegara
; Autor				: Łukasz Ochmański
; Data zaliczenia	: 25.01.2014                                                 ;
;                                                                             ;
;=============================================================================;
		
		.MODEL	SMALL

WysNap	MACRO	Napis ;<-Makro do wyswietlania napisów

	mov 	dx, offset Napis
	mov 	ah, 09h
	int 	21h
	
	ENDM
	
;===============================================================;

Koniec_M	MACRO ;<- makro końca programu

	mov	ax, 4C00h
	int	21h
	
	ENDM
	
;===============================================================;

ZmienOCW2	MACRO	priorytet
		
	cli		; CLEAR INTERRUPT FLAG
	mov	al, priorytet
	out	20h, al;
	sti 	; SET INTERRUPT FLAG
	
	ENDM

;===============================================================;

Wyczysc_ekran MACRO

	mov ax,0B800h	; ADRES POCZĄTKU EKRANU
	mov es,ax 
	mov cx,25*80	; COUNTER = 25 LINII X 80 ZNAKÓW
	xor bx,bx 		; BX=0
wyczysc: 
	mov byte ptr es:[bx],0	; USTAW WSZYSTKIE BAJTY = 0
	add bx,2 				; BX++
	loop wyczysc			; URUCHOM 2000 RAZY
		
	ENDM
		
;===============================================================;

WczytajZnak     MACRO
    
	mov     ah, 08h
	int     21h
	
	ENDM
	
;===============================================================;		

Ustaw_DS MACRO adres
	
	mov ax, SEG adres
	mov ds, ax
	
	ENDM
	
;===============================================================;

Znajdz_przerwanie_zegara MACRO
	
	; AH=35h - GET INTERRUPT VECTOR
	; ENTRY: AL = INTERRUPT NUMBER
	; RETURN: ES:BX -> CURRENT INTERRUPT HANDLER
	mov ah, 35h	
	mov al, 08h
	int 21h
	
	ENDM
	
;===============================================================;

Zapisz_przerwanie_zegara MACRO
	
	; ZAPAMIĘTAJ ES:BX
	mov WORD PTR OrgProcZeg, bx
	mov WORD PTR OrgProcZeg +2, es
	
	ENDM
	
;===============================================================;

Podmien_adres_procedury MACRO

	push ds
	
	; AH=25h - SET INTERRUPT VECTOR
	; ENTRY:
	;	* AL = INTERRUPT NUMBER
	;	* DS:DX -> NEW INTERRUPT HANDLER

	lea dx, MojaProcZeg	; USTAW PARAMETR DX
	Ustaw_DS Kod		; USTAW PARAMETR DS
	mov ah, 25h			; USTAW PARAMETR AH
	mov al, 08h			; USTAW PARAMETR AL
	int 21h
	
	pop ds				; PRZYWRÓĆ PIERWOTNĄ WARTOŚĆ DS
	
	ENDM

;===============================================================;

;===============================================================;

;===============================================================;
				
Dane	SEGMENT

	Czestotliwosc	EQU	8000h 	;32768
	OrgProcZeg 		dd	?		;tablica do przechowania dotychczasowej procedury
	poz				dw	40		;pozycja
	przes			dw	0002h	;przesunięcie
	kierunek		db	0		;0-przód; 1-wstecz
	txtWcisnieto1	DB "Zegar przyspieszony" ,13,10, "$"
	txtWcisnieto2	DB "Zegar spowolniony" ,13,10, "$"
	txtWcisnieto3	DB "Pierwotna procedura przywr",162,"cona" ,13,10, "$"
	txtWcisnieto4	DB 13,10,"Do widzenia!" ,13,10, "$"

Dane	ENDS

;===============================================================;

Kod		SEGMENT

ASSUME  CS:Kod, DS:Dane, SS:Stosik

MojaProcZeg	PROC FAR
	sti
	push ds
	push bx
	push es
	push si
	push ax

	Ustaw_DS Dane		; ustawiamy segment danych

	mov bx, 0B800h 		; do bx początek ekranu (pierwszy kwadracik ekranu)
   	mov es, bx			; do es wpisujemy adres ekranu
		
	cmp kierunek, 0
	je do_przodu
	jmp do_tylu
		
do_przodu:
	mov si, poz					; si=0,2,4,6,8,...
	cmp poz, 120				; czy nie jest na końcu 
	je odwroc_do_tylu
	mov BYTE PTR es:[si-2], ' '
	mov BYTE PTR es:[si-1], 00000000B
	mov BYTE PTR es:[si], 15	; 15='*' w tablicy ASCII
	mov BYTE PTR es:[si+1], 1Eh	; zółta litera na niebieskim tle
	mov bx, przes				; pozycja+2
	add poz, bx
	jmp koniec_procedury

do_tylu:
	mov si, poz			; si=120,118,116,...
	cmp poz, 40			; czy nie jest na początku
	je odwroc_do_przodu
	mov BYTE PTR es:[si+2], ' '
	mov BYTE PTR es:[si+3], 00000000B
	mov BYTE PTR es:[si], 15	; 15='*' w tablicy ASCII
	mov BYTE PTR es:[si+1], 1Eh	; zółta litera na niebieskim tle
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
	Ustaw_DS Dane
	Wyczysc_ekran
	Znajdz_przerwanie_zegara
	Zapisz_przerwanie_zegara
	Podmien_adres_procedury
	;PRZERWANIE PRZEJĘTE!!!
		
	; WCIŚNIĘCIE DOWOLNEGO KLAWISZA POWODUJE
	; PRZYSPIESZENIE ZEGARA (ZA WYJĄTKIEM ESC)
klawisz1:
	WczytajZnak
	cmp al, 1Bh		; JEŻELI ESC, GO TO klawisz1
	je klawisz1		; ELSE PRZESTAW ZEGAR
	WysNap txtWcisnieto1
	
	mov	al, 36h		;al=00110110
	out	43h, al		;wyślij 00110110 na port 43h
	mov	ax, Czestotliwosc
	out	40h, al		;wyślij młodszy bajt wartości początkowej
	mov	al, ah		;wyślij starszy bajt (128) wartości początkowej
	out	40h, al		;do licznika 0

	; WCIŚNIĘCIE DOWOLNEGO KLAWISZA POWODUJE
	; SPOWOLNIENIE ZEGARA (ZA WYJĄTKIEM ESC)	
klawisz2:
	WczytajZnak
	cmp al, 1Bh
	je klawisz2
	WysNap txtWcisnieto2

	mov	al, 36h		;al=00110110
	out	43h, al		;wyślij 00110110 na port 43h
	mov	al, 0
	out	40h, al	
	out	40h, al	

	; WCIŚNIĘCIE DOWOLNEGO KLAWISZA POWODUJE
	; ODTWORZENIE DOMYŚLNEJ PROCEDURY ZEGARA (ZA WYJĄTKIEM ESC)
klawisz3:
	WczytajZnak
	cmp al, 1Bh
	je klawisz3
	WysNap txtWcisnieto3

	cli
	push ds
	mov	ah, 25h			;odtwórz oryginalny wektor
	mov	al, 08h			;przerwania zegara
	lds	dx, OrgProcZeg
	int	21h
	pop ds
	sti
	
	; WCIŚNIĘCIE DOWOLNEGO KLAWISZA POWODUJE
	; ZAKOŃCZENIE PROGRAMU (ZA WYJĄTKIEM ESC)
klawisz4:
	WczytajZnak
	cmp al, 1Bh
	je klawisz4
	WysNap txtWcisnieto4
	
	Koniec_M

Kod            ENDS

;===============================================================;

Stosik         SEGMENT     STACK

	DB 100h DUP (?)

Stosik         ENDS

;===============================================================;

END     Start

