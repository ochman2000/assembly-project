;=============================================================================;
;                                                                             ;
; Plik           : test01.asm                                                   ;
; Format         : EXE                                                        ;
; Cwiczenie      : Czyszczenie ekranu
; Autorzy        : £ukasz Ochmañski
; Data zaliczenia: 25.01.2014                                                 ;
;                                                                             ;
;=============================================================================;
		
		.MODEL	SMALL

WczytZn MACRO

	mov ah, 08h
	int	21h
	
	ENDM
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

Wyczysc MACRO

		mov ax,0B800h	;wyczysc ekran
		mov es,ax 
		mov cx,25*80	;licznik=25 linii po 80 pol (bx porusza sie co 2 pola)
		xor bx,bx 	;wyzerowanie bx
wyczysc_ekran: 
		mov byte ptr es:[bx],0 ;czyscimy odpowiednie pola
		add bx,2 
		loop wyczysc_ekran
		
		ENDM
		
;---------------------------------------------------------------;

Dane	SEGMENT
txtPowitanie DB "Program do czytania klawiatury", 13,10,"$"
txtWyj DB "[5] Wyjscie" ,13,10, "$"
txtWcisnieto DB "Wci", 152 ,"ni",169, "to klawisz; " ,13,10, "$"
txtWcisnieto1 DB "Wci", 152 ,"ni",169, "to klawisz 1" ,13,10, "$"
txtWcisnieto2 DB "Wci", 152 ,"ni",169, "to klawisz 2" ,13,10, "$"
txtWcisnieto3 DB "Wci", 152 ,"ni",169, "to klawisz 3" ,13,10, "$"
txtWcisnieto4 DB "Wci", 152 ,"ni",169, "to klawisz 4" ,13,10, "$"
txtPrompt DB "Przyci",152,"nij klawisze od 1 do 6; " ,13,10, "$"
Dane	ENDS

Kod		SEGMENT
	ASSUME  CS:Kod, DS:Dane, SS:Stosik
;--------------------------------------------------------;
Start:
	mov ax, SEG Dane	;przeslanie pozycji segmentu danych do ax
    mov ds, ax			;wpisanie pozycji do rejestru segmentowego danych
	
	WysNap txtPowitanie 
	WysNap txtPrompt
;menu wyboru opcji
Menu:
	WczytZn
	
	cmp al, '1'
	je klawisz1
	
	cmp al, '2'
	je klawisz2
	
	cmp al, '3'
	je klawisz3
	
	cmp al,	'4'
	je klawisz4
	
	cmp al, '5'
	je klawisz5
	
	cmp al, '6'
	je klawisz6
	
	jmp Menu
	

klawisz1:
	WysNap txtWcisnieto1
	jmp Menu
klawisz2:
	WysNap txtWcisnieto2
	jmp Menu
klawisz3:
	WysNap txtWcisnieto3
	jmp Menu
klawisz4:
	WysNap txtWcisnieto4
	jmp Menu
klawisz5:	
	Koniec_M
klawisz6:
	Wyczysc 
	jmp Menu	
Kod		ENDS

Stosik	SEGMENT	STACK
	DB	100h DUP (?)
Stosik	ENDS

END Start