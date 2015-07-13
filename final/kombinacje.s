.equ READ, 3
.equ WRITE, 4
.equ STDIN, 0
.equ STDOUT, 1
.equ EXIT, 1
.equ EXIT_SUCCESS, 0
.equ LINUX_SYSCALL, 0x80

.bss
.equ LBIGBUFOR, 1024
.equ LBUFOR, 12
.equ LDWORD, 4
.lcomm lenwynik, LDWORD
.lcomm wynik, LBUFOR
.lcomm bufor, LBUFOR
.lcomm n, LDWORD
.lcomm n2, LDWORD
.lcomm k, LDWORD
.lcomm k2, LDWORD
.lcomm tmpn, LDWORD

.data
linia:
  .ascii "====================================================\n\0"
  linia_len = .-linia
podajl1:
  .ascii "Podaj wartosc N: \0"
  podajl1_len = .-podajl1
podajl2:
  .ascii "Podaj wartosc K: \0"
  podajl2_len = .-podajl2
failura_wieksze:
  .ascii "K nie moze byc wieksze od N\n\0"
  fail_wieksze_len = .-failura_wieksze
tmpwynik:
  .long 1

.text
.globl _start
_start:
movl $WRITE, %eax
movl $STDOUT, %ebx
movl $linia, %ecx
movl $linia_len, %edx
int $LINUX_SYSCALL

movl $WRITE, %eax
movl $STDOUT, %ebx
movl $podajl1, %ecx
movl $podajl1_len, %edx
int $LINUX_SYSCALL

movl $READ, %eax
movl $STDIN, %ebx
movl $bufor, %ecx
movl $LBUFOR, %edx
int $LINUX_SYSCALL

pushl $10
pushl $bufor
call przelicz_ciag
addl $8, %esp
movl %eax, n
movl %eax, n2	# zmienna dla f. rekurencyjnej

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

pushl $10
pushl $bufor
call przelicz_ciag
addl $8, %esp

# poniewaz (n po k) == (n po n-k) nalezy sprawdzic
# czy przypadek (n po n-k) nie bylby prostszy do obliczenia
movl n, %ebx
subl %eax, %ebx
cmpl %ebx, %eax
  jl komb_przepisz_eaxk
movl %ebx, %eax
movl %ebx, k
movl %ebx, k2	# zmienna dla f. rekurencyjnej
jmp komb_

komb_przepisz_eaxk:
movl %eax, k
movl %eax, k2


# koniec porownywan, przepisz eax do zmiennej k
# wartosci n i k juz znajduja sie w buforach
komb_:
# po pobraniu liczb pora sprawdzic trywialne przypadki
movl k, %eax
cmpl $0, %eax		# do k wpisano zero
  je komb_wpisz_1
cmpl $1, %eax		# k == 1
  je komb_wpisz_n
cmpl n, %eax		# n == k
  je komb_wpisz_1
cmpl n, %eax		# k wieksze niz n
  ja komb_failura
incl %eax		# jezeli eax = n-1
cmpl n, %eax
  je komb_wpisz_n
decl %eax

movl n, %eax 	# n do eax
movl k, %ebx 	# k do ebx
pushl %eax

xorl %edx, %edx
idivl %ebx		# dzielimy przez k (moze sie skroci)
cmpl $0, %edx		
  jne pre_komb_bringkback # jesli sie nie skrocilo
addl $4, %esp		# usuwamy wartosc ze stosu (nie jest juz potrzebna)
movl $1, %ebx
jmp komb_licz

pre_komb_bringkback:
popl %eax		# przywracamy poprzednie eax

komb_licz:
  decl n		# pomniejszamy n
  decl k		# pomniejszamy k
  imull n, %eax
  cmpl $1, k
    je komb_licz_end  
  pushl %eax		# zrzucamy wartosc n na stos
  xorl %edx, %edx
  idivl k		# dzielimy przez k (moze sie skroci)
  cmpl $0, %edx		
    jne komb_bringkback # jesli sie nie skrocilo
  addl $4, %esp		# usuwamy wartosc ze stosu (nie jest juz potrzebna)
  jmp komb_licz
