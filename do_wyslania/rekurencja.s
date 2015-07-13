# Program wykonuje dzielenie (funkcja dzielenier) wedlug algorytmu:
# 1. r <- dzielna
#    q <- 0
# 2. a) r - dzielnik
#    b) if r < dzielna - wyjdz z rekurencji
#       else if r >= dzielna - wywolaj funkcje rekurencyjna z parametrami (r, dzielnik)
# 3. Przy opuszczaniu kolejnych wywolan funkcji: q <- q+1
# 4. Iloraz= q, Reszta= r
#
# - Dodatkowo dolaczona zostala tez wersja iteracyjna funkcji - funkcja dzielenie
.equ READ, 3
.equ WRITE, 4
.equ STDIN, 0
.equ STDOUT, 1
.equ EXIT, 1
.equ EXIT_SUCCESS, 0
.equ LINUX_SYSCALL, 0x80

.bss
.equ LBUFOR, 12
.equ LDWORD, 4
.lcomm buforl, LDWORD
.lcomm bufor, LBUFOR
.lcomm dzielna, LDWORD
.lcomm dzielnik, LDWORD
.lcomm wynik, LDWORD

.data
powitanie:
  .ascii "Program liczy iloraz dzielenia.\n\0"
  lpowitanie = .-powitanie
pdzielna:
  .ascii "Podaj dzielna: \0"
  lpdzielna = .-pdzielna
pdzielnik:
  .ascii "Podaj dzielnik: \0"
  lpdzielnik = .-pdzielnik
szWyniki:
  .ascii "Wynik funkcji bez rekurencji: \n\0"
  lszWyniki = .-szWyniki
szWynikiR:
  .ascii "Wynik funkcji z rekurencja: \n\0"
  lszWynikiR = .-szWynikiR
szIloraz:
  .ascii "\tIloraz: \0"
  lszIloraz = .-szIloraz
szReszta:
  .ascii "\tReszta: \0"
  lszReszta = .-szReszta
szDzielnikZero:
  .ascii "Dzielenie przez zero.\n\0"
  lszDzielnikZero = .-szDzielnikZero
  
.text
.globl _start
_start:
movl $WRITE, %eax
movl $STDOUT, %ebx
movl $powitanie, %ecx
movl $lpowitanie, %edx
int $LINUX_SYSCALL

# zapytaj o dzielna
movl $WRITE, %eax
movl $STDOUT, %ebx
movl $pdzielna, %ecx
movl $lpdzielna, %edx
int $LINUX_SYSCALL

movl $READ, %eax
movl $STDIN, %ebx
movl $bufor, %ecx
movl $LBUFOR, %edx
int $LINUX_SYSCALL

# przekonwertuj wpisany ciag na liczbe 32-bitowa i zachowaj w zmiennej dzielna
pushl $10
pushl $bufor
call przelicz_ciag
addl $8, %esp
movl %eax, dzielna

# zapytaj o dzielnik
movl $WRITE, %eax
movl $STDOUT, %ebx
movl $pdzielnik, %ecx
movl $lpdzielnik, %edx
int $LINUX_SYSCALL

movl $READ, %eax
movl $STDIN, %ebx
movl $bufor, %ecx
movl $LBUFOR, %edx
int $LINUX_SYSCALL

# ciag znakow na liczbe, ktora wpisz do zmiennej dzielnik
pushl $10
pushl $bufor
call przelicz_ciag
addl $8, %esp

# sprawdzimy jeszcze czy dzielnik nie jest czasem rowny zero
cmpl $0, %eax
  je dzielnik_zero
  
movl %eax, dzielnik

# wywolanie funkcji - wersja bez rekurencji
pushl dzielnik
pushl dzielna
call dzielenie
addl $8, %ebp

pushl %edx	# reszta
pushl %eax	# iloraz

movl $WRITE, %eax
movl $STDOUT, %ebx
movl $szWyniki, %ecx
movl $lszWyniki, %edx
int $LINUX_SYSCALL

# konwertuj iloraz na ciag znakow
popl %eax
pushl $bufor
pushl $10
pushl %eax
call konwertuj_liczbe
addl $12, %esp
movl %eax, buforl	# dlugosc ciagu do zmiennej buforl

movl $WRITE, %eax
movl $STDOUT, %ebx
movl $szIloraz, %ecx
movl $lszIloraz, %edx
int $LINUX_SYSCALL

# wypisz iloraz
movl $WRITE, %eax
movl $STDOUT, %ebx
movl $bufor, %ecx
movl buforl, %edx
int $LINUX_SYSCALL

