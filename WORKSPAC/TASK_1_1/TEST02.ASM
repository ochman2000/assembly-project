; wersja TASM
.model tiny
.code
org 100h

start:
	mov	ah, 9	;AH jest g¢rn¥ cz©˜ci¥ AX
	mov	dx, offset info
	int	21h	;to przerwanie korzysta z AH, DS:DX
	mov	ah, 0	;AH jest g¢rn¥ cz©˜ci¥ AX
	int	16h	;to przerwanie korzysta z AH i AL
	mov	ax, 4c00h
	int	21h	;to przerwanie korzysta a AH (AX)
	
info	db	"Czesc.$"

end start