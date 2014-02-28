; wersja TASM
.model tiny
.stack 40H
.code
org 100h

start:
	;*****************************************************
	;W PRZYPADKU PROGRAMU TYPU *.EXE WYMAGANY JEST SEGMENT
	;JEŚLI GO NIE PODASZ, TO ADRES W REJESTRZE DS BEDZIE INNY
	;NIZ TEN W KTORYM ZNAJDUJE SIE ZADEKLAROWANA TABLICA ZNAKOW:
	; powitanie	db	". Czesc ziomek", 10, 13, "$"
	;WTEDY NA EKRANIE POJAWIĄ SIE KRZAKI ZAMIAST TEKSTU.
	;*****************************************************
	mov ax, SEG array01
	mov ds, ax
	
print:
	;READ VALUE FROM MEMORY (1 BYTE) AND DISPLAY IT AS ASCII
	mov	dl, znak			;pobierz wartość zmiennej
	mov	ah, 2				;parametr funkcji 21h 
	int	21h					;System.out.print(char)
	
	;READ ADDRESS (POINTER) FROM MEMORY (2 BYTE) AND DISPLAY IT AS ASCII
	mov	dx, offset znak		;pobierz adres zmiennej
	mov	ah, 2				;parametr funkcji 21h 
	int	21h					;System.out.print(char)
	
	;READ ADDRESS (POINTER) FROM MEMORY (2 BYTE) AND PRINT ALL VALUES
	;IN THE ARRAY TERMINATED BY "$" SIGN
	mov	dx, offset znak		;pobierz adres zmiennej
	mov	ah, 9				;parametr funkcji 21h
	int	21h					;System.out.print(String)

store;
	;STORE DATA INTO MEMORY AT VARIABLE znak
	mov bx, offset znak;	;bx=znak
	mov byte ptr [bx], cl
	
return:
	mov	ax, 4c00h			;paremetr funkcji 21h
	int	21h					;System.exit(ax)

;=========================================
;SEKCJA DEKLARACJI ZMIENNYCH

array01		db	". ASCII Character no. ", "$"
newLine 	db	" | ", "$"
hundreds 	db 48;
tens	 	db 49;
znak		db	0;
;=========================================
end start