# Zestaw funkcji do operacji na duzych liczbach (tj. wiekszych niz 2^32)
# - Nie ma zaimplementowanego dynamicznego przydzielania pamieci, dlatego do niektorych
#   funkcji jako argument nalezy podac dodatkowy bufor o rozmiarze takim samym jak
#   bufor przeznaczony na wynik. Wartosci wpisane do tego bufora nie beda mialy zadnego
#   konkretnego znaczenia jezeli chodzi o wynik dzialania funkcji jednak sa niezbedne
#   do przechowywania danych.
# - Opisy zmiennych lokalnych, argumentow i dodatkowe komentarze 
#   do funkcji znajduja sie bezposrednio nad funkcjami.
# - Niektore argumenty zostaly oznaczone tez jako zmienne lokalne - znaczy to ze 
#   po uzyciu ich w pewnym miejscu nie sa juz potrzebne i zostaja one uzyte wlasnie jako 
#   zmienne lokalne.
# - "Dlugosc" do ktorej odniesienia znajduja sie w komentarzach to 
#   ilosc_zaalokowanych_bajtow / dlugosc_pojedynczego_slowa, (czyli ilosc miejsc w tablicy, 
#   czyli tlumaczac na C : int tablica[dlugosc]; )

.text
# big_strtonum  - przerabia ciag znakow na duza liczbe
# Argumenty:
# 8(%ebp)	- ciag znakow
# 12(%ebp)	- bufor na liczbe
# 16(%ebp)	- dlugosc bufora (w slowach)
# 20(%ebp)	- drugi bufor na liczbe, musi miec taka sama dlugosc jak pierwszy
# 24(%ebp)	- podstawa liczby
# Zmienne lokalne:
# -4(%ebp)	- przechowuje aktualny znak
# -8(%ebp)	- adres na -4(%ebp)
# -12(%ebp)	- adres na podstawe
# -16(%ebp)     - ilosc slow znajdujaca sie w buforze
# 16(%ebp)	= 16(%ebp)+1
# Wartosc zwracana:
# eax = -16(%ebp)	- sukces
# eax = -1		- porazka
.globl big_strtonum
.type big_strtonum,@function
big_strtonum:
  pushl %ebp
  movl %esp, %ebp
  subl $16, %esp

  # zerujemy bufor na liczbe
  pushl $0
  pushl 16(%ebp)
  pushl 12(%ebp)
  call big_set
  addl $12, %esp

  # sprawdzamy czy pierwszy znak nie jest czasem mniejszy od spacji
  movl 8(%ebp), %esi
  cmpb $0x20, (%esi)
    jbe big_strtonum_end

  # inicjalizacja zmiennych lokalnych
  movl $0, -4(%ebp)
  movl %ebp, -8(%ebp)
  subl $4, -8(%ebp)	
  movl %ebp, -12(%ebp)
  addl $24, -12(%ebp)
  movl $1, -16(%ebp)
  incl 16(%ebp)
  
  xorl %eax, %eax
big_strtonum_loop:
  # przepisujemy aktualny znak do al, odejmujemy 0x30
  movb (%esi), %al
  subb $0x30, %al
  
  # sprawdzamy czy liczba miesci sie w przedziale 0 - (podstawa-1)
  cmpb $0, %al
    jl big_strtonum_fail
  cmpb 24(%ebp), %al
    jb big_strtonum_loop_continue
    
  # jezeli nie, sprawdzamy czy podstawa jest mniejsza od 10
  cmpb $10, 24(%ebp)
    jb big_strtonum_fail

  # jezeli nie, zamieniamy potencjalna litere na mala, odejmujemy 0x27
  # i sprawdzamy czy wynik znajduje sie w zakresie 0 - (podstawa-1)
  orb $0b00100000, %al
  subb $0x27, %al
  cmpb $0, %al
    jl big_strtonum_fail
  cmpb 24(%ebp), %al
    jae big_strtonum_fail
    
big_strtonum_loop_continue:
  # zachowujemy wartosc cyfry w zmiennej lokalnej oraz wskaznik na element docelowy na stosie
  movb %al, -4(%ebp)
  pushl %esi

  # dodajemy wartosc cyfry do zawartosci bufora na liczbe 
  pushl 16(%ebp)
  pushl 12(%ebp)
  pushl $1
  pushl -8(%ebp)
  pushl -16(%ebp)
  pushl 12(%ebp)
  call big_add
  addl $24, %esp
  
  # sprawdzamy czy bufor na wynik sie nie skonczyl
  cmpl $-1, %eax
    je big_strtonum_fail
  movl %eax, -16(%ebp)

  # przywracamy adres na bufor ze stosu, sprawdzamy czy nastepny znak nie jest mniejszy od spacji
  popl %esi
  movb 1(%esi), %al
  cmpb $0x20, %al
    jbe big_strtonum_end

  pushl %esi

  # mnozymy wartosc w buforze przez podstawe systemu i zapisujemy w buforze pomocniczym
  pushl 16(%ebp)
  pushl 20(%ebp)
  pushl $1
  pushl -12(%ebp)
  pushl -16(%ebp)
  pushl 12(%ebp)
  call big_mull
  addl $24, %esp
  
  # ponownie sprawdzamy czy nie skonczylo sie miejsce na wynik
  cmpl $-1, %eax
    je big_strtonum_fail  
  movl %eax, -16(%ebp)
  
  # przepisujemy bufor pomocniczy do wynikowego
  pushl 12(%ebp)
  pushl -16(%ebp)
  pushl 20(%ebp)
  call big_mov
  addl $12, %esp
  
  popl %esi
  incl %esi # zwiekszamy adres
  jmp big_strtonum_loop
