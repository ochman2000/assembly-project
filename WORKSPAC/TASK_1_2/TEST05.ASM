; wersja TASM
.model tiny
.code
org 100h

start:
	mov	cx, 48
	
print:
	mov	ah, 2		;parametr funkcji 21h
	mov	dx, cx		;parametr funkcji 21h
	int	21h		;System.out.print(ch)
	mov	ah, 9		;parametr funkcji 21h
	mov	dx, offset info	;parametr funkcji 21h
	int	21h		;System.out.print(dx)
	
petla:
	inc	cx
	cmp	cx, 58
	je	return
	jmp	print
	
return:
	mov	ax, 4c00h	;paremetr funkcji 21h
	int	21h		;System.exit(ax)

;=========================================
;SEKCJA DEKLARACJI ZMIENNYCH

info	db	". Czesc ziomek", 10, 13, "$"

end start