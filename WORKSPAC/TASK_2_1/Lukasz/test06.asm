;===============================================================;
;
; Plik           	: test06.asm
; Format         	: EXE
; Cwiczenie			: Zmiana częstotliwości zegara
; Autor				: Łukasz Ochmański
; Data zaliczenia	: 25.01.2014
;
;===============================================================;
		
	.MODEL	SMALL

;===============================================================;

; MACRO DO WYŚWIETLANIA NAPISÓW

WysNap MACRO Napis

	mov dx, offset Napis
	mov ah, 09h
	int 21h
	
	ENDM
	
;===============================================================;

; MACRO ZERUJĄCE WSZYSTKIE BAJTY W OBSZARZE PAMIĘCI OPERACYJNEJ
; ODPOWIEDZIALNEJ ZA PRZECHOWYWANIE ZAWARTOŚCI EKRANU
Wyczysc_ekran MACRO
LOCAL wyczysc
	mov ax,0B800h			; ADRES POCZĄTKU EKRANU
	mov es,ax 
	mov cx,25*80			; COUNTER = 25 LINII X 80 ZNAKÓW
	xor bx,bx 				; BX=0
wyczysc: 
	mov byte ptr es:[bx],0	; USTAW WSZYSTKIE BAJTY = 0
	add bx,2 				; BX++
	loop wyczysc			; URUCHOM PĘTLĘ 2000 RAZY
		
	ENDM
		
;===============================================================;

WczytajZnak MACRO
    
	mov ah, 08h
	int 21h
	
	ENDM
	
;===============================================================;

; MACRO DO USTAWIANIA SEGMENTU DS

Ustaw_rejestr_ds MACRO adres
	
	mov ax, SEG adres
	mov ds, ax
	
	ENDM
	
;===============================================================;

; MACRO ZWRACAJĄCE ADRES PROCEDURY ODPOWIEDZIALNEJ ZA
; KONTROLĘ URZĄDZENIA NA KANALE IRQ 0
; W TYM PRZYPADKU JEST TO PIT INTEL 8253/8254

Znajdz_przerwanie_zegara MACRO
	
	; AH=35h - GET INTERRUPT VECTOR
	; ENTRY: AL = INTERRUPT NUMBER
	; RETURN: ES:BX -> CURRENT INTERRUPT HANDLER
	mov ah, 35h	
	mov al, 08h ; IRQ 0
	int 21h
	
	ENDM
	
;===============================================================;

; MACRO ZAPISUJĄCE W PAMIĘCI OPERACYJNEJ ADRES PROCEDURY
; ZWRÓCONEJ PRZEZ FUNKCJĘ SYSTEMOWĄ 35h

Zapisz_przerwanie_zegara MACRO
	
	; ZAPAMIĘTAJ ES:BX
	mov WORD PTR OrgProcZeg, bx
	mov WORD PTR OrgProcZeg +2, es
	
	ENDM
	
;===============================================================;

; MACRO WYWOŁUJĄCE FUNKCJĘ SYSTEMOWĄ 25h, SŁUŻĄCĄ DO
; MODYFIKACJI ADRESÓW PROCEDUR W WEKTORZE PRZERWAŃ

Podmien_adres_procedury MACRO
	
	push ds
	
	; AH=25h - SET INTERRUPT VECTOR
	; ENTRY:
	;	* AL = INTERRUPT NUMBER
	;	* DS:DX -> NEW INTERRUPT HANDLER

	lea dx, MojaProcZeg		; USTAW PARAMETR DX
	Ustaw_rejestr_ds Kod			; USTAW PARAMETR DS
	mov ah, 25h				; USTAW PARAMETR AH
	mov al, 08h				; USTAW PARAMETR AL
	int 21h
	
	pop ds					; PRZYWRÓĆ PIERWOTNĄ WARTOŚĆ DS
	
	ENDM

;===============================================================;

; MACRO ZMIENIAJĄCE CZĘSTOTLIWOŚĆ GENEROWANIA PRZERWANIA ZEGAROWEGO
; UKŁADU CZASOWEGO PIT (INTEL 8253/8254) POPRZEZ PORTY 40h I 43h

Ustaw_zegar MACRO tempo

	cli
	mov	al, 36h				; AL=00110110
	out	43h, al	
	mov	ax, tempo				
	out	40h, al				; WYŚLIJ MŁODSZY BAJT AX (AL)
	mov	al, ah	
	out	40h, al				; WYŚLIJ STARSZY BAJT AX (AH)
	sti
	
	ENDM

;===============================================================;

; MACRO WYWOŁUJĄCE FUNKCJĘ SYSTEMOWĄ 25h, SŁUŻĄCĄ DO
; MODYFIKACJI ADRESÓW PROCEDUR W WEKTORZE PRZERWAŃ