big_strtonum_fail:
  movl $-1, -16(%ebp)
big_strtonum_end:
  movl -16(%ebp), %eax  
  movl %ebp, %esp
  popl %ebp
  ret
    
# big_numtostr	- przerabia duza liczbe na ciag znakow
# Argumenty:
# 8(%ebp)	- tablica zawierajace 4-bajtowe slowa
# 12(%ebp)	- ilosc slow (dlugosc)
# 16(%ebp)	- bufor na znaki
# 20(%ebp)	- dlugosc bufora
# 24(%ebp)	- podstawa liczby
# Zmienne lokalne:
# -4(%ebp)	- reszta z wyniku
# -8(%ebp)	- adres do reszty
# -12(%ebp)	- ile mamy cyfr
# Wartosc zwracana:
# eax = -1	- blad
# eax = ilosc znakow+2 - sukces
.globl big_numtostr
.type big_numtostr,@function
big_numtostr:
  pushl %ebp
  movl %esp, %ebp
  subl $12, %esp

  movl %ebp, -8(%ebp)
  subl $4, -8(%ebp)
  movl $0, -12(%ebp)
  
big_numtostr_loop:
  # dzielimy liczbe znajdujaca sie pod adresem w 8(%ebp) przez podstawe
  # w -4(%ebp) mamy reszty
  pushl -8(%ebp)
  pushl 12(%ebp)
  pushl 8(%ebp)
  pushl 24(%ebp)
  pushl 12(%ebp)
  pushl 8(%ebp)
  call big_div2
  addl $24, %esp

  incl -12(%ebp)	# zwiekszamy licznik cyfr
  movl %eax, 12(%ebp)   # przepisujemy nowa dlugosc liczby (po podzieleniu) do zmiennej
  pushl -4(%ebp)	# wyrzucamy reszte na stos
  
  cmpl $0, %eax		# sprawdzamy czy dlugosc wyniku to zero
    ja big_numtostr_loop	# jesli nie - kontynuuj petle

  movl -12(%ebp), %ecx	# przepisz licznik cyfr do ecx
  addl $2, %ecx		# dodaj dwa do ecx
  cmpl 20(%ebp), %ecx	# sprawdz czy nie przekroczylismy rozmiaru bufora wyjsciowego
    ja big_numtostr_failure
  # teraz przygotujemy bufor wyjsciowy dopisujac "\n\0" na koniec
  movl 16(%ebp), %edi
  leal -1(%edi,%ecx,1), %edi
  movb $0, (%edi)
  decl %edi
  movb $0xa, (%edi)
  movl 16(%ebp), %edi
  subl $2, %ecx  
big_numtostr_loop2:
  popl %eax
  # dodajemy 0x30 do al tak aby otrzymac cyfre ascii
  addb $0x30, %al

  # jezeli wyszlo wiecej niz '9' dodamy jeszcze 0x27 otrzymujac litere
  cmpb $0x39, %al
    jbe big_numtostr_loop2_mov
  addb $0x27, %al
big_numtostr_loop2_mov:  
  # przepisujemy cyfre pod adres, zmniejszamy licznik, zwiekszamy adres
  movb %al, (%edi)
  incl %edi
  decl %ecx
  # licznik rozny od zera - kontynuuj petle
  cmpl $0, %ecx
    jne big_numtostr_loop2
  movl -12(%ebp), %eax # przepisz dlugosc wyniku do eax
  addl $2, %eax		# dodaj 2 (poniewaz powiekszylismy ciag o "\n\0")
  jmp big_numtostr_end
big_numtostr_failure:
  movl $-1, %eax
big_numtostr_end:
  movl %ebp, %esp
  popl %ebp
  ret

