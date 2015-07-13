# === DO POPRAWNEJ KOMPILACJI WYMAGANE JEST DOLACZENIE PLIKU bignumbers.s ===

# Program zawiera zarowno funkcje iteracyjna jak i rekurencyjna
# Program liczy kombinacje n po k
# gdzie n to dowolna liczba (ograniczona wielkoscia LDWORD*LELEMENTY)
# a k nie moze byc wieksze niz 2^32
# - k jest ograniczone do 32 bitow tylko ze wzgledu na czas wykonania.
#   Funkcja, ktora byla w stanie podzielic dwie dowolnie duze liczby, wykonywala obliczenia
#   zbyt dlugo - przyklad takiej funkcji (operujacej na 32 bitach) znajduje sie w programie 
#   dzielenierek, a funkcja dla duzych liczb znajduje sie w bignumbers.s i nazywa sie
#   big_div


.equ READ, 3
.equ WRITE, 4
.equ STDIN, 0
.equ STDOUT, 1
.equ EXIT, 1
.equ EXIT_SUCCESS, 0
.equ LINUX_SYSCALL, 0x80

.bss
.equ LBIGBUFOR, 1024*1024
.equ LBIGELEMENTY, LBIGBUFOR/4
.equ LBUFOR, 12
.equ LDWORD, 4
.equ LELEMENTY, 1024
.lcomm lenwynik, LDWORD
.lcomm wynik, LBIGBUFOR
.lcomm bufor, LBIGBUFOR
.lcomm lenn, LDWORD
.lcomm n, LDWORD*LELEMENTY
.lcomm n2, LDWORD*LELEMENTY	# dla f. rekurencyjnej
.lcomm k, LDWORD
.lcomm k2, LDWORD		# dla f. rekurencyjnej
.lcomm tmpnum, LDWORD*LELEMENTY

.data
linia:
  .skip 78, '='
  .byte 0xA, 0x0
  linia_len = .-linia
podajl1:
  .ascii "Podaj wartosc N: \0"
  podajl1_len = .-podajl1
podajl2:
  .ascii "Podaj wartosc K: \0"
  podajl2_len = .-podajl2
strIt:
  .ascii "Iteracyjna: \0"
  strIt_len = .-strIt
strRek:
  .ascii "Rekurencyjna: \0"
  strRek_len = .-strRek
failura_wieksze:
  .ascii "K nie moze byc wieksze od N\n\0"
  fail_wieksze_len = .-failura_wieksze
tmpwynik:
  .long 1
zero:	 .long 0
jedynka: .long 1

.text
.globl _start
_start:
movl $WRITE, %eax
movl $STDOUT, %ebx
movl $linia, %ecx
movl $linia_len, %edx
int $LINUX_SYSCALL

# pytamy o N
movl $WRITE, %eax
movl $STDOUT, %ebx
movl $podajl1, %ecx
movl $podajl1_len, %edx
int $LINUX_SYSCALL

movl $READ, %eax
movl $STDIN, %ebx
movl $bufor, %ecx
movl $LBIGBUFOR, %edx
int $LINUX_SYSCALL

# konwertujemy podany ciag znakow na liczbe
pushl $10
pushl $tmpnum
pushl $LELEMENTY
pushl $n
pushl $bufor
call big_strtonum
addl $20, %esp
movl %eax, lenn

# przepisujemy ta liczbe aby mozna bylo ja wykorzystac w f. rekurencyjnej
pushl $n2
pushl %eax
pushl $n
call big_mov
addl $12, %esp

# teraz pytamy o k
movl $WRITE, %eax
movl $STDOUT, %ebx
movl $podajl2, %ecx
movl $podajl2_len, %edx
int $LINUX_SYSCALL

movl $READ, %eax
movl $STDIN, %ebx
movl $bufor, %ecx
movl $LBUFOR, %edx
int $LINUX_SYSCALL

# wpisujemy k do zmiennych k i k2
pushl $10
pushl $bufor
call przelicz_ciag
addl $8, %esp
movl %eax, k
movl %eax, k2

# sprawdzamy czy k > n lub k == n
pushl $1
pushl $k
pushl lenn
pushl $n
call big_compare
addl $16, %esp