Przywroc_wektor MACRO

	push ds
	mov	ah, 25h			
	mov	al, 08h				; IRQ 0
	lds	dx, OrgProcZeg
	int	21h
	pop ds
	
	ENDM

;===============================================================;

; MACRO KONFIGURUJĄCE PROGRAMOWALNY STEROWNIK PRZERWAŃ PIC (INTEL 8259A)
; PRZESYŁA OPERACYJNE SŁOWO ROZKAZOWE OCW2

ZmienOCW2 MACRO	priorytet
		
	cli						; CLEAR INTERRUPT FLAG
	mov	al, priorytet
	out	20h, al;
	sti 					; SET INTERRUPT FLAG
	
	ENDM

;===============================================================;

;===============================================================;

;===============================================================;

; MACRO WYWOŁUJĄCE FUNKCJĘ SYSTEMOWĄ 4C00h

Koniec MACRO

	mov	ax, 4C00h
	int	21h
	
	ENDM
	
;===============================================================;

Stosik SEGMENT STACK

	DB 100h DUP (?)

Stosik ENDS

;===============================================================;
				
Dane SEGMENT
	
	; CONSTANTS
	wolno			EQU	0000h 	; 1/1,193181*65536 = 54925 = 54,925ms
	szybko			EQU	8000h 	; 1/1,193181*32768 = 27462 = 27,462ms
	szybciej		EQU 4000h	; 1/1,193181*16384 = 13731 = 13,731ms
	najszybciej		EQU 2000h	; 1/1,193181* 8196 = 68690 =  6,869ms
	
	; GLOBAL VARIABLES
	czestotliwosc	dw	0000h
	OrgProcZeg 		dd	?		; OBSZAR PRZEZNACZONY NA PRZECHOWANIE
								; PROCEDURY
	poz				dw	40		; POZYCJA PORUSZAJĄCEJ SIĘ GWIAZDKI
	przes			dw	0002h	; PRZESUNIĘCIE PORUSZAJĄCEJ SIĘ GWIAZDKI
	kierunek		db	0		; KIERUNEK RUCHU GWIAZDKI
								; (0-PRZÓD; 1-WSTECZ)
	txtPowitanie	DB 	" Witaj w programie demonstruj",165,"cym dzia",136,	"anie",13,10," programowalnego sterownika przerwa",228," 8259A oraz",13,10," programowalnego zegara przyrostowego 8253.",13,10,13,10," Wci",152,"nij dowolny klawisz, aby kontynuowa",134,"...",13,10,13,10, "$"
	txtWcisnieto1	DB 	" Procedura obs",136,"ugi kana",136,"u IRQ0 przychwycona i zmodyfikowana.", 13, 10, "$"
	txtWcisnieto2	DB 	" Programowalny zegar przyrostowy 8253 przyspieszony. (145,6Hz)" ,13,10, "$"
	txtWcisnieto3	DB 	" Programowalny zegar przyrostowy 8253 spowolniony. (18,2Hz)" ,13,10, "$"
	txtWcisnieto4	DB 	" Pierwotna procedura obs",136,"ugi kana",136,"u IRQ0 przywr",162,"cona." ,13,10, "$"
	txtPrompt5	DB 	13,10," Wci",152,"nij dowolny klawisz, aby zako",228,"czy",134,"...", "$"
	txtWcisnieto5	DB 	13,10," Do widzenia!" ,13,10, "$"

Dane ENDS

;===============================================================;

Kod SEGMENT

ASSUME CS:Kod, DS:Dane, SS:Stosik

MojaProcZeg	PROC FAR
	sti
	push ds
	push bx
	push es
	push si
	push ax

	Ustaw_rejestr_ds Dane
	Ustaw_zegar	czestotliwosc;		; USTAW CZĘSTOTLIWOŚĆ ZEGARA
									; UŻYWAJĄC WARTOŚCI ZMIENNEJ
									; GLOBALNEJ czestotliwosc

	mov bx, 0B800h 					; B800 - ADRES POCZĄTKU EKRANU
   	mov es, bx
		
	cmp kierunek, 0
	je do_przodu					; TRUE  - PRZÓD
	jmp do_tylu						; FALSE - WSTECZ
		
do_przodu:
	mov si, poz						; SI=0,2,4,6,8,...
	cmp poz, 120					; SPRAWDŹ CZY NIE JEST NA KOŃCU
	je odwroc_do_tylu
	mov BYTE PTR es:[si-2], ' '
	mov BYTE PTR es:[si-1], 00h
	mov BYTE PTR es:[si], 15		; 15='*' W TABLICY ASCII
	mov BYTE PTR es:[si+1], 1Eh		; ŻÓŁTA LITERA NA NIEBIESKIM TLE
	mov bx, przes					; POZYCJA=POZYCJA+2
	add poz, bx
	jmp koniec_procedury