# big_div2 	- dzieli duze liczby (dzielna dowolna, dzielnik mniejszy niz 2^32)
# Argumenty:
# 8(%ebp)	- tablica zawierajace 4-bajtowe slowa bedace dzielna
# 12(%ebp)	- ilosc miejsc zajetych w tablicy przez dzielna (dlugosc)
# 16(%ebp)	- dzielnik
# 20(%ebp)	- tablica na wynik
# 24(%ebp)	- dlugosc tablicy na wynik
# 28(%ebp)	- adres do zmiennej w ktorej zapiszemy reszte
# Wartosci zwracane:
# eax = -1	- wystapil blad
# eax = 0	- iloraz rowny zero
# eax = (12(%ebp)) lub eax = (12(%ebp))-1	- dlugosc wyniku
# Zmienne lokalne:
# 12(%ebp)	- wartosc zwracana (dlugosc wyniku)
.globl big_div2
.type big_div2,@function
big_div2:
  pushl %ebp
  movl %esp, %ebp

  # porownujemy dlugosc dzielnej z dlugoscia bufora wyniku
  # jesli to ostatnie jest mniejsze - zwracamy blad
  movl 12(%ebp), %eax
  cmpl 24(%ebp), %eax
    ja big_div2_failure

  # sprawdzamy cze dzielnik jest rowny zero
  # jesli tak - zwracamy blad
  cmpl $0, 16(%ebp)
    je big_div2_failure
    
  movl 8(%ebp), %esi		# przepisz adres do dzielnej do esi
  movl 20(%ebp), %edi		# przepisz adres do wyniku do edi
  movl 12(%ebp), %ecx		# przepisz dlugosc dzielnej do ecx
  leal -4(%esi,%ecx,4), %esi	# ustaw adres dzielnej na najwyzsze slowo
  leal -4(%edi,%ecx,4), %edi	# ustaw adres wyniku zgodnie z adresem wyzej
  movl (%esi), %eax		# przepisz najwyzsze slowo do eax
  movl 16(%ebp), %ebx
  xorl %edx, %edx		# wyzeruj edx
  cmpl 16(%ebp), %eax		# porownaj dzielnik z najwyzszym slowem dzielnej
    jae big_div2_firstnotzero	# jesli slowo jest wieksze od dzielnika wykonaj skok
  decl 12(%ebp)			# jesli nie, zmniejsz dlugosc wyniku o 1 (bo i tak pojawi sie zero)
big_div2_firstnotzero:
  # wykonujemy dzielenie    
  movl (%esi), %eax
  divl %ebx
  decl %ecx
  movl %eax, (%edi)
  cmpl $0, %ecx
    je big_div2_endloop
  subl $4, %esi
  subl $4, %edi
  jmp big_div2_firstnotzero
big_div2_endloop:
  movl 28(%ebp), %edi
  movl %edx, (%edi)
  movl 12(%ebp), %eax
  jmp big_div2_end
big_div2_failure:
  movl $-1, %eax
big_div2_end:
  movl %ebp, %esp
  popl %ebp
  ret

# big_div	- dzieli duze liczby (zarowno dzielna jak i dzielnik moga byc rowne/wieksze od 2^32)
# Argumenty:
# 8(%ebp)	- tablica zawierajace 4-bajtowe slowa bedace dzielna
# 12(%ebp)	- ilosc miejsc zajetych w tablicy przez dzielna (dlugosc)
# 16(%ebp)	- tablica zawierajaca dzielnik
# 20(%ebp)	- dlugosc dzielnika
# 24(%ebp)	- tablica zawierajaca wynik
# 28(%ebp)	- dlugosc tablicy na wynik
# 32(%ebp)	- tablica zawierajaca reszte
# 36(%ebp)	- dlugosc tablicy na reszte
# Wartosci zwracane:
# eax = -1 	- wystapil blad
# eax = 0	- wszystko w porzadku
# Zmienne lokalne:
# -4(%ebp)	- miejsce w ktorym przechowujemy jedynke
# -8(%ebp)	- tu jest przechowywany adres na %ebp-4
# Komentarze:
#   - przy duzej roznicy miedzy dzielnikiem a dzielna funkcja bedzie
#     obliczac wynik do konca swiata i o jeden dzien dluzej...
.globl big_div
.type big_div,@function
big_div:
  pushl %ebp
  movl %esp, %ebp
  subl $8, %esp
  movl $0, -4(%ebp)
  movl %ebp, -8(%ebp)
  subl $4, -8(%ebp)

  # porownujemy zero z dzielnikiem
  pushl $1
  pushl -8(%ebp)
  pushl 20(%ebp)
  pushl 16(%ebp)
  call big_compare
  addl $16, %esp
  
  cmpl $0, %eax
    je big_div_failure
    
  movl $1, -4(%ebp)
  # porownujemy dlugosc dzielnej z dlugosciami bufora wyniku i reszty
  # jesli te ostatnie sa mniejsze - zwracamy blad
  movl 12(%ebp), %eax
  cmpl 28(%ebp), %eax
    ja big_div_failure
  cmpl 36(%ebp), %eax
    ja big_div_failure
 
  # zerujemy tablice przeznaczona na wynik
  pushl $0
  pushl 28(%ebp)
  pushl 24(%ebp)
  call big_set
  addl $12, %esp
  
  # przepisujemy dzielna do tablicy przeznaczonej na reszte
  pushl 32(%ebp)
  pushl 12(%ebp)
  pushl 8(%ebp)
  call big_mov
  addl $12, %esp
  
