;===============================================================;
;
; Plik           	: zadanie.asm
; Format         	: EXE
; èwiczenie			: Sterownik przerwa‰ 8259A i zegar/licznik 8253
; Autor				: ùukasz Ochma‰ski
; Data zaliczenia	: 25.01.2014
;
;===============================================================;
		
	.MODEL	SMALL

;===============================================================;

; MACRO DO WYóWIETLANIA NAPIS‡W

WysNap MACRO Napis

	mov dx, offset Napis
	mov ah, 09h
	int 21h
	
	ENDM
	
;===============================================================;

; MACRO ZERUJ§CE WSZYSTKIE BAJTY W OBSZARZE PAMI®CI OPERACYJNEJ
; ODPOWIEDZIALNEJ ZA PRZECHOWYWANIE ZAWARTOóCI EKRANU
Wyczysc_ekran MACRO
LOCAL wyczysc
	mov ax,0B800h			; ADRES POCZ§TKU EKRANU
	mov es,ax 
	mov cx,25*80			; COUNTER = 25 LINII X 80 ZNAK‡W
	xor bx,bx 				; BX=0
wyczysc: 
	mov byte ptr es:[bx],32	; USTAW WSZYSTKIE BAJTY = 0 lub 32
	add bx,2 				; BX++
	loop wyczysc			; URUCHOM P®TL® 2000 RAZY
		
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

; MACRO ZWRACAJ§CE ADRES PROCEDURY ODPOWIEDZIALNEJ ZA
; KONTROL® URZ®DZENIA NA KANALE IRQ 0
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

; MACRO ZAPISUJ§CE W PAMI®CI OPERACYJNEJ ADRES PROCEDURY
; ZWR‡CONEJ PRZEZ FUNKCJ® SYSTEMOW§ 35h

Zapisz_przerwanie_zegara MACRO
	
	; ZAPAMI®TAJ ES:BX
	mov WORD PTR Oryg_Vect_08h, bx
	mov WORD PTR Oryg_Vect_08h +2, es
	
	ENDM
	
;===============================================================;

; MACRO WYWOùUJ§CE FUNKCJ® SYSTEMOW§ 25h, SùUΩ§C§ DO
; MODYFIKACJI ADRES‡W PROCEDUR W WEKTORZE PRZERWA„

Podmien_adres_procedury_08 MACRO
	
	push ds
	
	; AH=25h - SET INTERRUPT VECTOR
	; ENTRY:
	;	* AL = INTERRUPT NUMBER
	;	* DS:DX -> NEW INTERRUPT HANDLER

	mov dx, OFFSET New_Handler_08h	; USTAW PARAMETR DX
	Ustaw_rejestr_ds Kod			; USTAW PARAMETR DS
	mov ah, 25h						; USTAW PARAMETR AH
	mov al, 08h						; USTAW PARAMETR AL
	int 21h
	
	pop ds
	
	ENDM

;===============================================================;

; MACRO ZWRACAJ§CE ADRES PROCEDURY ODPOWIEDZIALNEJ ZA
; KONTROL® URZ§DZENIA NA KANALE IRQ 1
; W TYM PRZYPADKU JEST TO KLAWIATURA

Znajdz_przerwanie_klawiatury MACRO
	
	; AH=35h - GET INTERRUPT VECTOR
	; ENTRY: AL = INTERRUPT NUMBER
	; RETURN: ES:BX -> CURRENT INTERRUPT HANDLER
	mov ah, 35h	
	mov al, 09h ; IRQ 1
	int 21h
	
	ENDM
	
;===============================================================;

; MACRO ZAPISUJ§CE W PAMI®CI OPERACYJNEJ ADRES PROCEDURY
; ZWR‡CONEJ PRZEZ FUNKCJ® SYSTEMOW§ 35h

Zapisz_przerwanie_klawiatury MACRO
	
	; ZAPAMI®TAJ ES:BX
	mov WORD PTR Oryg_Vect_09h, bx
	mov WORD PTR Oryg_Vect_09h +2, es
	
	ENDM
	
