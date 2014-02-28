;============================================================
; Plik           : arch2-2.asm 
; Format         : SYS
; Cwiczenie      : Cwiczenie 2-2
; Autorzy        : Bartosz Cichecki, Jaroslaw Stempniak
; Data zaliczenia: 17.11.2010 / sroda, 16:30
;============================================================

.MODEL  TINY

;******************************************                                                         ####### DrukujZnakanie komunikatu
;DrukujZnakenie komunikatu podczas kompilacji

DISPLAY "------------------"

IFNDEF dev
	DISPLAY "ERROR: Brak symbolu dev"
ELSEIF dev EQ 1
	DISPLAY "Sterownik dla konsoli"
ELSEIF dev EQ 0
	DISPLAY "Sterownik dla drukarki"
ELSE
	DISPLAY "ERROR: Nieznana wartosc. 1 dla konsoli, 0 dla drukarki"
ENDIF

DISPLAY "------------------"
;*******************************************



;*******************************************                                                         ####### Macro wypisujace na CON/PRN
;MACRO - Wyslanie znaku na konsole / do drukarki
DrukujZnakCONlubPRN    MACRO   Znak
        IFNB <Znak>
                mov     al, Znak
        ENDIF

        IF dev EQ 1	;Drukuj znak na konsoli
                mov     ah, 0eh 
                mov     bl, 0 ;przezroczyste dla dos
                int     10h
        ELSEIF dev EQ 0 ;Wyslanie jednego bajta (znaku) do drukarki
                mov     ah, 00h
                mov     dx, 0h ;numer portu LPT
                int     17h
        ENDIF
ENDM
;*******************************************



;*******************************************                                                         ####### Kod programu
;Wlasciwy kod programu

.CODE
Start:

	;NAGLOWEK STEROWNIKA                                                                             ####### Naglowek sterownika
	;*******************
	;przechowuje najwazniejsze informacje do wspolpracy z systemem operacyjnym
	;18 bajtow dlugosci
	
	;00h | 4 bajty | adres nastepnego sterownika
	dd      -1
	;04h | 2 bajty | atrybuty
	db      00000000b ;tutaj bity od 7 do 0
					;bit 7 - 0 - brak obslugi sprawdzania dopuszczalnosci operacji we/wy
					;bit 6 - 0 - dla znakowych - brak obslugi funkcji sterowania konfiguracja dla klasy urzadzen
					;bit 5 - 0 - niezidentyfikowany
					;bit 4 - 0 - urzadzenie znakowe, nie CON, nieuzywany bit
					;bit 3 - 0 - urzadzenie nie bedace zegarem systemowym
					;bit 2 - 0 - urzadzenie nie zerowe
					;bit 1 - 0 - urzadzenie znakowe, nie standardowe (nie CON)
					;bit 0 - 0 - urzadzenie znakowe, nie standardowe (nie CON)
					  
	db      10000000b ;tutaj bity od 15 do 8
					;bit 15 - 1 - urzadzenie znakowe
					;bit 14 - 0 - brak obslugi nadania/odbioru znaku sterujacego
					;bit 13 - 0 - dla znakowych, brak obslugi nadania grupowego
					;bit 12 - 0 - niezidentyfikowany
					;bit 11 - 0 - dla znakowych, brak funkcji zajecia/zwolnienia urzadzenia
					;bit 10,9,8 - 0 - niezidentyfikowany
	;06h | 2 bajty | przesuniecie procedury szeregujacej
	dw      OFFSET ProceduraSzeregujaca
	;08h | 2 bajty | przesuniecie procedury wykonawczej
	dw      OFFSET ProceduraWykonawcza
	;0Ah | 8 bajtow | nazwa urzadzenia
	db      'NOWYSTER'
	;KONIEC NAGLOWKA STEROWNIKA
	;*******************


	PakietSeg dw ? ;tu bedzie przechowany segment pakietu zlecenia
	PakietOff dw ? ;tu bedzie offset pakietu zlecenia

	SterowanieON db 0 ;czy program jest w sekwencji sterowania
	UpperCase db 0 ;czy program wypisuje tylko duze

;*******************************************                                                         ####### Procedura szeregujaca
;Procedura Szeregujaca
;odpowiada za zapamietanie adresu przekazywanego pakietu zlecenia
ProceduraSzeregujaca PROC FAR
    mov     cs:PakietSeg, es ;segment w ktorym znaduje sie pakiet zlecenia
    mov     cs:PakietOff, bx ;przesuniecie tego pakietu
    ret
ProceduraSzeregujaca ENDP
;*******************************************



;*******************************************                                                         ####### Procedura wykonawcza
;Procedura wykonawcza
;w oparciu o zapamietany adres odczytuje pakiet zlecenia i okresla jaka funkcja zostala zlecona			//W jaki sposób okreœla??? 
ProceduraWykonawcza  PROC FAR

	;zapamietanie rejestru flagowego i uzywanych rejestrow
    pushf
    push    es
    push    bx
    push    ax
	push    ds
	push    cs
    pop     ds

	;jako ES:BS laduje seg:offset pakietu zlecenia
	mov     bx, PakietSeg ;zapamietuje do es (tymczasowo do ax) segment pakietu zlecenia (wczesniej zapamietany w szeregujacej)
    mov     es, bx
    mov     bx, PakietOff ;j/w tylko offset do bx
	mov     ax, es:[bx+2] ;pobiera numer funkcji z pakietu zlecenia