big_div_loop:
  pushl 20(%ebp)
  pushl 16(%ebp)
  pushl 12(%ebp)
  pushl 32(%ebp)
  call big_compare
  addl $16, %esp
  
  cmpl $-1, %eax
    je big_div_end

  pushl 36(%ebp)
  pushl 32(%ebp)
  pushl 20(%ebp)
  pushl 16(%ebp)
  pushl 12(%ebp)
  pushl 32(%ebp)
  call big_sub
  addl $24, %esp
  
  pushl 28(%ebp)
  pushl 24(%ebp)
  pushl $1
  pushl -8(%ebp)
  pushl 28(%ebp)
  pushl 24(%ebp)
  call big_add
  addl $24, %esp
  jmp big_div_loop
big_div_failure:
  movl $-1, %eax  
  movl %ebp, %esp
  popl %ebp
  ret
big_div_end:
  xorl %eax, %eax
  movl %ebp, %esp
  popl %ebp
  ret
# big_mull	- mnozy duze liczby
# Argumenty:
# 8(%ebp)	- tablica zawierajace 4-bajtowe slowa bedace pierwsza liczba
# 12(%ebp)	- ilosc miejsc zajetych w tablicy przez pierwsza liczbe (dlugosc)
# 16(%ebp)	- tablica zawierajaca druga liczbe
# 20(%ebp)	- dlugosc drugiej liczby
# 24(%ebp)	- tablica zawierajaca wynik
# 28(%ebp)	- dlugosc tablicy na wynik
# Zmienne lokalne:
# 8(%ebp)	- adres do dluzszej liczby
# 12(%ebp)	- zawiera dlugosc dluzszej liczby
# 20(%ebp)	- zawiera dlugosc krotszej liczby
# 28(%ebp)	- zawiera dlugosc wyniku
# -4(%ebp)	- zawiera wartosc przepelnienia
# -8(%ebp)	- zawiera index drugiego czynnika
# Wartosci zwracane:
# eax = dlugosc wyniku	- sukces
# eax = -1		- zabraklo miejsca w buforze wyjsciowym
# Komentarze:
#   - poniewaz konieczne jest wyzerowanie bufora przeznaczonego na wynik,
#     bufor musi byc rozny od obu liczb (tj. nie mozna podac liczba1 = liczba1 * liczba2)
.globl big_mull
.type big_mull,@function
big_mull:
  pushl %ebp
  movl %esp, %ebp
  subl $8, %esp
  movl $0, -4(%ebp)

# jeszcze nalezaloby sprawdzic czy wynik zmiesci sie w tablicy
# maksymalna dlugosc wyniku to dlugosc pierwszego czynnika plus dlugosc drugiego czynnika
  movl 12(%ebp), %eax
  addl 20(%ebp), %eax
  cmpl 28(%ebp), %eax		# porownujemy teraz miejsce dostepne z potrzebnym
    ja big_mull_failure
  movl %eax, 28(%ebp)		# przepisujemy miejsce potrzebne do zmiennej lokalnej

  movl 24(%ebp), %ebx
big_mull_zeroresult:		# zerujemy tablice z wynikiem
  movl $0, (%ebx)
  addl $4, %ebx
  decl %eax
  cmpl $0, %eax
    ja big_mull_zeroresult
  
  movl 12(%ebp), %ecx		# dlugosc pierwszej liczby do ecx
  cmpl 20(%ebp), %ecx		# porownujemy z dlugoscia 2-giej liczby
    jae big_mull_first_bigger	# jesli pierwsza liczba wieksza, skok
  movl 20(%ebp), %ecx		# jesli nie - przepisz dlugosc drugiej do ecx
  movl 12(%ebp), %eax		# przepisz dlugosc pierwszej (krotszej) do eax 
  movl %ecx, 12(%ebp)		# wpisujemy dlugosc dluzszej liczby do zmiennej lokalnej  
  movl %eax, 20(%ebp)		# przepisz dlugosc krotszej liczby do zmiennej lokalnej
  movl 16(%ebp), %esi		# adres dluzszej liczby (2-giej) do esi
  movl 8(%ebp), %edi  		# adres krotszej liczby (1-szej) do edi
  movl %esi, 8(%ebp)		# przepisz adres do dluzszej liczby do zmiennej lokalnej
  jmp big_mull_second_bigger
big_mull_first_bigger:
  movl 8(%ebp), %esi		# adres dluzszej liczby (1-szej) do esi
  movl 16(%ebp), %edi		# adres krotszej liczby (2-giej) do edi
big_mull_second_bigger:
  movl 24(%ebp), %ebx		# adres wyniku do ebx
  movl $0, -8(%ebp)		# ustaw index drugiego czynnika na zero
  xorl %ecx, %ecx		# zeruj ecx
big_mull_loop:
  movl (%esi), %eax		# przepisz wartosc pod (%esi) do eax
  mull (%edi)			# pomnoz eax przez (%edi), wartosc zwroc do edi:eax
  addl -4(%ebp), %eax		# dodaj ewentualne przepelnienie do eax
    jnc big_mull_noaddoverflow	# jesli nie wystapilo przepelnienie po dodaniu kontynuuj
  incl %edx			# jesli tak, dodaj jeszcze 1 do edx