komb_bringkback:
  popl %eax		# przywracamy poprzednie eax
  imull k, %ebx		# mnozymy ebx przez k
  jmp komb_licz
komb_licz_end:
  xorl %edx, %edx
  divl %ebx
  
pushl $wynik
pushl $10
pushl %eax
call konwertuj_liczbe
addl $12, %esp
movl %eax, lenwynik

jmp komb_wypisz_wynik
			
komb_wpisz_1:
pushl $wynik
pushl $10
pushl $1
call konwertuj_liczbe
addl $12, %esp
movl %eax, lenwynik

jmp komb_wypisz_wynik

komb_wpisz_n:
pushl $wynik
pushl $10
pushl n
call konwertuj_liczbe
addl $12, %esp
movl %eax, lenwynik

jmp komb_wypisz_wynik

komb_failura:
movl $WRITE, %eax
movl $STDOUT, %ebx
movl $failura_wieksze, %ecx
movl $fail_wieksze_len, %edx
int $LINUX_SYSCALL

jmp komb_koniec

komb_wypisz_wynik:
movl $WRITE, %eax
movl $STDOUT, %ebx
movl $wynik, %ecx
movl lenwynik, %edx
int $LINUX_SYSCALL

# Tu wykonaj wersje rekurencyjna
pushl k2
pushl n2
call kombinacjer
addl $8, %esp

pushl $wynik
pushl $10
pushl %eax
call konwertuj_liczbe
addl $12, %esp
movl %eax, lenwynik

movl $WRITE, %eax
movl $STDOUT, %ebx
movl $wynik, %ecx
movl lenwynik, %edx
int $LINUX_SYSCALL

komb_koniec:
movl $EXIT, %eax
movl $EXIT_SUCCESS, %ebx
int $LINUX_SYSCALL

# Funckja rekurencyjna kombinacjer
# Argumenty:
# 8(%ebp)	- n
# 12(%ebp)	- k
.type kombinacjer,@function
kombinacjer:
pushl %ebp
movl %esp, %ebp

  decl 8(%ebp)		# pomniejszamy n
  decl 12(%ebp)		# pomniejszamy k
  
  cmpl $-1, 12(%ebp)		# sprawdzamy czy podano k == 0
    je kombinacjer_wpisz_1
  cmpl $0, 12(%ebp)		# sprawdzamy czy podano k == 1
    je kombinacjer_wpisz_n

  pushl 12(%ebp)
  pushl 8(%ebp)
  call kombinacjer
  addl $8, %esp

  jmp kombinacjer_licz
kombinacjer_wpisz_1:
  movl $1, %eax
  jmp kombinacjer_end
kombinacjer_wpisz_n:
  movl 8(%ebp), %eax	# wpisujemy obecne n do eax
  incl %eax		# poniewaz f. zmniejsza n na samym poczatku musimy teraz przywrocic poprzednia wartosc

  jmp kombinacjer_end
kombinacjer_licz:
  incl 8(%ebp)		# zwiekszamy n (zostalo zmniejszone wyzej)
  incl 12(%ebp)		# j/w dla k
  
  imull 8(%ebp), %eax	# licznik = n * licznik
  pushl %eax		# zrzucamy wartosc n na stos
  xorl %edx, %edx
  idivl 12(%ebp)	# dzielimy przez k (skroci sie)
  cmpl $0, %edx		
    jne kombinacjer_bringkback # jesli sie nie skrocilo
  addl $4, %esp		# usuwamy wartosc ze stosu (nie jest juz potrzebna)
  jmp kombinacjer_end
kombinacjer_bringkback:
  popl %eax		# przywracamy poprzednio eax
  imull 12(%ebp), %ebx	# mnozymy ebx przez k (mianownik = k*mianownik)
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