;===============================================================;

; MACRO WYWOùUJ§CE FUNKCJ® SYSTEMOW§ 25h, SùUΩ§C§ DO
; MODYFIKACJI ADRES‡W PROCEDUR W WEKTORZE PRZERWA„

Podmien_adres_procedury_09 MACRO
	
	push ds
	
	; AH=25h - SET INTERRUPT VECTOR
	; ENTRY:
	;	* AL = INTERRUPT NUMBER
	;	* DS:DX -> NEW INTERRUPT HANDLER

	mov dx, OFFSET New_Handler_09h	; USTAW PARAMETR DX
	Ustaw_rejestr_ds Kod			; USTAW PARAMETR DS
	mov ah, 25h						; USTAW PARAMETR AH
	mov al, 09h						; USTAW PARAMETR AL
	int 21h
	
	pop ds
	
	ENDM

;===============================================================;

; MACRO ZMIENIAJ§CE CZ®STOTLIWOóè GENEROWANIA PRZERWANIA ZEGAROWEGO
; UKùADU CZASOWEGO PIT (INTEL 8253/8254) POPRZEZ PORTY 40h I 43h

Ustaw_zegar MACRO tempo

	cli
	mov	al, 36h				; AL=00110110
	out	43h, al	
	mov	ax, tempo				
	out	40h, al				; WYóLIJ MùODSZY BAJT AX (AL)
	mov	al, ah	
	out	40h, al				; WYóLIJ STARSZY BAJT AX (AH)
	sti
	
	ENDM

;===============================================================;

; MACRO WYWOùUJ§CE FUNKCJ® SYSTEMOW§ 25h, SùUΩ§C§ DO
; MODYFIKACJI ADRES‡W PROCEDUR W WEKTORZE PRZERWA„

Przywroc_wektor_08 MACRO

	push ds
	mov	ah, 25h			
	mov	al, 08h				; IRQ 0
	lds	dx, Oryg_Vect_08h
	int	21h
	pop ds
	
	ENDM

;===============================================================;

; MACRO WYWOùUJ§CE FUNKCJ® SYSTEMOW§ 25h, SùUΩ§C§ DO
; MODYFIKACJI ADRES‡W PROCEDUR W WEKTORZE PRZERWA„

Przywroc_wektor_09 MACRO

	push ds
	mov	ah, 25h			
	mov	al, 09h				; IRQ 1
	lds	dx, Oryg_Vect_09h
	int	21h
	pop ds
	
	ENDM

;===============================================================;

; MACRO KONFIGURUJ§CE PROGRAMOWALNY STEROWNIK PRZERWA„ PIC (INTEL 8259A)
; PRZESYùA OPERACYJNE SùOWO ROZKAZOWE OCW2

ZmienOCW2 MACRO	priorytet
		
	cli						; CLEAR INTERRUPT FLAG
	mov	al, priorytet
	out	20h, al;
	sti 					; SET INTERRUPT FLAG
	
	ENDM

;===============================================================;

;===============================================================;

;===============================================================;