cmpl $-1, %eax
  je komb_failure
cmpl $0, %eax
  je komb_wpisz_1

# poniewaz (n po k) == (n po n-k) nalezy sprawdzic
# czy przypadek (n po n-k) nie bylby prostszy do obliczenia

# zanim to jednak zrobimy sprawdzmy czy po zamienieniu k na n-k nie otrzymamy czasem
# liczby wiekszej niz 2^32
cmpl $1, lenn
  ja komb_

# wykonujemy n-k
pushl $LELEMENTY
pushl $bufor
pushl $1
pushl $k
pushl lenn
pushl $n
call big_sub
addl $24, %esp

cmpl $1, %eax 	# jezeli dlugosc wyniku wieksza od jeden
  ja komb_

# sprawdzamy czy n-k < k
# zanim to jednak zrobimy sprawdzmy czy po zamienieniu k na n-k nie otrzymamy czasem
# liczby wiekszej niz 2^32
cmpl $1, lenn
  ja komb_
  
pushl $1
pushl $k	# k
pushl %eax
pushl $bufor	# n-k
call big_compare
addl $16, %esp

cmpl $1, %eax
  je komb_
  
movl bufor, %eax
movl %eax, k
movl %eax, k2	# zmienna dla f. rekurencyjnej

# koniec porownywan, przepisz eax do zmiennej k
# wartosci n i k juz znajduja sie w buforach
komb_:
# po pobraniu liczb pora sprawdzic trywialne przypadki
movl k, %eax
cmpl $0, %eax		# do k wpisano zero
  je komb_wpisz_1
cmpl $1, %eax		# k == 1
  je komb_wpisz_n
  
# ==================================================
# = WYLICZENIE KOMBINACJI			   =
# ==================================================
# wywolujemy funkcje wykonujaca algorytm w wersji iteracyjnej
pushl $wynik
pushl $LBIGELEMENTY
pushl $bufor
pushl k
pushl lenn
pushl $n
call kombinacjeit
addl $24, %esp
movl %eax, lenwynik

# konwertujemy otrzymany wynik na ciag znakow
pushl $10
pushl $LBIGBUFOR  
pushl $wynik
pushl lenwynik
pushl $bufor
call big_numtostr
addl $20, %esp
movl %eax, lenwynik

jmp komb_wypisz_wynik
			
komb_wpisz_1:
pushl $wynik
pushl $10
pushl $1
call konwertuj_liczbe
addl $12, %esp
movl %eax, lenwynik
movl $0, k2

jmp komb_wypisz_wynik

komb_wpisz_n:
pushl $10
pushl $LBIGBUFOR  
pushl $wynik
pushl lenn
pushl $n
call big_numtostr
addl $20, %esp
movl %eax, lenwynik

jmp komb_wypisz_wynik

komb_failure:
movl $WRITE, %eax
movl $STDOUT, %ebx
movl $failura_wieksze, %ecx
movl $fail_wieksze_len, %edx
int $LINUX_SYSCALL

jmp komb_koniec

komb_wypisz_wynik:
movl $WRITE, %eax
movl $STDOUT, %ebx
movl $strIt, %ecx
movl $strIt_len, %edx
int $LINUX_SYSCALL

movl $WRITE, %eax
movl $STDOUT, %ebx
movl $wynik, %ecx
movl lenwynik, %edx
int $LINUX_SYSCALL

# ==================================================
# = WYLICZENIE KOMBINACJI - REKURENCJA		   =
# ==================================================
pushl $wynik
pushl $LBIGELEMENTY
pushl $bufor
pushl k2
pushl lenn
pushl $n2
call kombinacjer
addl $24, %esp
movl %eax, lenwynik

# konwertujemy otrzymany wynik na ciag znakow
pushl $10
pushl $LBIGBUFOR  
pushl $wynik
pushl lenwynik
pushl $bufor
call big_numtostr
addl $20, %esp
movl %eax, lenwynik

# wypisujemy wynik funkcji rekurencyjnej
movl $WRITE, %eax
movl $STDOUT, %ebx
movl $strRek, %ecx
movl $strRek_len, %edx
int $LINUX_SYSCALL

