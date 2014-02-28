; wersja TASM
.model tiny
.STACK 40H
.DATA
;=========================================
;SEKCJA DEKLARACJI ZMIENNYCH

info	db	". Czesc ziomek", 10, 13, "$"
;=========================================
;TU ZACZYNA SIĘ PROGRAM
.CODE

DODAJ	PROC
	PUSH AX		;skopiuj zawartosc rejestru do pamieci operacyjnej
	PUSH BP		;skopiuj zawartosc rejestru do pamieci operacyjnej
	MOV BP, SP	;uzyj rejestru do innych celow
	ADD BP,6 ;BP adresuje pierwszy parametr procedury

	;tu trzeba wyprintowac dziada
	;--------a---------
	mov	ah, 2		;parametr funkcji 21h
	mov	dx, [BP+4]		;parametr funkcji 21h
	int	21h		;System.out.print(ch)
	mov	dx, 10		;parametr funkcji 21h
	int	21h		;System.out.print(ch)
	mov	dx, 13		;parametr funkcji 21h
	int	21h		;System.out.print(ch)
	;--------b---------
	mov	dx, [BP+2]	;parametr funkcji 21h
	int	21h		;System.out.print(ch)
	mov	dx, 10		;parametr funkcji 21h
	int	21h		;System.out.print(ch)
	mov	dx, 13		;parametr funkcji 21h
	int	21h		;System.out.print(ch)
	;--------suma---------
	mov	dx, [BP]		;parametr funkcji 21h
	int	21h		;System.out.print(ch)
	mov	dx, 10		;parametr funkcji 21h
	int	21h		;System.out.print(ch)
	mov	dx, 13		;parametr funkcji 21h
	int	21h		;System.out.print(ch)
	
	POP BP	;przywroc wartosc rejestru BP, korzystajac z zawartosci stosu
	POP AX	;przywroc wartosc rejestru AX, korzystajac z zawartości stosu
	RET 6		;powrot z procedury ze zdjeciem trzech parametrow (3*2)
DODAJ	ENDP
;------------
;****** Koniec makr i procedur ************
;=================================================

start:
	
dodawanie:
	push 48	;a=1
	push 49
	push 50
	call dodaj

return:
	mov	ax, 4c00h	;paremetr funkcji 21h
	int	21h		;System.exit(ax)
end start
end