big_mull_noaddoverflow:
  movl %edx, -4(%ebp)		# przepisz edx do zmiennej lokalnej przechowujacej przepelnienie
  addl %eax, (%ebx)		# dodaj eax do miejsca wyniku
    jnc big_mull_noaddoverflow2
  pushl %ebx
big_mull_fixresultov:
  addl $4, %ebx
  addl $1, (%ebx)
    jc big_mull_fixresultov
  popl %ebx
big_mull_noaddoverflow2:
  incl %ecx			# zwieksz licznik dla dluzszego czynnika
  cmpl 12(%ebp), %ecx		# porownaj dlugosc dluzszej liczby z licznikiem
    je big_mull_incindex	
  addl $4, %esi			# zwieksz adres do dluzszej liczby
  addl $4, %ebx			# zwieksz adres wyniku
  jmp big_mull_loop		# powroc na poczatek petli
big_mull_incindex:		# koniec dluzszego czynnika
  cmpl $0, -4(%ebp)		# jesli przepelnienie rowne zero
    je big_mull_incindex2
  addl $4, %ebx			# zwieksz adres wyniku
  movl -4(%ebp), %eax		# przepisz przepelnienie do eax
  movl $0, -4(%ebp)		# zeruj przepelnienie
  addl %eax, (%ebx)		# dodaj eax do wyniku
big_mull_incindex2:
  incl -8(%ebp)			# zwieksz licznik dla krotszego czynnika
  movl -8(%ebp), %eax		# przepisz licznik do eax
  cmpl 20(%ebp), %eax		# porownaj dlugosc krotszego czynnika z jego licznikiem
    je big_mull_end
  xorl %ecx, %ecx		# zeruj index dluzszej liczby
  movl 8(%ebp), %esi		# przepisz adres dluzszczego czynnika spowrotem do esi
  addl $4, %edi			# zwieksz adres do krotszego czynnika
  movl 24(%ebp), %ebx		# przepisz adres wyniku do ebx
  leal (%ebx,%eax,4), %ebx	# oblicz nowy adres wyniku
  jmp big_mull_loop
big_mull_end:
  movl 28(%ebp), %eax		# przepisujemy potrzebne miejsce do eax (wartosc zwracana)
  movl 24(%ebp), %esi
  leal -4(%esi,%eax,4), %esi
  cmpl $0, (%esi)
    jne big_mull_really_end
  decl %eax
  jmp big_mull_really_end	# koniec
big_mull_failure:
  movl $-1, %eax
big_mull_really_end:
  movl %ebp, %esp
  popl %ebp
  ret


# big_sub	- odejmuje duze liczby
# Argumenty:
# 8(%ebp)	- tablica zawierajace 4-bajtowe slowa bedace pierwsza liczba
# 12(%ebp)	- ilosc miejsc zajetych w tablicy przez pierwsza liczbe (dlugosc)
# 16(%ebp)	- tablica zawierajaca druga liczbe
# 20(%ebp)	- dlugosc drugiej liczby
# 24(%ebp)	- tablica zawierajaca wynik
# 28(%ebp)	- dlugosc tablicy na wynik
# Zmienne lokalne:
# 12(%ebp)	- zawiera dlugosc dluzszej liczby
# 20(%ebp)	- zawiera dlugosc krotszej liczby
# -4(%ebp)	- zawiera wartosc przepelnienia
# Wartosci zwracane:
# eax = dlugosc wyniku	- sukces
# eax = -1		- zabraklo miejsca na wynik
# Komentarze:
# - funkcja powinna rownie dobrze dzialac na liczbach
#   calkowitych jak i na naturalnych
#   jezeli chodzi o te pierwsze - dla przykladu:
#   liczba1 = -1, -1, -2
#   liczba2 = -2, -2, -1
#   (przyklad mozna uproscic jezeli przyjac, ze -1 = 9, -2 = 8, wtedy:
#   liczba1 = 899, liczba2 = 988)
#   liczba1 - liczba2 = -89, funkcja natomiast zwroci wynik:
#   wynik = 1, 1, -1, gdyby wynik uproscic tak samo jak liczby powyzej:
#   wynik = 911, a 1000 - 911 = 89.
#   przenoszac to teraz na liczby 32-bitowe okazuje sie, ze otrzymujemy
#   poprawne wyniki dla liczb calkowitych
.globl big_sub
.type big_sub,@function
big_sub:
  pushl %ebp
  movl %esp, %ebp
  subl $4, %esp
  movl $0, -4(%ebp)
  
  movl 12(%ebp), %ecx		# dlugosc pierwszej liczby do ecx
  cmpl 20(%ebp), %ecx		# porownujemy z dlugoscia 2-giej liczby
    jae big_sub_first_bigger	# jesli pierwsza liczba wieksza, skok
  movl 20(%ebp), %ecx		# jesli nie - przepisz dlugosc drugiej do ecx
  movl 12(%ebp), %eax		# przepisz dlugosc pierwszej (krotszej) do eax 
  movl %ecx, 12(%ebp)		# wpisujemy dlugosc dluzszej liczby do zmiennej lokalnej  
  movl %eax, 20(%ebp)		# przepisz dlugosc krotszej liczby do zmiennej lokalnej
  movl 16(%ebp), %esi		# adres dluzszej liczby (2-giej) do esi
  movl 8(%ebp), %edi  		# adres krotszej liczby (1-szej) do edi
  jmp big_sub_second_bigger
