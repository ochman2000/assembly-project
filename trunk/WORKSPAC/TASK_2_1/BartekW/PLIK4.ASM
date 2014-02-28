                .MODEL TINY
Wyswietl MACRO znak
         mov   al,znak
         mov   ah, 0eh ;0eh parametr przerwania
         mov   bl, 0   ;0 parametr przerwania
         int   10h		; przerwanie
         ENDM

        .CODE
Start:
        dd      0FFFFh	;adres nastêpnego sterownika
        db      00h		;2 kolejne bajty w dól
        db      80h		;atrybuty sterownika u nas informacja o urz¹dzeniu znakowym (15 bit)
        dw      OFFSET szeregujaca		;adres proc szereg
        dw      OFFSET wykonawcza		;adres proc wykonwaczej 
        db      'DRUK    '				; 8 bajtowa nazwa sterownika

        ;zmienne dla funkji sterownika

Pakiet  dd      ?						;adres pakietu 	- miejsce w pamieci dla tego co jest przekazywane przez system w momencie wywolania urzadzenia. rezerwuje na 4 bajty
malpa   db      0						;zeby wiedzial czy poprzednim znakiem byla malpa	
duze    db      0						;zeby wiedzial jakie ma pisac litery 


szeregujaca PROC FAR						;
            mov  WORD PTR Pakiet, es		; do zmiennej pakiet przypisujemy najpierw rejestr zawierajacy starsza czesc adresu 
            mov  WORD PTR [Pakiet+2], bx	;do zmiennej pakiet przypisujemy rejestr zawierajacy mlodsza czesc adresu o 2 miejsca w bok co daje nam cala 4 bajtowa zmienna zapelniona
            ret								;
szeregujaca ENDP

wykonawcza PROC FAR
           pushf							
           push bx							
           push es							
           push ax							
           push ds							
           push cs							; zawartosc rejestru cs (adres segmentu kodu) odkladamy na stos 
           pop  ds							; adres segnentu kodu zdejmujemy ze stosu do rejestru danych 
           mov bx,WORD PTR Pakiet			; przenosimy tylko 2 bajtowa czesc do bx
           mov es,bx						;
           mov bx,WORD PTR [Pakiet+2]		;
           mov ax,es:[bx+2]					; do ax przenosimy to co pod adresem es:[bx+2] z przesunieciem o 2 bajty i pod tym adresem mamy info jaka funkcja sterownika ma zostac wywolana

czyInic:
           cmp  ax,0h						; porownujemy czy jest rowne 0 
           jne  czyZapis					;jezeli ax = 0 to ignorujemy skok a jezeli rozne to przechodzimy do czy zapis
           call Inicjalizacja				
czyZapis:
           cmp  ax,8h						;zprawdzamy czy ax = 8 (zapis)
           jne  Done						;jezeli tak to ignorujemy skok a jezeli nie to skaczemy do Done 
           call Zapisz						
Done:
           mov ah, 1h						;
           mov al, 0h						;
           mov es:[bx+3],ax					;ustawiony 8 bit slowa statusu urzadzenia czyli Done
           pop ds							
           pop ax	
           pop es
           pop bx
           popf								;
           ret
wykonawcza ENDP

Zapisz     PROC
             push es						
             push bx						
             push ax						
             mov  ax, es:[bx+10h]		; pobieramy adres obszaru transmisji danych 
             mov  bx, es:[bx+0eh]		;	
             mov  es, ax				

             mov  al, es:[bx]			; pobieramy znak spod adresu
             cmp  al, '@'				;sprawdzamy czy znak jest @
             jne  plus					;jezeli nie to przechodzimy do plus
             cmp malpa,0				;jezeli jest to sprawdzamy czy malpa byla 0
             jne wypisz					;jezeli nie to do wypisz
             mov malpa,1				;jezeli tak to przypisujemy malpie 1
             jmp koniec						

plus:
             cmp al, '+'				; sprawdzamy czy znak jest plusem
             jne minus					;jezeli nie to skaczemy 
             cmp malpa, 1				;jezeli tak to sprawdzamy czy malpa jest 1 
             jne wypisz					;jezeli nie to skaczemy do wypisz
             mov duze, 1				;jezeli tak to ustawiamy duze litery na 1
             mov malpa, 0				;i zerujemy malpe 
             jmp koniec					;
minus:
             cmp al, '-'				; sprawdzamy czy znak jest - 
             jne innyZnak				;jezeli nie to skaczemu do innyznak
             cmp malpa, 1				;jezeli tak to sprawdzamy czy malpa jest 1
             jne wypisz					;jezeli nie to skaczemy do wypisz
             mov duze,0					;jezeli tak to duze litery ustawiamy na 0
             mov malpa,0				;zerujemy malpe 
             jmp koniec					;
innyZnak:
             cmp duze, 1				;sprawdzamy czy maja byc duze litery
             jne omin					;jezeli nie to skaczemu do omin
             cmp al, 'z'				;
             ja  omin					;
             cmp al, 'a'				;4 lin - sprawdzamy czy znak jest z przedzialu od a do z
             jb  omin					;jezeli nie to skaczemy do omin
             sub al, 32					;jezeli jest to dodajemy 32 zeby zmienic mala na duza bo taka jest roznica w ASCII
omin:
             cmp malpa, 1				;sprawdzamy czy malpa jest 1 
             jne wypisz					;jezeli nie to idziemy do wypisz 
             push ax					;odkladamy ax
             mov malpa,0				;zerujemy malpe
             Wyswietl   '@'				;wywolujemy makro wysweitl i wyswietlamy malpe 
             pop  ax					;zdejmujemy ax
wypisz:
             Wyswietl al				;wypisujemy znak
koniec:									
             pop ax						
             pop bx						;koniec proc zapisu
             pop es
             ret
Zapisz       ENDP

Inicjalizacja PROC						
              push dx					
              push ax					

              mov dx, OFFSET text		;wyswietlanie napisu 
              mov ah,09h
              int 21h
              mov WORD PTR es:[bx+0Eh], OFFSET Inicjalizacja   ; informujemy system gdzie obciac program
              mov WORD PTR es:[bx+10h], cs
              pop ax
              pop dx
              ret
Inicjalizacja ENDP

text    db      "wgrano sterownik drukarki",13,10,"$"
              END Start