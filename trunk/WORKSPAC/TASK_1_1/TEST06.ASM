; wersja TASM
.model tiny
.stack 40H
.code
org 100h

start:
	mov	cx, 48		;cx=48;
	;*****************************************************
	;W PRZYPADKU PROGRAMU TYPU *.EXE WYMAGANY JEST SEGMENT
	;JEŚLI GO NIE PODASZ, TO ADRES W REJESTRZE DS BEDZIE INNY
	;NIZ TEN W KTORYM ZNAJDUJE SIE ZADEKLAROWANA TABLICA ZNAKOW:
	; powitanie	db	". Czesc ziomek", 10, 13, "$"
	;WTEDY NA EKRANIE POJAWIĄ SIE KRZAKI ZAMIAST TEKSTU.
	;*****************************************************
	mov ax, SEG powitanie
	mov ds, ax
	
print:
	mov	ah, 2		;parametr funkcji 21h
	mov	dx, cx		;parametr funkcji 21h
	int	21h			;System.out.print(char)
	mov	ah, 9		;parametr funkcji 21h
	mov	dx, offset powitanie	;parametr funkcji 21h
	int	21h			;System.out.print(string)
	
petla:
	inc	cx
	cmp	cx, 58
	je	return
	jmp	print
	
return:
	mov	ax, 4c00h	;paremetr funkcji 21h
	int	21h			;System.exit(ax)

;=========================================
;SEKCJA DEKLARACJI ZMIENNYCH

powitanie	db	". Czesc ziomek", 10, 13, "$"

end start