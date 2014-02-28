;***********************************************************************************
;	Program AK29.asm typu exe						   *
;	Dodawanie jednocyfrowych liczb calkowitych bez znaku (wynik jednocyfrowy)  *
;	Wartosci liczb podajemy z klawiatury. Sume wyswietlamy na ekranie.	   *
;***********************************************************************************
	.MODEL TINY
	.STACK 40H
	.DATA
KOM	DB 13,10,"Dodawanie jednocyfrowych liczb calkowitych bez znaku$"
KOM1	DB 13,10,"a = $"
KOM2	DB 13,10,"b = $"
KOM3	DB 13,10,"suma = a + b = $"
	BUF1 DB 2 DUP (?)	;tablica na postac tekstowa pierwszego skladnika
	BUF2 DB 2 DUP (?)	;tablica na postac tekstowa drugiego skladnika
	BUF_WYNIK DB 2 DUP (?)	;tablica na postac tekstowa sumy
	SKLADNIK1 DW (?)
	SKLADNIK2 DW (?)
	SUMA DW (?)
	.CODE
;******	Makra i procedury ***************
;*** Wyswietlenie komunikatu TEKST ***
WYSWIETL MACRO TEKST
	MOV DX,OFFSET TEKST
	MOV AH,9
	INT 21H
	ENDM
;------------
;*** Wczytanie liczby z klawiatury do zmiennej BUFOR typu String ***
CZYTAJ	MACRO BUFOR
	;uzupelnic tresc makrodefinicji
	ENDM
;------------
;*** konwersja zmiennej BUFOR (String) do zmiennej SKLADNIK typu naturalnego ***
KONW	MACRO BUFOR,SKLADNIK
	;uzupelnic tresc makrodefinicji
	ENDM
;------------
;*** obliczenie zmiennej WYNIK = A + B ***
	;*** wersja z zastosowaniem procedury ***
DODAJ	PROC
	PUSH AX
	PUSH BP
	MOV BP,SP
	;uzupelnic tresc procedury
	POP BP
	POP AX
	RET 2		;powrot z procedury ze zdjeciem jednego parametru
DODAJ	ENDP
;------------
;*** konwersja zmiennej LICZBA do zmiennej BUFOR typu String$ ***
KONW10	MACRO LICZBA,BUFOR
	;uzupelnic tresc makrodefinicji
	ENDM
;------------
;****** Koniec makr i procedur ************
;=================================================
START:	MOV AX,@data
	MOV DS,AX
	WYSWIETL KOM
	WYSWIETL KOM1
	CZYTAJ BUF1		;wczytanie do BUF1 pierwszego skladnika
	KONW BUF1,SKLADNIK1	;konwersja z postaci tekstowej do obliczeniowej
	WYSWIETL KOM2
	CZYTAJ BUF2		;wczytanie do BUF2 drugiego skladnika
	KONWU2 BUF2,SKLADNIK2	;konwersja z postaci tekstowej do obliczeniowej
	PUSH SKLADNIK1		;przekazanie parametru do procedury przez stos
	PUSH SKLADNIK2		;przekazanie parametru do procedury przez stos
	CALL DODAJ
	POP SUMA		;zdjecie ze stosu wyniku procedury
	KONW10 SUMA,BUF_WYNIK	;konwersja z postaci obliczeniowej do tekstowej
	WYSWIETL KOM3
	WYSWIETL BUF_WYNIK	;wyswietlenie sumy
	MOV AH,4CH
	INT 21H
	END START
	END