; MACRO WYWOùUJ§CE FUNKCJ® SYSTEMOW§ 4C00h

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
	priorytet   	db  1		; 0-KLAWIATURA; 1-ZEGAR
	Oryg_Vect_08h 	dd	?		; OBSZAR PRZEZNACZONY NA PRZECHOWANIE
	Oryg_Vect_09h	dd	?		; PROCEDURY
	poz				dw	40		; POZYCJA PORUSZAJ§CEJ SI® GWIAZDKI
	przes			dw	0002h	; PRZESUNI®CIE PORUSZAJ§CEJ SI® GWIAZDKI
	kierunek		db	0		; KIERUNEK RUCHU GWIAZDKI
								; (0-PRZ‡D; 1-WSTECZ)
	txtPowitanie	DB 	" Witaj w programie demonstruj•cym dziaàanie",13,10," programowalnego sterownika przerwa‰ 8259A oraz",13,10," programowalnego zegara przyrostowego 8253.",13,10,13,10," Wciònij dowolny klawisz, aby kontynuowaÜ...",13,10,13,10, "$"
	txtWcisnieto1	DB 	" Procedura obsàugi kanaàu IRQ0 przechwycona i zmodyfikowana.", 13, 10, "$"
	txtWcisnieto2	DB 	" Cz©stotliwoòÜ generowania przerwania zegarowego zwi©kszona do 145,6Hz" ,13,10, "$"
	txtWcisnieto3	DB 	" Cz©stotliwoòÜ generowania przerwania zegarowego zmniejszona do 18,21Hz" ,13,10, "$"
	txtWcisnieto4	DB 	" Procedura obsàugi kanaàu IRQ1 przechwycona i zmodyfikowana.", 13, 10, "$"
	txtWcisnieto5	DB 	" Ustawiono najwyæszy priorytet dla klawiatury.", 13, 10, "$"
	txtWcisnieto6	DB 	" Przerwanie klawiatury.", 13, 10, "$"
	txtWcisnieto7	DB 	" Ustawiono najwyæszy priorytet dla zegara.", 13, 10, "$"
	txtWcisnieto8	DB 	" Pierwotna procedura obsàugi kanaàu IRQ0 przywr¢cona." ,13,10, "$"
	txtWcisnieto9	DB 	" Pierwotna procedura obsàugi kanaàu IRQ1 przywr¢cona." ,13,10, "$"
	txtPrompt5	DB 	13,10," Wciònij dowolny klawisz, aby zako‰czyÜ...", "$"
	txtWcisnieto10	DB 	13,10," Do widzenia!" ,13,10, "$"

Dane ENDS

;===============================================================;

Kod SEGMENT

ASSUME CS:Kod, DS:Dane, SS:Stosik

New_Handler_08h	PROC FAR
	sti
	push ds
	push bx
	push es
	push si
	push ax

	Ustaw_rejestr_ds Dane
	Ustaw_zegar	czestotliwosc		; USTAW CZ®STOTLIWOóè ZEGARA
									; UΩYWAJ§C WARTOóCI ZMIENNEJ
									; GLOBALNEJ czestotliwosc

	mov bx, 0B800h 					; B800 - ADRES POCZ§TKU EKRANU
   	mov es, bx
		
	cmp kierunek, 0
	je do_przodu					; TRUE  - PRZ‡D
	jmp do_tylu						; FALSE - WSTECZ
		
do_przodu:
	mov si, poz						; SI=0,2,4,6,8,...
	cmp poz, 120					; SPRAWDç CZY NIE JEST NA KO„CU
	je odwroc_do_tylu
	mov BYTE PTR es:[si-2], ' '
	mov BYTE PTR es:[si-1], 00h
	mov BYTE PTR es:[si], 15		; 15='*' W TABLICY ASCII
	mov BYTE PTR es:[si+1], 1Eh		; Ω‡ùTA LITERA NA NIEBIESKIM TLE
	mov bx, przes					; POZYCJA=POZYCJA+2
	add poz, bx
	jmp koniec_procedury