movl $WRITE, %eax
movl $STDOUT, %ebx
movl $wynik, %ecx
movl lenwynik, %edx
int $LINUX_SYSCALL

komb_koniec:
movl $EXIT, %eax
movl $EXIT_SUCCESS, %ebx
int $LINUX_SYSCALL

# Funkcja iteracyjna kombinacjeit
# Argumenty:
# 8(%ebp)	- n
# 12(%ebp)	- dlugosc n
# 16(%ebp)	- k
# 20(%ebp)	- bufor na wynik
# 24(%ebp)	- dlugosc bufora na wynik
# 28(%ebp)	- bufor pomocniczy (musi byc tak samo duzy jak bufor na wynik)
# Zmienne lokalne:
# -4(%ebp)	- dlugosc wyniku
# -8(%ebp)	- temp k
# -12(%ebp)	- jedynka
# -16(%ebp)	- adres na jedynke
# -20(%ebp)	- miejsce na reszte
# -24(%ebp)	- adres na reszte
# Wartosc zwracana:
# eax = dlugosc wyniku
.type kombinacjeit,@function
kombinacjeit:
  pushl %ebp
  movl %esp, %ebp
  subl $24, %esp
  
  # inicjalizacja zmiennych lokalnych
  movl $1, -12(%ebp)
  movl %ebp, -16(%ebp)
  subl $12, -16(%ebp)
  movl %ebp, -24(%ebp)
  subl $20, -24(%ebp)

# Zamiast liczyc (n po k) = (n\k) * (n-1\k-1) * ...
# policzymy (n po k) = (n\1) * (n-1\2) * ... * (n-k+1\k)
# poniewaz wtedy za kazdym przejsciem petli mozna bedzie
# aktualny wynik podzielic przez aktualny mianownik bez
# otrzymywania reszty

# Zaczynamy od przepisania n do bufora przeznaczonego na wynik
movl 12(%ebp), %eax		# dlugosc n do eax
movl %eax, -4(%ebp)	# dlugosc n do dlugosci wyniku
pushl 20(%ebp)
pushl %eax
pushl 8(%ebp)
call big_mov
addl $12, %esp

movl $1, -8(%ebp)

# petla
kombinacjeit_loop:
# zwiekszamy k o jeden
incl -8(%ebp)

# zmniejszamy n o jeden
pushl 12(%ebp)
pushl 8(%ebp)
pushl $1
pushl -16(%ebp)
pushl 12(%ebp)
pushl 8(%ebp)
call big_sub
addl $24, %esp
movl %eax, 12(%ebp)

# mnozymy n przez bufor
pushl 24(%ebp)
pushl 28(%ebp)
pushl 12(%ebp)
pushl 8(%ebp)
pushl -4(%ebp)
pushl 20(%ebp)
call big_mull
addl $24, %esp
movl %eax, -4(%ebp)

# dzielimy bufor przez k
pushl -24(%ebp)
pushl 24(%ebp)
pushl 20(%ebp)
pushl -8(%ebp)
pushl -4(%ebp)
pushl 28(%ebp)
call big_div2
addl $24, %esp
movl %eax, -4(%ebp)

# sprawdzamy czy temp k jest rozne od k
movl -8(%ebp), %eax
cmpl 16(%ebp), %eax
  jne kombinacjeit_loop

  movl -4(%ebp), %eax
  
  movl %ebp, %esp
  popl %ebp
  ret

