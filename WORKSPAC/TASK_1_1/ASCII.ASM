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
	
	mov	cl, 0			;cx=0;
pobierz_adres_zmiennej_znak:
	mov ax, offset znak;	;ax=i
	mov bx, ax
	
print:
	mov	ah, 2				;parametr funkcji 21h
	;READ FROM MEMORY
	mov	dl, znak			;pobierz wartość zmiennej
	;mov dx, offset znak	;pobierz adres zmiennej
	int	21h					;System.out.print(char)
	
	mov	ah, 9				;parametr funkcji 21h
	mov	dx, offset newLine	;parametr funkcji 21h (adres tablicy bajtów)
	int	21h					;System.out.print(String)
	
petla:
	inc	cl
	;STORE DATA INTO VARIABLE AT ADDRESS bx
	mov byte ptr [bx], cl
	cmp	cl, 255
	je	return
	jmp	print
	
return:
	mov	ax, 4c00h	;paremetr funkcji 21h
	int	21h			;System.exit(ax)

;=========================================
;SEKCJA DEKLARACJI ZMIENNYCH

array01	db	". ASCII Character no. ", "$"
newLine db	" | ", "$"
hundreds db 48;
tens	 db 49;
znak	db	0;
end start