big_sub_first_bigger:
  movl 8(%ebp), %esi		# adres dluzszej liczby (1-szej) do esi
  movl 16(%ebp), %edi		# adres krotszej liczby (2-giej) do edi
big_sub_second_bigger:
  movl 24(%ebp), %edx		# adres wyniku do edx
  movl %ecx, 12(%ebp)		# wpisujemy dlugosc dluzszej liczby do zmiennej lokalnej
  xorl %ecx, %ecx		# zeruj ecx
big_sub_loop:
  xorl %ebx, %ebx		# wyzeruj ebx (trzyma flage "czy wystapilo przepelnienie")
  movl (%esi), %eax		# przepisz element tablicy dluzszej liczby do eax
  cmpl 20(%ebp), %ecx		# porownaj indeks z dlugoscia krotszej liczby
    jae big_sub_second_number_end	# jesli okazalo sie, ze druga liczba sie skonczyla
  subl (%edi), %eax		# dodaj element krotszej
    jnc big_sub_second_number_end	# sprawdz czy jest ustawiona flaga carry
  movl $1, %ebx			# ustaw flage na 'true'
big_sub_second_number_end:
  subl -4(%ebp), %eax		# dodaj ewentualne przepelnienie (moze byc zero, moze byc jeden)
    jc big_sub_calc_overflow	# jesli wystapilo przepelnienie
  cmpl $1, %ebx			# sprawdz czy jest ustawiona flaga przepelnienia
    je big_sub_calc_overflow	# ustaw przepelenienie
  movl $0, -4(%ebp)		# jesli nie, przepelnienie = 0
  jmp big_sub_nocalc_overflow
big_sub_calc_overflow:
  movl $1, -4(%ebp)  		# przepelenienie = 1
big_sub_nocalc_overflow:
  movl %eax, (%edx)		# wpisz wynik do buforu
  incl %ecx			# zwieksz licznik
  cmpl 12(%ebp), %ecx		# porownaj licznik z dlugoscia dluzszej liczby
    jae big_sub_end		# wiekszy/rowny - koniec funkcji
  cmpl 28(%ebp), %ecx		# porownaj licznik z dlugoscia bufora wyniku
    jae big_sub_failure		# jesli wiekszy/rowny - zwroc blad
  addl $4, %esi			# zwieksz adresy
  addl $4, %edx
  cmpl 20(%ebp), %ecx		# porownaj index z dlugoscia mniejszej liczby
    jae big_sub_loop		# jesli index jest wiekszy/rowny nie zwiekszaj juz adresu mniejszej liczby
  addl $4, %edi  
  jmp big_sub_loop
big_sub_end:
  movl %ecx, %eax	# przepisujemy index do eax (wartosc zwracana)
  jmp big_sub_really_end	# koniec
big_sub_failure:
  movl $-1, %eax
big_sub_really_end:
  movl %ebp, %esp
  popl %ebp
  ret
  
# big_add	- dodaje duze liczby
# Argumenty:
# 8(%ebp)	- tablica zawierajace 4-bajtowe slowa bedace pierwsza liczba
# 12(%ebp)	- ilosc miejsc zajetych w tablicy przez pierwsza liczbe (dlugosc)
# 16(%ebp)	- tablica zawierajaca druga liczbe
# 20(%ebp)	- dlugosc drugiej liczby
# 24(%ebp)	- tablica zawierajaca wynik
# 28(%ebp)	- dlugosc tablicy na wynik
# Zmienne lokalne:
# 12(%ebp)	- zawiera dlugosc dluzszej liczby
# 20(%ebp)	- zawiera dlugosc krotszej liczby
# -4(%ebp)	- zawiera wartosc przepelnienia
# Wartosci zwracane:
# eax = dlugosc wyniku	- sukces
# eax = -1		- zabraklo miejsca w buforze wyjsciowym
.globl big_add
.type big_add,@function
big_add:
  pushl %ebp
  movl %esp, %ebp
  subl $4, %esp
  movl $0, -4(%ebp)
  
  movl 12(%ebp), %ecx		# dlugosc pierwszej liczby do ecx
  cmpl 20(%ebp), %ecx		# porownujemy z dlugoscia 2-giej liczby
    jae big_add_first_bigger	# jesli pierwsza liczba wieksza, skok
  movl 20(%ebp), %ecx		# jesli nie - przepisz dlugosc drugiej do ecx
  movl 12(%ebp), %eax		# przepisz dlugosc pierwszej (krotszej) do eax 
  movl %ecx, 12(%ebp)		# wpisujemy dlugosc dluzszej liczby do zmiennej lokalnej  
  movl %eax, 20(%ebp)		# przepisz dlugosc krotszej liczby do zmiennej lokalnej
  movl 16(%ebp), %esi		# adres dluzszej liczby (2-giej) do esi
  movl 8(%ebp), %edi  		# adres krotszej liczby (1-szej) do edi
  jmp big_add_second_bigger