# Funckja rekurencyjna kombinacjer
# Argumenty:
# 8(%ebp)	- bufor na n
# 12(%ebp)	- dlugosc n
# 16(%ebp)	- k
# 20(%ebp)	- bufor na wynik
# 24(%ebp)	- dlugosc bufora na wynik
# 28(%ebp)      - bufor pomocniczy
# Zmienne lokalne:
# -4(%ebp)	- jedynka
# -8(%ebp)	- adres na jedynke
# -12(%ebp)	- aktualna dlugosc wyniku
# Wartosc zwracana:
# eax = dlugosc wyniku
.type kombinacjer,@function
kombinacjer:
  pushl %ebp
  movl %esp, %ebp
  subl $12, %esp
  
  # inicjalizuj zmienne lokalne
  movl $1, -4(%ebp)
  movl %ebp, -8(%ebp)
  subl $4, -8(%ebp)

  decl 16(%ebp)		# pomniejszamy k
  
  cmpl $-1, 16(%ebp)		# sprawdzamy czy podano k == 0
    je kombinacjer_wpisz_1
  cmpl $0, 16(%ebp)		# sprawdzamy czy podano k == 1
    je kombinacjer_wpisz_n


  # pomniejszamy n, przepisujemy nowa dlugosc n do 12(%ebp)
  pushl 12(%ebp)
  pushl 8(%ebp) 
  pushl $1
  pushl -8(%ebp)
  pushl 12(%ebp)
  pushl 8(%ebp)
  call big_sub
  addl $24, %esp
  movl %eax, 12(%ebp)
   

# wywolujemy funkcje rekurencyjna, dlugosc wyniku 
# po jej przejsciu zapisujemy w zmiennej lokalnej
  pushl 28(%ebp)
  pushl 24(%ebp)
  pushl 20(%ebp)
  pushl 16(%ebp)
  pushl 12(%ebp)
  pushl 8(%ebp)
  call kombinacjer
  addl $24, %esp
  movl %eax, -12(%ebp)

  jmp kombinacjer_licz
kombinacjer_wpisz_1:
  # przepisujemy jeden do wyniku
  movl $1, %eax
  movl 20(%ebp), %edi
  movl $1, (%edi)
  jmp kombinacjer_end

kombinacjer_wpisz_n:
  # przepisujemy aktualne n do wyniku
  pushl 20(%ebp)
  pushl 12(%ebp)
  pushl 8(%ebp)
  call big_mov
  addl $12, %esp
  movl 12(%ebp), %eax

  jmp kombinacjer_end
kombinacjer_licz:
  # zwiekszamy n (zostalo zmniejszone wyzej)
  pushl 12(%ebp)
  pushl 8(%ebp)
  pushl $1
  pushl -8(%ebp)
  pushl 12(%ebp)
  pushl 8(%ebp)
  call big_add
  addl $24, %esp
  
  incl 16(%ebp)		# j/w dla k

# licznik = n * licznik  
  pushl 24(%ebp)
  pushl 28(%ebp) 	
  pushl -12(%ebp)
  pushl 20(%ebp)
  pushl %eax
  pushl 8(%ebp)
  call big_mull
  addl $24, %esp
  
# licznik = licznik / k  
  pushl -8(%ebp)
  pushl 24(%ebp)
  pushl 20(%ebp)
  pushl 16(%ebp)
  pushl %eax
  pushl 28(%ebp)
  call big_div2
  addl $24, %esp
    
kombinacjer_end:
  movl %ebp, %esp
  popl %ebp
  ret

# Funkcja przelicz_ciag - skanuje podany ciag ascii
# przerabia go na wartosci liczbowe, ktore sa zapisywane
# do tablicy
# Argumenty:
# 1. Ciag znakow		- 8(%ebp)
# 2. Podstawa liczby		- 12(%ebp)
# Dane:
# eax - wartosc zwracana, ile bajtow zajmuje liczba
#	rowne zero gdy wystapil blad
# ebx - aktualny znak przekopiowany z (%ecx)
# ecx - adres do aktualnego znaku
.type przelicz_ciag,@function
przelicz_ciag:
pushl %ebp
movl %esp, %ebp

movl $0, %eax
movl 8(%ebp), %ecx
xorl %ebx, %ebx	# zeruj ebx
movb (%ecx), %bl
cmpb $0x20, %bl
  jbe przelicz_ciag_failure

przelicz_ciag_begin:
subb $0x30, %bl  
cmpl 12(%ebp), %ebx  	# wartosc jest ponizej podstawy
  jb przelicz_ciag_licz

przelicz_ciag_16:
cmpl $10, 12(%ebp)	# podstawa jest ponizej 10 - czytaj: wpisano glupoty
  jb przelicz_ciag_failure

orb $0b00100000, %bl	# zamiana litery na mala
subb $0x27, %bl		# odjecie 27 od wartosci znaku (tak aby a = 10, b = 11, itd.)
cmpl 12(%ebp), %ebx	# wartosc znaku dalej powyzej podstawy
  jae przelicz_ciag_failure