CzyInicjalizujaca:
    cmp     ax, 0h ;Sprawdzenie czy pobrana funkcja to funkcja inicjalizujaca
    jne     CzyZapisujaca ;jesli nie to skok do CzyZapisujaca
    call    Funkcjainicjalizujaca ;jesli tak to skok do procedury zapisujacej

CzyZapisujaca:
    cmp     ax, 8h ;Analogicznie do wyzej
	jne     koniec
    call    FunkcjaZapisujaca
	
koniec:
	;Slowo statusu urzadzenia                                                                        ####### S³owo statusu
	;########################
	;W przypadku operacji wykonanej poprawnie ustawiany jest tylko bit DONE
    mov     ah, 00000001b ;bity 15 do 8
						;bit 8 - 1 - DONE - operacja zakonczona
    mov     al, 0 ;bity 7 do 0
    mov     es:[bx+3], ax ;do pakietu zlecenie
	;########################
	
	;odtworzenie rejestrow i rejedtru flagowego
    pop     ds
    pop     ax
    pop     bx
    pop     es
    popf
    ret

ProceduraWykonawcza  ENDP
;*******************************************



;*******************************************                                                         ####### Funkcja zapisu
;Funkcja zapisu
;08h

FunkcjaZapisujaca PROC NEAR
    push    bx
    push    es
    push    ax
    push    cx
    push    es

    mov     ax, es:[bx+10h]	;zapamietanie w nowym es (tymczasowo ax) segmentu adresu obszaru transmisji danych
    mov     bx, es:[bx+0eh] ;zapamietanie w nowym bx przesuniecia adresu obszaru transmisji danych
    mov     es, ax
	;pobieranie tylko 1 bajta na raz

    mov     al, es:[bx] ;pobierz znak z obszaru transmisji danych (1 bajt)

	;cmp	al, 12
	;je		powrot

    cmp     al, '@' ;sprawdzenie czy pobrany znak to @
    jne     InnyZnak ;jezeli nie to skaczemy do InnyZnak

	;jezeli jest @ to
    cmp     SterowanieON, 0 ;sprawdzamy czy SterowanieON == 0
						;SterowanieON mowi nam czy program jest na etapie rozpoznawania @- @+
    je      nowy_rozkaz ;jezeli nie SterowanieON to skaczemy do nowy rozkaz

    jmp     DrukujZnak ;DrukujZnakamy @ jezeli sa dwie pod rzad
	
nowy_rozkaz:
    mov     SterowanieON, 1 ;ustawia SterowanieON na 1
    jmp     powrot ;i skacze do powrot - zaczela sie sekwencja sterowania wielkoscia znakow

InnyZnak:
    cmp     al, '+'
    jne     InnyZnak2 ;jezeli znakiem nie jest + to skok do InnyZnak2
    cmp     SterowanieON, 0 ;jezeli jest to sprawdzamy czy zaczela sie sekwencja sterowania znakami czy jest to po prostu +
    je      DrukujZnak ;jezeli sam + to DrukujZnakamy
    mov     UpperCase, 1 ;jezeli nie sam to ustawiamy UpperCase na 1 sygnalizujac ze bedziemy pisac duzymi
    mov     SterowanieON, 0 ;i wychodzimy z sekwencji sterowania
    jmp     powrot ;powrot

InnyZnak2: ;analogicznie do InnyZnak
    cmp     al, '-'
    jne     InnyZnak3
    cmp     SterowanieON, 0
    je      DrukujZnak
    mov     UpperCase, 0
    mov     SterowanieON, 0
    jmp     powrot
	
InnyZnak3:
    cmp     UpperCase, 0 ;jezeli skewencja sterowania ustawila nam UpperCase na 1 to dokonujemy zamiany liter na duze
    je      dalej
    cmp     al, 'a'
    jb      dalej
    cmp     al, 'z'
    ja      dalej
    sub     al, 32 ;z malych na duze (wynika z ASCII)

dalej:
    cmp     SterowanieON, 1
    jne     DrukujZnak ;jezeli nie sekwencja sterujaca to DrukujZnak aktualny znak
    push    ax
    DrukujZnakCONlubPRN '@'
    mov     SterowanieON, 0
    pop     ax

DrukujZnak:
    DrukujZnakCONlubPRN

powrot:
	;odtworzenie rejestrow
    pop     es
    pop     cx
    pop     ax
    pop     es
    pop     bx
	ret

FunkcjaZapisujaca          ENDP
;*******************************************



;*******************************************                                                         ####### Funkcja inicjalizujaca
;Funkcja inicjalizujaca
;00h
Funkcjainicjalizujaca PROC NEAR
;tylko raz na poczatku wywolana, pozniej odcieta
	
	mov     WORD PTR es:[bx+0eh], OFFSET Funkcjainicjalizujaca ;offset funkcji 00h - zeby ja odciac
    mov     WORD PTR es:[bx+10h], cs ;segment w ktorym znajduje sie sterownik
	ret

Funkcjainicjalizujaca ENDP
;*******************************************

END Start