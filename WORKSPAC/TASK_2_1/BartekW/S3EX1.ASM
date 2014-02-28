;=============================================================================;
;                                                                             ;
; Plik           : s3ex1.asm                                                  ;
; Format         : EXE                                                        ;
; Cwiczenie      : Sterownik przerwañ 8259A i zegar/licznik 8253              ;
; Autorzy        : Bartosz Wieczorek, Daniel Bosnjak grupa, niedziela, 12:15  ;
; Data zaliczenia: 04.11.2012                                                 ;
;                                                                             ;
;=============================================================================;
		.MODEL	SMALL
; -- MAKRA --
OdczytZ MACRO
	mov ah, 08h
	int	21h
	ENDM
WypiszN	MACRO	Napis
	mov 	dx, offset Napis
	mov 	ah, 09h
	int 	21h
	ENDM
ZmOCW2	MACRO	priorytet
	mov	al,priorytet
	out	20h, al;
	ENDM
;--------------------------------------------------;
Dane	 SEGMENT

Org_Vect_08h DD ?
Org_Vect_09h DD ?

gdzie    DW 1600
kolor    DB 72h
predkosc DB 1
licznik  DB 0
txtMenu  DB  "  Program zmieniajacy priorytety przerwan oraz                                ", 13, 10
	 DB  "czestotliwosc generowania przerwania zegarowego.                              ", 13, 10
	 DB  79 dup (" ")
	 DB  13, 10, "[1] Ustaw priorytet klawiatury                                        "
	 DB  13, 10, "[2] Ustaw priorytet zegara                                            "
	 DB  13, 10, "[3] Przyspiesz zegar do prêdkoœci czterokrotnej                       "
	 DB  13, 10, "[4] Przyroc domyslna predkowsc zegara                                 "
	 DB  13, 10, "[5] Wyjscie                                                           " 
	 DB  13, 10, 79 dup (" ")
	 DB  13, 10, 25 dup('-'), " SYMULACJA DRUKOWANIA ZNAKOW ", 24 dup('-')
	 DB  13, 10, 319 dup (" ")
	 DB  13, 10, 25 dup('-'), " SYMULACJA DRUKOWANIA ZNAKOW ", 24 dup('-'), '$'
Dane	 ENDS

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

	mov bx, SEG Dane
	mov ds, bx
	; zapisujemy do ES adres ekranu
	mov bx, 0B800h 
	mov es, bx
	
	mov si, gdzie
	mov ah, predkosc
	add ah, 48
	mov al, kolor
	
	mov BYTE PTR es:[si], ah
	mov BYTE PTR es:[si+1], al
	
	mov ax, gdzie
	inc ax
	inc ax
	mov gdzie, ax
	cmp ax, 2240
	jb Orgin
	; wracamy na poczatek wiersza drukowania znakow
	mov ax,1600
	mov gdzie, ax
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

	mov bx, SEG Dane
	mov ds, bx
	mov al, kolor 
	sub al, 70h
	inc al
	and al, 7
	add al, 70h
	mov kolor, al

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
	mov ds, ax		;wpisanie pozycji do rejestru segmentowego danych
	xor	ax,ax
	ZmOCW2 11000111b 	;przywraca standardowy priorytet przerwan

	;pobranie aktualnego wektora przerwañ uk³adu czasowego
	mov ah, 35h
	mov al, 08h
	int 21h
	mov WORD PTR Org_Vect_08h, bx
	mov WORD PTR Org_Vect_08h + 2, es
	;pobieranie aktualnego wektora przerwañ klawiatury
	mov ah, 35h		
	mov al, 09h
	int 21h
	mov WORD PTR Org_Vect_09h, bx;
	mov WORD PTR Org_Vect_09h + 2, es
	; ustawienie wektora przerwañ dla uk³adu czasowego
	mov dx, offset New_handler_08h
	mov ax, SEG Kod
	mov ds, ax	
	mov ah, 25h
	mov al, 08h		
	int 21h
	; ustawienie wektora przerwañ dla klawiatury
	mov dx, offset New_handler_09h
	mov ax, SEG Kod
	mov ds, ax
	mov ah, 25h
	mov al, 09h	
	int 21h
	
	mov ax, SEG Dane
	mov ds, ax
	; chcemy zaj¹æ programem ca³y ekran, wiêc skaczemy do (0,0)
	mov ah, 02h
	mov bh, 0
	mov dh, 0
	mov dl, 0
	int 10h
	xor ax,ax
	; wyœwietlenie menu i reakcja na wybór u¿ytkownika
	WypiszN txtMenu
Menu:
	OdczytZ
	cmp al, '1'
	je MaxPriorytetKlawiatury
	cmp al, '2'
	je MaxPriorytetZegara
	cmp al, '3'
	je PredkoscZegara_x4
	cmp al, '4'
	je PredkoscZegara_x1
	cmp al, '5'
	je Koniec
	jmp Menu
MaxPriorytetKlawiatury:
	ZmOCW2 11000000b ;najni¿szy priorytet dostaje IRQ0, wiêc IRQ1 (klawiatura) dostaje najwy¿szy
	jmp Menu
MaxPriorytetZegara:
	ZmOCW2 11000111b ;najni¿szy priorytet dostaje IRQ7, wiêc IRQ8 (zegar) dostaje najwy¿szy
	jmp Menu
PredkoscZegara_x4:
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
PredkoscZegara_x1:
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
	;przywrocenie priorytetow
	ZmOCW2 11000111b 
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
	; odtworzenie wektorów przerwañ
	mov ah, 25h
	mov al, 08h
	lds dx, Org_Vect_08h
	int 21h
	
	mov ax, SEG Dane
	mov ds, ax
	mov ah, 25h
	mov al, 09h
	lds dx, Org_Vect_09h
	int 21h
	; wyjœcie z programu
	mov	ax, 4C00h
	int	21h

Kod		ENDS

Stosik	SEGMENT	STACK
	DB	100h DUP (?)

Stosik	ENDS

END Start