do_tylu:
	mov si, poz						; SI=120,118,116,...
	cmp poz, 40						; SPRAWDç CZY NIE JEST NA POCZ§TKU
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
	; PRZY PRZEJMOWANIU PRZERWANIA NALEΩY ZAPEWNIè WYWOùYWANIE ORYGINALNEJ
	; PROCEDURY JEGO OBSùUGI Z PIERWOTN§ CZ®STOTLIWOóCI§, JAKO, ΩE PROCEDU- ; RA TA REALIZUJE WAΩNE FUNKCJE SYSTEMOWE I MUSI BYè WYKONYWANA W óCIS-
	; ùYCH ODST®PACH CZASU. NIESTETY ODKOMENTOWANIE PONIΩSZEJ LINI SPRAWIA,
	; ΩE ZGùASZANIE PRZERWANIA ZEGAROWEGO NAST®PUJE ZALEDWIE CO 55ms. JEST
	; TO ZNACZNIEJ MNIEJ NIΩ CZAS WYKONANIA WSZYSTKICH INSTRUKCJI TEGO PRO-
	; GRAMU. Z TEGO POWODU USTAWIENIE CZ®STOTLIWOóCI LICZNIKA W POCZ§TKOWEJ ; CZ®óCI KODU JEST NADPISYWANE PRZEZ KOLEJNE INSTRUKCJE. ZATEM POD UWA-
	; G® BRANA JEST WYù§CZNIE OSTATNIA INSTRUKCJA, A POPRZEDZAJ§CE S§ IGNO-
	; ROWANE. INNYMI SùOWY: WSZYSTKIE PR‡BY PRZYSPIESZENIA ZEGARA S§ NADPI-
	; SYWANE PONIΩSZ§ LINI§ KODU, ZANIM WEJD§ W ΩYCIE.
	Ustaw_zegar wolno 				; USTAW CZ®STOTLIWOóè ZEGARA
									; UΩYWAJ§C WARTOóCI STAùEJ wolno
									; Z ZADEKLAROWAN§ WARTOóCI§=0
									
	; ROZWI§ZANIEM TEGO PROBLEMU BYùOBY ZASTOSOWANIE PRZERWANIA SYSTEMOWEGO
	; INT 08h - TIMER INTERRUPT, INT 28h - DOS IDLE INTERRUPT LUB PO PROSTU
	; ZASTOSOWANIE P®TLI, OBCI§ΩAJ§CEJ PROCESOR. TAKI FRAGMENT KODU NALEΩA-
	; ùOBY UMIEóCIè NA SAMYM POCZ§TKU MOJEJ PROCEDURY.
	
	pushf
	call Oryg_Vect_08h

	; END OF INTERRUPT (EOI)
	mov al, 01100000b
	out 20h, al
	
	; TAKI "WORKAROUND" ΩEBY CZ®óCIOWO ROZWI§ZAè POWYΩEJ OPISANY PROBLEM
	; TERAZ OSTANI§ LINI§ KODU JEST POΩ§DANA CZ®STOTLIWOóè :)
	Ustaw_zegar	czestotliwosc
	
	pop ax
	pop si
	pop es
	pop bx
	pop ds
	iret
	
New_Handler_08h ENDP

;===============================================================;

New_Handler_09h	PROC FAR
	sti
	push ds
	push bx
	push es
	push si
	push ax

	Ustaw_rejestr_ds Dane

	mov bx, 0B800h 					; B800 - ADRES POCZ§TKU EKRANU
   	mov es, bx
		
	cmp kierunek, 0
	je k_do_przodu					; TRUE  - PRZ‡D
	jmp k_do_tylu					; FALSE - WSTECZ
		
k_do_przodu:
	mov si, poz						; SI=0,2,4,6,8,...
	cmp poz, 120					; SPRAWDç CZY NIE JEST NA KO„CU
	je k_odwroc_do_tylu
	mov BYTE PTR es:[si-2], 15
	mov BYTE PTR es:[si-1], 02h
	mov BYTE PTR es:[si],	15		; 15='*' W TABLICY ASCII
	mov BYTE PTR es:[si+1], 02h	
	mov bx, przes					; POZYCJA=POZYCJA+2
	add poz, bx
	jmp k_koniec_procedury

k_do_tylu:
	mov si, poz						; SI=120,118,116,...
	cmp poz, 40						; SPRAWDç CZY NIE JEST NA POCZ§TKU
	je k_odwroc_do_przodu
	mov BYTE PTR es:[si],	15
	mov BYTE PTR es:[si+1], 02h
	mov BYTE PTR es:[si+2], 15
	mov BYTE PTR es:[si+3], 02h
	mov bx, przes
	sub poz, bx
	jmp k_koniec_procedury

