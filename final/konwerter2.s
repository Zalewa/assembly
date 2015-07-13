# Zasada dzialania programu jest prosta:
# najpierw zczytujemy liczbe z klawiatury, przerabiamy ja na wartosc liczbowa
# rozumiana przez komputer stosujac schemat Hornera.
# Nastepnie otrzymana wartosc przekazujemy do funkcji ktora przerabia liczbe
# na ciag znakow.
# Kazda funkcja w tym programie zwraca wartosc do %eax.

.equ EXIT, 1
.equ EXIT_SUCCESS, 0
.equ READ, 3
.equ WRITE, 4
.equ STDIN, 0
.equ STDOUT, 1

.bss
.equ LICZBA, 1024
.lcomm tekst, LICZBA

.equ ZNAK, 3
.lcomm cznak, ZNAK

.equ LTABLICA, 2048
.lcomm tablica, LTABLICA

.data
pytanie_liczba:
  .ascii "Wprowadz liczbe: \0"
  pyt_licz_len = .-pytanie_liczba
  
pytanie_podstawa:
  .ascii "Podaj podstawe liczby\n(b=2, o=8, d=10, x=16): \0"
  pyt_podst_len = .-pytanie_podstawa
  
pytanie:
  .ascii "Teraz wybierz na jaki format chcesz przekonwertowac liczbe\n(b=2, o=8, d=10, x=16): \0"
  pytanie_len = .-pytanie
  
failura:
  .ascii "Podano zly format wyjsciowy!\n\0"
  failura_len = .-failura
  
#podstawa:
#  .long 0
  
.text
.globl _start
_start:
movl $WRITE, %eax
movl $STDOUT, %ebx
movl $pytanie_podstawa, %ecx
movl $pyt_podst_len, %edx
int $0x80

movl $READ, %eax
movl $STDIN, %ebx
movl $cznak, %ecx
movl $ZNAK, %edx
int $0x80

xorl %eax, %eax
movb cznak, %al	# skopiuj pierwsza litere tekstu do %al
pushl %eax
call GetPodstawa
addl $4, %esp

cmpl $0, %eax	# funkcja rozpoznala znak
  jne zapytaj_o_liczbe

movl $WRITE, %eax
movl $STDOUT, %ebx
movl $failura, %ecx
movl $failura_len, %edx
int $0x80
jmp _start

zapytaj_o_liczbe:
pushl %eax
movl $WRITE, %eax
movl $STDOUT, %ebx
movl $pytanie_liczba, %ecx
movl $pyt_licz_len, %edx
int $0x80

movl $READ, %eax
movl $STDIN, %ebx
movl $tekst, %ecx
movl $LICZBA, %edx
int $0x80

# konwertujemy ciag na liczbe
# 2. argument jest juz na stosie
pushl $tekst
call przelicz_ciag
addl $8, %esp

pushl %eax	# odkladamy wartosc liczby na stos
# wyrzucamy zapytanie o format wyjsciowy
zapytaj_o_wynik:
movl $WRITE, %eax
movl $STDOUT, %ebx
movl $pytanie, %ecx
movl $pytanie_len, %edx
int $0x80

movl $READ, %eax
movl $STDIN, %ebx
movl $cznak, %ecx
movl $ZNAK, %edx
int $0x80

xorl %eax, %eax
movb cznak, %al	# skopiuj pierwsza litere tekstu do %al
pushl %eax
call GetPodstawa
addl $4, %esp

cmpl $0, %eax	# funkcja rozpoznala znak
  jne konwertuj

movl $WRITE, %eax
movl $STDOUT, %ebx
movl $failura, %ecx
movl $failura_len, %edx	
int $0x80
jmp zapytaj_o_wynik

# konwertujemy liczbe na ciag
konwertuj:
pushl %eax
popl %ebx	# przywracamy podstawe ze stosu
popl %eax	# przywracamy liczbe ze stosu
pushl $tekst
pushl %ebx
pushl %eax	# w tym miejscu przekazujemy liczbe jako argument do funkcji
call konwertuj_liczbe
addl $12, %esp

cmpl $0, %eax	# sprawdzamy czy konwertuj_liczbe sie NIE udalo
  je program_end

program_success:
movl %eax, %edx	# eax zawiera dlugosc ciagu utworzonego przez konwertuj_liczbe
movl $WRITE, %eax
movl $STDOUT, %ebx
movl $tekst, %ecx
int $0x80

program_end:
movl $EXIT, %eax
movl $EXIT_SUCCESS, %ebx
int $0x80

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

# Funkcja GetPodstawa
# odczytuje znaki, zwraca wartosc liczbowa
# b = 2
# o = 8
# d = 10
# x = 16
# Argumenty:
# 1. znak	8(%ebp)
# Dane:
# 1. eax - znak, pozniej wpisuje tu wartosc zwracana
# Nie rozroznia wielkosci znakow
.type GetPodstawa,@function
GetPodstawa:
pushl %ebp
movl %esp, %ebp

movl 8(%ebp), %eax
orb $0b00100000, %al	# konwertuj znak na mala litere
cmpb $0x62, %al		# 'b'
  je GetPodstawa_ret2
cmpb $0x6F, %al		# 'o'
  je GetPodstawa_ret8
cmpb $0x64, %al		# 'd'
  je GetPodstawa_ret10
cmpb $0x78, %al		# 'x'
  je GetPodstawa_ret16
xorl %eax, %eax		# nie rozpoznano znaku, zeruj eax
jmp GetPodstawa_end

GetPodstawa_ret2:
  movl $0b10, %eax
  jmp GetPodstawa_end
GetPodstawa_ret8:
  movl $010, %eax
  jmp GetPodstawa_end
GetPodstawa_ret10:
  movl $10, %eax
  jmp GetPodstawa_end
GetPodstawa_ret16:
  movl $0x10, %eax
  
GetPodstawa_end:
movl %ebp, %esp
popl %ebp
ret
  