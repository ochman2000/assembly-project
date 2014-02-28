; wersja TASM
.model tiny
.code
org 100h

start:
	mov	ah, 9	;AH jest g¢rn¥ cz©˜ci¥ AX
	mov	dx, offset info
	int	21h	;to przerwanie korzysta z AH, DS:DX


return:
	mov	ax, 4c00h
	int	21h	;to przerwanie korzysta a AH (AX)
	
info	db	"Czesc", 10, 13, "ziom",162, 07Ch, "s", 10, 13, 10, 13, "$"

end start