k_odwroc_do_przodu:
	mov kierunek, 0
	mov poz, 40
	mov si, poz
	jmp k_koniec_procedury

k_odwroc_do_tylu:
	mov kierunek, 1
	mov poz, 120
	mov si, poz
	jmp k_koniec_procedury

k_koniec_procedury:

	; IMITACJA PAUZY. PONIEWAΩ NIE CHCE MI SI® SZUKAè JAK SI® WYWOùUJE
	; FUNKCJ® SYSTEMOW§ INT 08h - TIMER INTERRUPT LUB INT 28h - DOS IDLE
	; INTERRUPT, POZWOLIùEM SOBIE NAPISAè P®TL®, KT‡RA ZAJEΩDΩA PROCESOR
	; PRZEZ KILKA SEKUND. W TEN SPOS‡B MOΩNA ZOBACZYè CZY KOD PROCURY
	; WùAóNIE SI® WYKONUJE.
mov ax, 4000
PetlaZewn:
	mov	cx, 4000
PetlaWewn:
	loop PetlaWewn
	dec	ax
	jnz	PetlaZewn
		
	pushf
	call Oryg_Vect_09h

	; END OF INTERRUPT (EOI)	
	mov al, 01100000b
	out 20h, al
	
	pop ax
	pop si
	pop es
	pop bx
	pop ds
	iret
	
New_Handler_09h ENDP

;===============================================================;

;===============================================================;

;===============================================================;

Start:
	Ustaw_rejestr_ds Dane
	Wyczysc_ekran
	WysNap txtPowitanie

	; KLAWISZ 1
	WczytajZnak
	Wyczysc_ekran
	Znajdz_przerwanie_zegara
	Zapisz_przerwanie_zegara
	Podmien_adres_procedury_08
	WysNap txtWcisnieto1
	
	; KLAWISZ 2
	WczytajZnak
	mov czestotliwosc, najszybciej
	WysNap txtWcisnieto2
	
	; KLAWISZ 3
	WczytajZnak
	mov czestotliwosc, wolno
	WysNap txtWcisnieto3
	
	; KLAWISZ 4
	WczytajZnak
	Znajdz_przerwanie_klawiatury
	Zapisz_przerwanie_klawiatury
	Podmien_adres_procedury_09
	WysNap txtWcisnieto4
	
	; KLAWISZ 5
	WczytajZnak
	ZmienOCW2 11000000b
	WysNap txtWcisnieto5
	
	; KLAWISZ 6
	WczytajZnak
	WysNap txtWcisnieto6
	
	; KLAWISZ 6 BIS
	WczytajZnak 
	WysNap txtWcisnieto6
	
	; KLAWISZ 6 TER
	WczytajZnak	
	WysNap txtWcisnieto6

	; KLAWISZ 6 QUARTER
	WczytajZnak
	WysNap txtWcisnieto6
	
	; KLAWISZ 7
	WczytajZnak
	ZmienOCW2 11000111b
	WysNap txtWcisnieto7
	
	; KLAWISZ 6
	WczytajZnak
	WysNap txtWcisnieto6
	
	; KLAWISZ 6 BIS
	WczytajZnak
	WysNap txtWcisnieto6
	
	; KLAWISZ 6 TER
	WczytajZnak	
	WysNap txtWcisnieto6

	; KLAWISZ 6 QUARTER
	WczytajZnak
	WysNap txtWcisnieto6
	
	; KLAWISZ 8
	WczytajZnak
	Przywroc_wektor_08
	WysNap txtWcisnieto8
	
	; KLAWISZ 09
	WczytajZnak
	Przywroc_wektor_09
	WysNap txtWcisnieto9
	
	; KLAWISZ 10
	WczytajZnak
	Wyczysc_ekran
	WysNap txtWcisnieto10
	Koniec

Kod ENDS

;===============================================================;

END Start