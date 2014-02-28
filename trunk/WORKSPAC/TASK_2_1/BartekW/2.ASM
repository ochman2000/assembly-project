
                .MODEL  TINY
IFDEF CON
	DISPLAY "<< Kompilacja sterownika konsoli >>"
ELSEIFDEF LPT1
	DISPLAY "<< Kompilacja sterownika drukarki >>"
ELSE 
	DISPLAY "!! Nie zdefiniowano urz¹dzenia ( CON albo LPT ) !!"
	ERR
ENDIF


WyswietlZnak	MACRO 	Znak
	push ax
	mov al, Znak
IFDEF CON
	mov ah, 0eh					;znak na ekran
	int 10h
ELSEIFDEF LPT1	
	mov ah, 00h					;znak do drukarki
	mov dx, 0
	int 17h
	;mov ah, 0eh					;znak na ekran
	;int 10h
ENDIF
	pop ax	
ENDM

		.CODE
Start:
			;NAGLOWEK STEROWNIKA
		dd	-1	;Adres nastêpnego sterownika

		db	00000000b	;Atrybuty (bity 7-0 )
		db	10000000b	;Atrybuty (bity 15-8 )
		dw	OFFSET ProcSzeregujaca
		dw	OFFSET ProcWykonawcza	
		db	'ARCH2   '	
		

			;KONIEC NAGLOWKA STEROWNIKA


AdresPakietuS	dw	?		;segment 
AdresPakietuP	dw	?		;przesuniecie

SekwSter	db	0
WszystkieDuze	db	0


ProcSzeregujaca	PROC FAR
		mov	cs:AdresPakietuS, es
		mov	cs:AdresPakietuP, bx
		ret

ProcSzeregujaca	ENDP


ProcWykonawcza	PROC FAR
		pushf
		push	es
		push	bx
		push	ax
		push	ds

		push	cs
		pop	ds

		mov	bx, AdresPakietuS		
		mov	es, bx
		mov	bx, AdresPakietuP	
	
		mov	ax, es:[bx+2]	;pobiera numer funkcji

		
spr0h:
		cmp	ax, 0h
		jne	spr8h
		call	Proc0h		
		
spr8h:
		cmp	ax, 8h
		jne	koniec
		call	Proc8h
koniec:
		mov	ah, 00000001b
		mov	al, 0
		mov	es:[bx+3], ax
		
		pop	ds
		pop	ax
		pop	bx
		pop	es
		popf
		ret

ProcWykonawcza	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Proc8h		PROC NEAR	;Zapis
		push	bx
		push	es
		push	ax
		push	cx
		push	es

		mov	ax, es:[bx+10h]
		mov	bx, es:[bx+0eh]
		mov	es, ax

		mov	al, es:[bx] ;pobierz znak
		
		cmp	al, '@'
		jne	inny
		
		cmp	SekwSter, 0
		je	nowy_rozkaz
				
		jmp	wyswietl	;wyswietl '@' bo byly 2 pod rzad
nowy_rozkaz:
		mov	SekwSter, 1
		jmp	powrot
inny:
		cmp	al, '+'
		jne	inny2
		cmp	SekwSter, 0
		je	wyswietl	;gdy sam + bez @ to go wyswetl
		mov	WszystkieDuze, 1
		mov	SekwSter, 0
		jmp	powrot
inny2:
		cmp	al, '-'
		jne	inny3
		cmp	SekwSter, 0
		je	wyswietl	;gdy sam - bez @ to go wyswetl
		mov	WszystkieDuze, 0
		mov	SekwSter, 0
		jmp	powrot
inny3:
		cmp	WszystkieDuze, 0
		je	dalej
		cmp	al, 'a'
		jb	dalej
		cmp	al, 'z'
		ja	dalej			
		sub	al, 32		;zmien z malej na duza
;;;;;;;;;;;;;;;;;;;;;;;;;;;
dalej:
		cmp	SekwSter, 1
		jne	wyswietl
		push	ax

		;mov	al, '@'
		;mov	ah, 0eh
		;mov	bl, 0
		;int	10h
		WyswietlZnak	'@'
		mov	SekwSter, 0

		pop	ax

wyswietl:
		WyswietlZnak al
		;mov	ah, 0eh
		;mov	bl, 0
		;int	10h

powrot:
		pop	es
		pop	cx
		pop	ax
		pop	es
		pop	bx
		
		ret

Proc8h		ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Proc0h		PROC NEAR	;procedura inicjalizujaca
		push	dx
		push	ax

                mov     dx, OFFSET txtPowitanie
                mov     ah, 09h
                int     21h
	
		mov	WORD PTR es:[bx+0eh], OFFSET Proc0h		
		mov	WORD PTR es:[bx+10h], cs	
		pop	ax
		pop	dx
		
		ret

Proc0h		ENDP


txtPowitanie	db	">>> Sterownik urzadzenia v0.9b <<<",13,10,"$"

		END     Start