big_add_first_bigger:
  movl 8(%ebp), %esi		# adres dluzszej liczby (1-szej) do esi
  movl 16(%ebp), %edi		# adres krotszej liczby (2-giej) do edi
big_add_second_bigger:
  movl 24(%ebp), %edx		# adres wyniku do edx
  movl %ecx, 12(%ebp)		# wpisujemy dlugosc dluzszej liczby do zmiennej lokalnej
  xorl %ecx, %ecx		# zeruj ecx
big_add_loop:
  xorl %ebx, %ebx		# wyzeruj ebx (trzyma flage "czy wystapilo przepelnienie")
  movl (%esi), %eax		# przepisz element tablicy dluzszej liczby do eax
  cmpl 20(%ebp), %ecx		# porownaj indeks z dlugoscia krotszej liczby
    jae big_add_second_number_end	# jesli okazalo sie, ze druga liczba sie skonczyla
  addl (%edi), %eax		# dodaj element krotszej
    jnc big_add_second_number_end	# sprawdz czy jest ustawiona flaga carry
  movl $1, %ebx			# ustaw flage na 'true'
big_add_second_number_end:
  addl -4(%ebp), %eax		# dodaj ewentualne przepelnienie (moze byc zero, moze byc jeden)
    jc big_add_calc_overflow	# jesli wystapilo przepelnienie
  cmpl $1, %ebx			# sprawdz czy jest ustawiona flaga przepelnienia
    je big_add_calc_overflow	# ustaw przepelenienie
  movl $0, -4(%ebp)		# jesli nie, przepelnienie = 0
  jmp big_add_nocalc_overflow
big_add_calc_overflow:
  movl $1, -4(%ebp)  		# przepelenienie = 1
big_add_nocalc_overflow:
  movl %eax, (%edx)		# wpisz wynik do buforu
  incl %ecx			# zwieksz licznik
  cmpl 12(%ebp), %ecx		# porownaj licznik z dlugoscia dluzszej liczby
    jae big_add_end		# wiekszy/rowny - koniec funkcji
  cmpl 28(%ebp), %ecx		# porownaj licznik z dlugoscia bufora wyniku
    jae big_add_failure		# jesli wiekszy/rowny - zwroc blad
  addl $4, %esi			# zwieksz adresy
  addl $4, %edx
  cmpl 20(%ebp), %ecx		# porownaj index z dlugoscia mniejszej liczby
    jae big_add_loop		# jesli index jest wiekszy/rowny nie zwiekszaj juz adresu mniejszej liczby
  addl $4, %edi  
  jmp big_add_loop
big_add_end:
  movl -4(%ebp), %ebx   # przepisujemy ostatnie przepelnienie do ebx
  movl %ecx, %eax	# przepisujemy index do eax (wartosc zwracana)
  cmpl $0, %ebx		# sprawdzamy czy ebx == 0
    je big_add_really_end	# jesli tak - koniec
  cmpl 28(%ebp), %ecx	# porownujemy dlugosc bufora z indexem
    jae big_add_failure	# jesli wiekszy rowny - zabraklo miejsca na ostatnie przepelnienie
  addl $4, %edx		# zwiekszamy adres bufora
  incl %eax		# zwiekszamy wartosc zwracana (dlugosc wyniku)
  movl %ebx, (%edx)	# przepisujemy przepelnienie
  jmp big_add_really_end	# koniec
big_add_failure:
  movl $-1, %eax
big_add_really_end:
  movl %ebp, %esp
  popl %ebp
  ret

# big_compare 	- Porownuje duze liczby
# Argumenty:
# 8(%ebp)  	- tablica zawierajace 4-bajtowe slowa bedace pierwsza liczba
# 12(%ebp) 	- ilosc miejsc zajetych w tablicy przez pierwsza liczbe  (dlugosc)
# 16(%ebp) 	- tablica zawierajaca druga liczbe
# 20(%ebp)	- dlugosc drugiej liczby
# Wartosci zwracane:
# eax = 1 	- liczba pierwsza wieksza
# eax = 0	- liczby rowne
# eax = -1	- liczba druga wieksza
# Komentarze:
# - teoretycznie jezeli jedna liczba jest "dluzsza" od drugiej
#   to powinna byc tez od niej wieksza, w praktyce jednak
#   mozna podac liczbe, ktora z przodu ma same zera
#   np.
#   (8(%ebp))  = 10,20,0,0
#   12(%ebp)   = 4
#   (16(%ebp)) = 10,30
#   20(%ebp)   = 2
#   jak widac w tym przypadku liczba druga jest wieksza chociaz jest "krotsza"
.globl big_compare
.type big_compare,@function
big_compare:
  pushl %ebp
  movl %esp, %ebp
  
  movl 12(%ebp), %eax		# dlugosc pierwszej liczby do eax
  # porownujemy dlugosci liczb
  cmpl 20(%ebp), %eax
    ja big_compare_longer_1
    jb big_compare_longer_2
    je big_compare_cmp
  
