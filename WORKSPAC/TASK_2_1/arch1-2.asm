;==============================
; Plik           : arch1-2.asm 
; Format         : EXE
; Cwiczenie      : Cwiczenie 2-1
; Autorzy        : Lukasz Cander, Szymon Klepacz
;==============================

; KOLEJNOSC PROGRAMU:
; Czesc glowna
; ZmienZegar
; PrzerwZegara
; ZmienPrior
; PrzerwKlaw


.MODEL	SMALL

include		makra.mac

Dane		SEGMENT

txt0		DB	CRL,"	Szymon Klepacz, Lukasz Cander 0$"
txt1     	DB	CRL,"   1 / 2 - zmniejsza / zwieksza czestotliwosc zegara$"
txt2		DB	CRL,"   q - zamienia priorytety klawiatury i zegara$"
txt3		DB 	CRL,"   ESC - wyjscie z programu$"

WektorZegar	DD	? ;zmienne przechowuja wektor do oryginalnej procedury przerwania zegara/klaw
WektorKlaw	DD	?

Priorytet   DB  1h ;zmienna pomocnicza - do zamiany priorytetu - najpierw zegar ma wyzszy
Mnoznik	DW	2 ;zmienna pomocnicza zawiera mnoznik wg ktorego zmieniana jest wielkosc odliczana przez licznik

Dane		ENDS

Kod		SEGMENT

ASSUME		CS:Kod, DS:Dane, SS:Stosik

Start:
		mov	ax, SEG Dane    
		mov	ds, ax 
		
		DrukujNapis txt0
		DrukujNapis txt1
		DrukujNapis txt2
		DrukujNapis txt3

Czekaj:
		mov	ah, 07h	;czytanie z konsoli
		int	21h

		; zapamietuje stare czyli 'oryginalne' adresy przerwan
		WezWektor	08h, WektorZegar  	; pobiera adres oryginalny wektora przerw. zeg 
		WezWektor	09h, WektorKlaw	    ; klawiatury	
		
		;tutaj nastepuje przejecia przerwania przez nowe procedury
		;przejmujemy zeby moc wyswietlac znak za kazdym razem kiedy to przerwanie nastepuje
			;procedury przejecia przerwania musza spelniac nastepujace warunki:
			; 1. zapamietanie wszystkich zmienionych rejestrow
			; 2. ponowne ustawienie IF
			; 3. wywolanie oryginalnej procedury (skok/wywolanie posredniu typu dalekiego)
			; 4. jezeli przerwanie jest maskowalne i celowo nie wywoluje sie oryginalnego przerwania musi zostac wyslane EOI
			; 5. nie nalezy uzywac przerwania 21h bo moze to doprowadzic to zapetlenia sie calego systemu operacyjnego
		UstWektor	08h, PrzerwZegara	; uwstawia nowy wektor przerw zegara
		UstWektor	09h, PrzerwKlaw	; klawiatury
		
CzekanieNaUzyt:
		mov	ah, 07h
		int	21h
WyborOpcji: ;proste menu
		cmp	al, '2'
		je	ZegarZwieksz	
		cmp	al, '1'
		je	ZegarZmniejsz
		cmp	al, 'q'
		je	ZmienPriorytet
		cmp	al, 1Bh ;ESC
		je	KoniecProg
		jmp	CzekanieNaUzyt
		
ZegarZmniejsz: ;zmniejsza czestotliwosc wyzwalania impulsow poprzez zwiekszenie wartosci od ktorej odliczamy
		cmp     Mnoznik, 01h ;sprawdzenie czy nie jest mniejsze niz 1h
		je      RobZegar
		shr     Mnoznik,1 ;przesuniecie w prawo bitow - tak jakby *2
		jmp		RobZegar
		
ZegarZwieksz: ;zwieksza czestotliwosc wyzwalania impulsow poprzez zmniejszenie wartosci od ktorej odliczamy
		cmp     Mnoznik, 10h ;sprawdzenie czy nie przekracza 10h - takie ograniczenie predkosci - nawet 40h dziala ale nie wiele widac
		ja      RobZegar
		shl     Mnoznik,1 ;przesuniecie w lewo bitow - tak jakby /2
		jmp		RobZegar
		
RobZegar:
		call 	ZmienZegar
		jmp 	CzekanieNaUzyt
		
ZmienPriorytet:
		call 	ZmienPrior
		jmp     CzekanieNaUzyt
		
KoniecProg:
		PrzywrocWektor	08h,WektorZegar ;na koniec programu przywracamy oryginalne przerwania
		PrzywrocWektor	09h,WektorKlaw


		mov	ax, 4C00h
		int	21h


;=========================================================
;=========================================================

