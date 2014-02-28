;=============================================================================;
;                                                                             ;
; Plik           : zad1.asm                                                   ;
; Format         : EXE                                                        ;
; Cwiczenie      : Sterownik przerwañ 8259A i zegar/licznik 8253              ;
; Autorzy        : Daniel Boœnjak  			  ;
; Data zaliczenia: 26.10.2010                                                 ;
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

;--------------------------------------------------;


Dane	SEGMENT

Org_Vect_08h DD ?
Org_Vect_09h DD ?

znak DB 30
gdzie DW 0
kolor DB 00000001b

predkosc DB 1
licznik DB 0

txtPowitanie DB "Program do zmieniania priorytetow przerwan", 13, 10, "$"
txtPrKl DB "[1] Ustaw priorytet klawiatury" ,13,10, "$"
txtPrZg DB "[2] Ustaw priorytet zegara" ,13,10, "$"
txtPrzys DB "[3] Przyspiesz zegar 4x" , 13,10,"$"
txtZwol DB "[4] Zwolnij zegar" ,13,10,"$"
txtWyj DB "[5] Wyjscie" ,13,10, "$"

Dane	ENDS

Kod		SEGMENT

	ASSUME  CS:Kod, DS:Dane, SS:Stosik
;------------------------------------------------------------;
New_handler_08h	PROC FAR		;nowa testowa procedura obs³ugi przerwania zegara
	sti
	push ds
	push ax
	push bx
	push si
	push es

	mov bx, SEG Dane 	; ustaw segment danych
    mov ds, bx
	
	mov bx, 0B800h ;adres ekranu
	mov es, bx
	
	
	mov si, gdzie
	mov ah, znak
	mov al, kolor
	
	mov BYTE PTR es:[si], ah
	mov BYTE PTR es:[si+1], al
	
	mov ax, gdzie
	inc ax
	inc ax
	mov gdzie, ax
	cmp ax, 80*2
	jb Orgin
	
	mov ax,0
	mov gdzie, ax
	
	mov al, kolor
	inc al
	mov kolor, al
Orgin:	
	xor bx,bx

	mov bl, licznik
	inc bl
	mov licznik, bl
	cmp bl, predkosc
	jb Eoi
	
	mov licznik, 0
	pushf
	call Org_Vect_08h
	jmp koniec_08h
Eoi: 
	mov al, 01100000b
	out 20h, al
koniec_08h:
	pop es
	pop si
	pop bx
	pop ax
	pop ds

	iret
New_handler_08h	ENDP
;------------------------------------------------------------;	
New_handler_09h	PROC FAR		;nowa procedura obs³ugi przerwania klawiatury
	
	sti
	push ds
	push cx
	push dx
	push ax
	push bx
	push si

	mov bx, SEG Dane 	; ustaw segment danych
    mov ds, bx 

	mov al, znak
	inc al
	mov znak,al
	
	mov cx, 0ffffh
petla:
	
	push cx
    mov cx, 03ffh
petla2:
	loop petla2
	pop cx
	loop petla
	
	pushf
	call Org_Vect_09h
	
	pop si
	pop bx
	pop ax
	pop dx
	pop cx
	pop ds

	iret
New_handler_09h	ENDP
;--------------------------------------------------------;
Start:
	

	mov ax, SEG Dane	;przeslanie pozycji segmentu danych do ax
    mov ds, ax			;wpisanie pozycji do rejestru segmentowego danych
	xor	ax,ax
	ZmOCW2 11000111b 	;przywraca standardowy priorytet przerwan
	
;pobranie i ustawienie wektorów przerwañ

	mov ah, 35h		;pobieranie aktualnego wektora przerwañ uk³adu czasowego
	mov al, 08h
	int 21h
	mov WORD PTR Org_Vect_08h, bx;	;zapamietanie aktualnego wektora przerwañ
	mov WORD PTR Org_Vect_08h + 2, es;
	;;ustawienie wektora przerwañ dla uk³adu czasowego
	mov dx, offset New_handler_08h
	mov	ax, SEG Kod
	mov	ds, ax	
	mov ah, 25h
	mov al, 08h		
	int 21h
	
	mov	ax, SEG Dane
	mov	ds, ax
	
	mov ah, 35h		;pobieranie aktualnego wektora przerwañ klawiatury
	mov al, 09h
	int 21h
	mov WORD PTR Org_Vect_09h, bx;	;zapamietanie aktualnego wektora przerwañ
	mov WORD PTR Org_Vect_09h + 2, es;
	;;ustawienie wektora przerwañ dla klawiatury
	
	mov	ax, SEG Kod
	mov	ds, ax
	mov ah, 25h
	mov al, 09h	
	mov dx, offset New_handler_09h
	int 21h
	
	mov	ax, SEG Dane
	mov	ds, ax
	
	
	mov bh,0
	mov dh,2
	mov dl,0
	mov ah,02h
	int 10h
	
	xor ax,ax
	
	WysNap txtPowitanie 
	WysNap txtPrKl 
	WysNap txtPrZg 
	WysNap txtPrzys 
	WysNap txtZwol 
	WysNap txtWyj 
;menu wyboru opcji
Menu:
	WczytZn
	
	cmp al, '1'
	je PrioKlaw
	
	cmp al, '2'
	je PrioZegar
	
	cmp al, '3'
	je Przyspiesz
	
	cmp al,'4'
	je Zeruj
	
	cmp al, '5'
	je Koniec
	
	jmp Menu
	
PrioKlaw:
	ZmOCW2 11000000b ;najni¿szy priorytet ma wejœcie przerwañ nr 0
	jmp Menu
PrioZegar:
	ZmOCW2 11000111b ;najni¿szy priorytet ma wejœcie przerwañ nr 7;
	jmp Menu
	
Przyspiesz:
	cli
	mov al, 00110110b
	out 43h, al
	
	mov al, 00h
	out 40h, al
	
	mov al, 40h
	out 40h, al
	
	mov predkosc, 4
	mov licznik, 0
	sti
	
	jmp Menu
	
Zeruj:
	cli
	mov al, 00110110b
	out 43h, al
	
	mov ax, 0
	out 40h, al
	mov al,ah
	out 40h, al
	
	mov predkosc, 1
	mov licznik, 0
	
	sti
	
	jmp Menu

Koniec:	
;koncowka
	ZmOCW2 11000111b ;przywrocenie priorytetow
	;przywrocenie pierwotej predkosci
	cli
	mov al, 00110110b
	out 43h, al
	
	mov ax, 0
	out 40h, al
	mov al,ah
	out 40h, al
	
	mov predkosc, 1
	mov licznik, 0
	
	sti
;odtworzenie wektorów przerwañ
	
	mov ah, 25h
	mov al, 08h
	lds dx, Org_Vect_08h
	int 21h
	
	mov	ax, SEG Dane
	mov	ds, ax
	
	mov ah, 25h
	mov al, 09h
	lds dx, Org_Vect_09h
	int 21h
	
	Koniec_M
Kod		ENDS

Stosik	SEGMENT	STACK
	DB	100h DUP (?)

Stosik	ENDS

END Start