big_compare_longer_1:
    movl 8(%ebp), %esi		# adres do tablicy do esi
    leal -4(%esi,%eax,4), %esi	# przeliczamy adres (esi + 4*eax wskazuje na miejsce tuz za tablica wiec odejmujemy 4)
  big_compare_longer_loop_1:
    movl (%esi), %ebx		# zawartosc pod adr. esi do ebx
    cmpl $0, %ebx		# sprawdzamy czy ebx != 0
      jne big_compare_bigger_1	# jesli tak, liczba 1 jest wieksza
    decl %eax			# zmniejsz eax
    subl $4, %esi		# zmniejsz adres
    cmpl 20(%ebp), %eax		# sprawdz czy eax != dlugosc drugiej liczby
      jne big_compare_longer_loop_1	# sprawdzenie sie powiodlo, kontynuuj petle
    jmp big_compare_cmp
big_compare_longer_2:
    movl 16(%ebp), %esi
    movl 20(%ebp), %eax
    leal -4(%esi,%eax,4), %esi    
  big_compare_longer_loop_2:
    movl (%esi), %ebx
    cmpl $0, %ebx
      jne big_compare_bigger_2
    decl %eax
    subl $4, %esi
    cmpl 12(%ebp), %eax
      jne big_compare_longer_loop_2

big_compare_cmp:
# poniewaz eax mozna juz teraz uzyc zarowno do indexowania obu liczb,
# o argumentach 12(%ebp) i 20(%ebp) zapominamy...
  movl 8(%ebp), %esi		# adres pierwszej tablicy do esi
  movl 16(%ebp), %edi		# adres drugiej do edi
  leal -4(%esi,%eax,4), %esi	# ustawiamy esi na ostatni element
  leal -4(%edi,%eax,4), %edi	# j/w
big_compare_cmp_loop:
  movl (%esi), %ebx		# element z tablicy pierwszej do ebx
  cmpl (%edi), %ebx		# porownujemy z elementem w drugiej tablicy
    ja big_compare_bigger_1	# ebx wiekszy - liczba 1. wieksza
    jb big_compare_bigger_2	# ebx mniejszy - liczba 2. wieksza
  decl %eax			# zmniejszamy eax
  cmpl $0, %eax			# sprawdzamy czy eax == 0
    je big_compare_end		# koniec
  subl $4, %esi			# przesuwamy sie o jeden element wstecz (1-sza tablica)
  subl $4, %edi			# j/w (2-ga tablica)
  jmp big_compare_cmp_loop

big_compare_bigger_1:
  movl $1, %eax
  jmp big_compare_end
big_compare_bigger_2:
  movl $-1, %eax
  jmp big_compare_end
big_compare_end:  
  movl %ebp, %esp
  popl %ebp
  ret

# big_mov - kopiuje dlugie liczby  
# Argumenty:
# 8(%ebp)	- liczba do skopiowania
# 12(%ebp)	- dlugosc liczby
# 16(%ebp)	- bufor do ktorego kopiujemy
# Komentarze:
# - funkcja nie sprawdza czy bufor pomiesci dana liczbe,
#   programista musi sie sam o to zatroszczyc
.globl big_mov
.type big_mov,@function
big_mov:
  pushl %ebp
  movl %esp, %ebp
  
  movl 8(%ebp), %esi
  movl 12(%ebp), %ecx
  movl 16(%ebp), %edi
big_mov_loop:
  movl (%esi), %eax
  movl %eax, (%edi)
  decl %ecx
  cmpl $0, %ecx
    je big_mov_end      
  addl $4, %esi
  addl $4, %edi
  jmp big_mov_loop
big_mov_end:
  movl %ebp, %esp
  popl %ebp
  ret

# big_set	- ustawia wszystkie elementy tablicy na podana wartosc
# Argumenty:
# 8(%ebp)	- adres do tablicy
# 12(%ebp)	- ilosc elementow
# 16(%ebp)	- wartosc
big_set:
  pushl %ebp
  movl %esp, %ebp
  movl 8(%ebp), %esi
  movl 12(%ebp), %ecx
  movl 16(%ebp), %eax
big_set_loop:
  movl %eax, (%esi)
  decl %ecx
  addl $4, %esi
  cmpl $0, %ecx
    ja big_set_loop
    
  movl %ebp, %esp
  popl %ebp
  ret
  
  