# w podobny sposob zalatw reszte
popl %edx
pushl $bufor
pushl $10
pushl %edx
call konwertuj_liczbe
addl $12, %esp
movl %eax, buforl

movl $WRITE, %eax
movl $STDOUT, %ebx
movl $szReszta, %ecx
movl $lszReszta, %edx
int $LINUX_SYSCALL

movl $WRITE, %eax
movl $STDOUT, %ebx
movl $bufor, %ecx
movl buforl, %edx
int $LINUX_SYSCALL

# wywolanie funkcji - wersja z rekurencja
pushl dzielnik
pushl dzielna
call dzielenier
addl $8, %ebp

# wyniki dzialania funkcji traktujemy tak samo jak w przypadku funkcji iteracyjnej
pushl %edx
pushl %eax

movl $WRITE, %eax
movl $STDOUT, %ebx
movl $szWynikiR, %ecx
movl $lszWynikiR, %edx
int $LINUX_SYSCALL

popl %eax
pushl $bufor
pushl $10
pushl %eax
call konwertuj_liczbe
addl $12, %esp
movl %eax, buforl

movl $WRITE, %eax
movl $STDOUT, %ebx
movl $szIloraz, %ecx
movl $lszIloraz, %edx
int $LINUX_SYSCALL

movl $WRITE, %eax
movl $STDOUT, %ebx
movl $bufor, %ecx
movl buforl, %edx
int $LINUX_SYSCALL

popl %edx
pushl $bufor
pushl $10
pushl %edx
call konwertuj_liczbe
addl $12, %esp
movl %eax, buforl

movl $WRITE, %eax
movl $STDOUT, %ebx
movl $szReszta, %ecx
movl $lszReszta, %edx
int $LINUX_SYSCALL

movl $WRITE, %eax
movl $STDOUT, %ebx
movl $bufor, %ecx
movl buforl, %edx
int $LINUX_SYSCALL

movl $EXIT, %eax
movl $EXIT_SUCCESS, %ebx
int $LINUX_SYSCALL

dzielnik_zero:
movl $WRITE, %eax
movl $STDOUT, %ebx
movl $szDzielnikZero, %ecx
movl $lszDzielnikZero, %edx
int $LINUX_SYSCALL

movl $EXIT, %eax
movl $1, %ebx
int $LINUX_SYSCALL

# Funkcja dzielenie, bez rekurencji
# 8(%ebp)	dzielna
# 12(%ebp)	dzielnik
# Wartosci zwracane:
# - eax - iloraz
# - edx - reszta
.type dzielenie,@function
dzielenie:
  pushl %ebp
  movl %esp, %ebp
  xorl %eax, %eax
  movl 8(%ebp), %edx	# przepisz dzielna do edx
dzielenie_loop:
  cmpl 12(%ebp), %edx	# sprawdz czy dzielna mniejsza od dzielnika
    jl dzielenie_end
  incl %eax
  subl 12(%ebp), %edx	# zmniejsz edx o dzielnik
  jmp dzielenie_loop
dzielenie_end:
  movl %ebp, %esp
  popl %ebp
  ret

# Funkcja dzielenier, z rekurencja
# 8(%ebp)	dzielna
# 12(%ebp)	dzielnik
# Wartosci zwracane:
# - eax - iloraz
# - edx - reszta
# Komentarze:
# - warunkiem wyjscia z rekurencji jest 8(%ebp) < dzielnik
# - za kazdym wywolaniem pomniejszamy 8(%ebp) o dzielnik
# - reszta znajdujaca sie w edx bedzie wynikiem ostatniego odejmowania 8(%ebp) - dzielnik.
# - na koncu kazdego wywolania powiekszamy eax o jeden, jest to iloraz
.type dzielenier,@function
dzielenier:
  pushl %ebp
  movl %esp, %ebp
  xorl %eax, %eax	# eax bedzie zawierac iloraz
  movl 8(%ebp), %edx	# przepisz dzielna do edx
  cmpl 12(%ebp), %edx	# sprawdz czy dzielna mniejsza od dzielnika
    jl dzielenier_end

  subl 12(%ebp), %edx	# zmniejsz edx o dzielnik
  pushl 12(%ebp)
  pushl %edx
  call dzielenier
  addl $8, %esp

  incl %eax		# zwieksz iloraz o jeden
  jmp dzielenie_loop
dzielenier_end:
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
  cmpl $0, %eax
    je konwertuj_3_zero
  xorl %ecx, %ecx
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
    movl 16(%ebp), %edx
    movl $1, -4(%ebp)
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
  