do_tylu:
	mov si, poz						; SI=120,118,116,...
	cmp poz, 40						; SPRAWDŹ CZY NIE JEST NA POCZĄTKU
	je odwroc_do_przodu
	mov BYTE PTR es:[si+2], ' '
	mov BYTE PTR es:[si+3], 00h
	mov BYTE PTR es:[si], 15
	mov BYTE PTR es:[si+1], 1Eh
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
	; ZGODNIE Z WYTYCZNYMI PROJEKTU:
	; PRZY PRZEJMOWANIU PRZERWANIA NALEŻY ZAPEWNIĆ WYWOŁYWANIE ORYGINALNEJ
	; PROCEDURY JEGO OBSŁUGI Z PIERWOTNĄ CZĘSTOTLIWOŚCIĄ, JAKO, ŻE PROCEDU- ; RA TA REALIZUJE WAŻNE FUNKCJE SYSTEMOWE I MUSI BYĆ WYKONYWANA W ŚCIS-
	; ŁYCH ODSTĘPACH CZASU. NIESTETY ODKOMENTOWANIE PONIŻSZEJ LINI SPRAWIA,
	; ŻE ZGŁASZANIE PRZERWANIA ZEGAROWEGO NASTĘPUJE ZALEDWIE CO 55ms. JEST
	; TO ZNACZNIEJ MNIEJ NIŻ CZAS WYKONANIA WSZYSTKICH INSTRUKCJI TEGO PRO-
	; GRAMU. Z TEGO POWODU USTAWIENIE CZĘSTOTLIWOŚCI LICZNIKA W POCZĄTKOWEJ ; CZĘŚCI KODU JEST NADPISYWANE PRZEZ KOLEJNE INSTRUKCJE. ZATEM POD UWA-
	; GĘ BRANA JEST TA OSTATNIA INSTRUKCJA, A POPRZEDZAJĄCE SĄ IGNOROWANE.
	; INNYMI SŁOWY: WSZYSTKIE PRÓBY PRZYSPIESZENIA ZEGARA SĄ NADPISYWANE
	; PONIŻSZĄ LINIĄ KODU, ZANIM WEJDĄ W ŻYCIE.
	Ustaw_zegar wolno 				; USTAW CZĘSTOTLIWOŚĆ ZEGARA
									; UŻYWAJĄC WARTOŚCI STAŁEJ wolno
									; Z ZADEKLAROWANĄ WARTOŚCIĄ=0
									
	; ROZWIĄZANIEM TEGO PROBLEMU BYŁOBY ZASTOSOWANIE PRZERWANIA SYSTEMOWEGO
	; INT 08h - TIMER INTERRUPT, INT 28h - DOS IDLE INTERRUPT LUB PO PROSTU
	; ZASTOSOWANIE PĘTLI, OBCIĄŻAJĄCEJ PROCESOR. TAKI FRAGMENT KODU NALEŻA-
	; ŁOBY UMIEŚCIĆ NA SAMYM POCZĄTKU MOJEJ PROCEDURY.
	
	pushf
	call OrgProcZeg
	
	; TAKI "WORKAROUND" ŻEBY CZĘŚCIOWO ROZWIĄZAĆ POWYŻEJ OPISANY PROBLEM
	; TERAZ OSTANIĄ LINIĄ KODU JEST POŻĄDANA CZĘSTOTLIWOŚĆ :)
	Ustaw_zegar	czestotliwosc;		; USTAW CZĘSTOTLIWOŚĆ ZEGARA
									; UŻYWAJĄC WARTOŚCI ZMIENNEJ
									; GLOBALNEJ czestotliwosc
	pop ax
	pop si
	pop es
	pop bx
	pop ds
	iret
	
MojaProcZeg ENDP

Start:
	Ustaw_rejestr_ds Dane
	Wyczysc_ekran
	WysNap txtPowitanie
	Znajdz_przerwanie_zegara
	Zapisz_przerwanie_zegara

	; KLAWISZ 1
	WczytajZnak
	Wyczysc_ekran
	Podmien_adres_procedury
	WysNap txtWcisnieto1
	
	; KLAWISZ 2
	;WczytajZnak
	;mov czestotliwosc, szybko
	;WysNap txtWcisnieto2
	
	; KLAWISZ 2 BIS
	WczytajZnak
	mov czestotliwosc, najszybciej
	WysNap txtWcisnieto2
	
	; KLAWISZ 3
	WczytajZnak
	mov czestotliwosc, wolno
	WysNap txtWcisnieto3

	; KLAWISZ 4
	WczytajZnak
	Przywroc_Wektor
	WysNap txtWcisnieto4
	
	; KLAWISZ 5
;	WysNap txtPrompt5
	WczytajZnak
	Wyczysc_ekran
	WysNap txtWcisnieto5
	Koniec

Kod ENDS

;===============================================================;

END Start