ZmienZegar	PROC
		;procedura przy pomocy slowa sterowania modyfikuje wartosc od ktorej nastepuje dekrementacja w zaleznosci od zmiennej Mnoznik

		cli			; IF=0 ignoruj przerwania

		mov	al, 00110110b
					; okresla slowo sterujace dla sterownika 8253: SC(00), RW(11), MOD(011), BCD(0), czyli
					; SC: licznik 0, RW: odczyt/zapis m³odszego, potem starszego bajtu, MOD: tryb 3, BCD: licznik binarny 16bitowy
					
					;TRYB 3:
					;wyjscie OUT przyjmuje wysoki stan, nowa wartosc jest ladowana do licznika i nastepuje zliczanie impulsow, kazdy impuls
					;pomniejsza licznik o 2, gdy odliczanie dobiegnie konca OUT przyjmuje niski stan
					;przebieg prostokatny o wypelnieniu 1/2
 
		out	43h, al		; wyslij slowo sterujace do ukladu zegara/licznika
		mov	ax, 0FFFFh	; okresl 16bitowa wartosc poczatkowa
						; maxymalnie duza - nie nastepuje przekrecenie o 1
		mov	dx, 0
		div	Mnoznik	;by zmienic zegar dzielac wartosc poczatkowa przez wartosc Mnoznik(ktora sie zmienia) 
		inc	ax
		out	40h, al		; zainicjuj -wyslij mlodszy bajt wartosci poczatkowej do licznika 0
		mov	al, ah
		out	40h, al		; wyœlij starszy bajt wartosci poczatkowej do licznika 0
		sti			; IF=1 odblokuj przerwania
		ret
		ENDP

;=========================================================
		
PrzerwZegara	PROC	FAR 
		;procedura przejecia przerwania zegarowego zeby pokazac szybkosc wyzwalania impulsow przez sterownik zegara
		
		sti ;odblokuj przerwania IF=1
		push	ax ;odlozenie rejestrow ktore sa uzywane
		push	bx
		push	cx
		push	ds
		
		
		mov	ax, SEG Dane
		mov	ds, ax 
		mov cx, Mnoznik
		dec cx ;zeby zwiekszyc czytelnosc (usuniecie '-' przy najnizszej czestotliwosci)

Petla:
		cmp	cx, 0h	;zrobione aby uwidocznic zmiane szybkosci pracy zegara
		je	BezWywolania		 
		WyswietlZnakBios '-'			
		loop Petla

BezWywolania:
		pushf				; odlozenie flag na stosie
		call	WektorZegar	; opuszczenie tej proc i wykonanie oryginalnej
							; oryginalny wektor obslugi przerwania
		WyswietlZnakBios '*'x
		jmp	KoniecProcZegara
		
		;mov	al, 20h	; niespecyficzne zlecenie EOI, zeruje w rejestrze obslugiwanych przerwan ISR
					; bit obsluzonego przerwania o najwyzszym priorytecie
		;out	20h, al	; czyli informacja o koncu obslugi przerwania

KoniecProcZegara:
		pop	ds
		pop	cx
		pop	bx
		pop	ax
		iret ;co by zdjac flagi rowniez
		ENDP


;=========================================================
		
ZmienPrior	PROC
		;procedura "zamienia" priorytety klawiatury i zegara poprzez wyslanie odpowiedniego slowa sterujacego do sterownika przerwan
		; w zaleznosci od wartosci zmiennej Priorytet

		cli			; IF=0 ignoruj przerwania
		cmp	Priorytet, 1h ;warunek a'la logiczny
		je Klawiatura	
		mov	al, 11000111b ;Rotacja okreslona
						  ;wyslanie slowa OCW2 do sterownika przerwan
						  ;1 - przeprowadzenie rotacjipriorytetow
						  ;1 - uwzglednienie 3 ostatnich bitow
						  ;0 - brak modyfikacji rejestru ISR (rejestr obslugiwanych przerwan)
						  ;00 - bity
						  ;111 - numer wejscia ktoremu przypisujemy najnizszy priorytet, czyli w tym wypadku wejsciu nr 7
						  ;klawiatura otrzyma priorytet 1, zegar 0 wiec moze przerwac przerwanie klawiatury
						  
		out	20h, al	
		mov Priorytet, 1h
		jmp KoniecProcedury

Klawiatura:	
		mov al, 11000000b  ; j/w tylko ze numer 000 to wskazanie wejscia 0  jako najnizszego priorytetem
						   ; klawiatura otrzyma priorytet 0, zegar 7 wiec nie moze przerwac przerwania klawiatury
		out	20h, al
		mov Priorytet, 0h

KoniecProcedury:		
		sti ; IF=1
		ret
		ENDP

;============================================================

PrzerwKlaw	PROC	FAR
		;procedura przejecie przerwania klawiatury aby pokazac poczatek i koniec obslugi przerwania klawiatury
		
		sti
		push	ax
		push	bx
		push	cx
		push	ds
		mov	ax, SEG Dane    
		mov	ds, ax
		WyswietlZnakBios '<' ;wyswietlamy znak dajac informacje ze rozpoczelo sie przerwanie klawiatury
		mov	ax, 1000
		
PetlaZewn:
		mov	cx, 0FFFFh
		
PetlaWewn:
		loop	PetlaWewn ;pewnego rodzaju pauza, loop wykona sie tyle razy ile CX=0FFFFh
						  ;bez tej pauzy ciezko by bylo pokazac ze faktycznie przerwanie klawiatury nie jest przerywane
		dec	ax
		jnz	PetlaZewn
		WyswietlZnakBios '>'
		
		pushf			; odlozenie flag
		call	WektorKlaw	; - oryginalny wektor obslugi przerwania
		
		pop	ds
		pop	cx
		pop	bx
		pop	ax
		iret			; przywrocenie flag i rejestrow
		ENDP

Kod		ENDS
;=========================================================



Stosik		SEGMENT	STACK

		DB	100h DUP (?)

Stosik		ENDS

END		Start