cmpl $10, %ebx		# wartosc znaku jest teraz ponizej 10
  jl przelicz_ciag_failure 
  
przelicz_ciag_licz:
addl %ebx, %eax		# dodaj wartosc cyfry do wartosci liczby
incl %ecx		# przejdz do nastepnego znaku
xorl %ebx, %ebx		# zeruj ebx
movb (%ecx), %bl	# pobierz znak
cmpb $0x20, %bl		# sprawdz czy wartosc jest ponizej ENTER
  jbe przelicz_ciag_end	# koniec
imull 12(%ebp), %eax 	# podstawa systemu razy wartosc liczby
jmp przelicz_ciag_begin

przelicz_ciag_failure:
movl $0, %eax

przelicz_ciag_end:

movl %ebp, %esp
popl %ebp  
ret

# Funkcja konwertuj_liczbe - przepisuje liczbe
# do tablicy znakow w podanym formacie
# Argumenty:
# 1. liczba		8(%ebp)
# 2. podstawa		12(%ebp)
# 3. adres bufora wyjsciowego	16(%ebp)
# Dane:
# 1. ebx - podstawa liczby, kopia arg2
.type konwertuj_liczbe,@function
konwertuj_liczbe:
  pushl %ebp
  movl %esp, %ebp
  subl $4, %esp
  movl 12(%ebp), %ebx

# eax - wynik dzielenia
# ecx - ilosc cyfr
# edx - reszta z dzielenia
  movl 8(%ebp), %eax
  movl $0, %ecx
  konwertuj_2_loop:
  cmpl $0, %eax		# eax == 0, zakoncz
    je konwertuj_2_loop_end  

  incl %ecx		# powieksz ilosc cyfr o jeden
  xorl %edx, %edx	# wyzeruj edx (potrzebne przy dzieleniu)
  idivl %ebx		# podziel edx:eax przez ebx, reszta dzielenia jest w edx, wynik w eax
  pushl %edx		# odloz edx na stos
  jmp konwertuj_2_loop	# powtarzaj dopoki eax == 0
  konwertuj_2_loop_end:
  movl %ecx, -4(%ebp)   # zapisujemy ilosc cyfr do zmiennej lokalnej

# eax - aktualna wartosc
# ecx - ilosc cyfr (ma wartosc z poprzedniego podpunktu)
# edx - adres aktualnego znaku

  movl 16(%ebp), %edx  # przepisz adres bufora do edx

  konwertuj_3_loop:
    cmpl $0, %ecx
      je konwertuj_3_end
      
    popl %eax
    cmpl $9, %eax	# jezeli cyfra jest od 0 - 9
      jle konwertuj_3_loop_1
    jmp konwertuj_3_loop_2  # else
    
    konwertuj_3_loop_1:
      addl $0x30, %eax	# dodaj 0x30 do wartosci cyfry
      jmp konwertuj_3_loop_3
    konwertuj_3_loop_2:
      subl $0x9, %eax	# odejmij 0x9 od wartosci cyfry
      addl $0x60, %eax  # dodaj 0x60, powinnismy otrzymac litere a - f

    konwertuj_3_loop_3:
      movb %al, (%edx)	# przepisz znak do miejsca pod adresem edx
      decl %ecx		# obniz ilosc cyfr o 1
      incl %edx		# zwieksz adres o 1
      jmp konwertuj_3_loop

  konwertuj_3_zero:
    movl $0x30, (%edx) # wpisz zero
    incl %edx    

  konwertuj_3_end:
    movl $0xA, (%edx)  # wpisz '\n'
    incl %edx
    movl $0x0, (%edx)  # wpisz '\0'
    movl -4(%ebp), %eax # przywroc ilosc cyfr, abysmy 
			# wiedzieli jaka jest dlugosc utworzonego ciagu
    addl $2, %eax	# dodaj dwa do dlugosci ciagu (czyli uwzgledniamy,
			# ze ciag zostal powiekszony o "\n\0")

  konwertuj_end:
  addl $4, %esp
  movl %ebp, %esp
  popl %ebp
  ret

