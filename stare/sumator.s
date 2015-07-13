.equ LINUX_SYSCALL, 0x80
.equ STDIN, 0
.equ STDOUT, 1
.equ EXIT, 1
.equ WRITE, 4
.equ READ, 3

.bss
.equ BAJTY, 1024
.equ BAJTY2, 2048
.equ LENDWORD, 4
.equ BAJT, 1
.lcomm liczba1, BAJTY
.lcomm liczba2, BAJTY
.lcomm podstawa, LENDWORD
.lcomm dlugosc1, LENDWORD
.lcomm dlugosc2, LENDWORD
.lcomm wynik, BAJTY2
.lcomm przepelnienie, BAJT
    
.data
komunikat0:
    .ascii "\nPodaj w jakim formacie chcesz wprowadzic liczby\n(x - szesnastkowy, d - dziesietny): \0"
    kom0_len = .-komunikat0
komunikat1:
    .ascii "Podaj pierwsza liczbe: \0"
    kom1_len = .-komunikat1
komunikat3:    
    .ascii "Podaj druga liczbe: \0"
    kom3_len = .-komunikat3
blad0:
    .ascii "Podaj poprawny format!\n\0"
    blad0_len = .-blad0    
.text
.globl _start

_start:
# zapytaj o podstawe liczb
movl $WRITE, %eax
movl $STDOUT, %ebx
movl $komunikat0, %ecx
movl $kom0_len, %edx
int $LINUX_SYSCALL

movl $READ, %eax
movl $STDIN, %ebx
movl $podstawa, %ecx
movl $BAJTY, %edx
int $LINUX_SYSCALL

# teraz nalezy przerobic litere podana do zmiennej podstawa
# na wartosc liczbowa, albo 10 albo 16
orl %ebx, %ebx		# zerujemy %ebx
movb podstawa, %bl	# wrzucamy znak do ebx
orb $0b00100000, %bl	# zamieniamy na mala litere
cmpb $0x64, %bl		# %bl = 'd'
  je wpisz_10
cmpb $0x78, %bl		# %bl = 'x'
  je wpisz_16

# sprawdzenie nie powiodlo sie, wyrzuc komunikat o bledzie
# i powroc do pytania o podstawe
movl $WRITE, %eax
movl $STDOUT, %ebx
movl $blad0, %ecx
movl $blad0_len, %edx
int $LINUX_SYSCALL
jmp _start

wpisz_10:
  movl $10, %eax
  movl %eax, podstawa
  jmp pytanie_1_liczba
wpisz_16:
  movl $0x10, %eax
  movl %eax, podstawa

pytanie_1_liczba:
# zapytaj o pierwsza liczbe
movl $WRITE, %eax
movl $STDOUT, %ebx
movl $komunikat1, %ecx
movl $kom1_len, %edx
int $LINUX_SYSCALL

movl $READ, %eax
movl $STDIN, %ebx
movl $liczba1, %ecx
movl $BAJTY, %edx
int $LINUX_SYSCALL

decl %eax	# pomniejszamy dlugosc liczby o 2
decl %eax	# pozbywajac sie entera i \0
movl %eax, dlugosc1

# zapytaj o druga liczbe
movl $WRITE, %eax
movl $STDOUT, %ebx
movl $komunikat3, %ecx
movl $kom3_len, %edx
int $LINUX_SYSCALL

movl $READ, %eax
movl $STDIN, %ebx
movl $liczba2, %ecx
movl $BAJTY, %edx
int $LINUX_SYSCALL

decl %eax
decl %eax
movl %eax, dlugosc2

# tu nastepuje dodanie obu liczb
# najpierw trzeba wyznaczyc ktora liczba jest dluzsza
# dlugosc tej liczby bedzie oznaczac ile razy przejdzie petla dodajaca
# kolejne znaki

movb $0, przepelnienie	# wyzeruj przepelnienie
movl dlugosc1, %edi	# sprawdzamy ktora liczba jest dluzsza...
cmpl dlugosc2, %edi	# ...od tej pory rejestr %edi bedzie wskazywal...
  jg prepare_wynik	# ...miejsce do ktorego sa wpisywane...
movl dlugosc2, %edi	# ...cyfry wyniku

prepare_wynik:
incl %edi	# zrob miejsce na ewentualne przepelnienie
movb $0x20, wynik	# wpisz spacje na poczatek wyniku
incl %edi	# zrob miejsce na znak '\n'
movb $0xa, wynik(,%edi,1) # wpisz enter do wyniku
incl %edi	# zrob miejsce na znak '\0'
movb $0x0, wynik(,%edi,1) # wpisz znak konczacy string do wyniku
decl %edi	# powroc do pierwszej cyfry
decl %edi

sumator_begin:

  movl dlugosc1, %edx	# pobierz dlugosc pierwszej liczby do rejestru
  cmpl $0, %edx
    jl liczba1koniec
  xorl %ebx, %ebx	# wyzeruj ebx    
  decl dlugosc1		# obniz dlugosc liczby o jeden
  movb liczba1(,%edx,1), %bl # pobierz ostatni znak liczby do bl

  pushl $podstawa
  pushl %ebx
  call charToInt
  addl $8, %esp
  
  jmp sumator_2
  liczba1koniec:
  xorl %eax, %eax	# koniec pierwszej liczby, eax = 0
  
  sumator_2:
  xorl %ebx, %ebx	# wyzeruj ebx
  movl dlugosc2, %edx	# pobierz dlugosc drugiej liczby do rejestru
  cmpl $0, %edx		# koniec drugiej liczby
    jl liczba2koniec	# ebx jest juz wyzerowane
  decl dlugosc2		# obniz dlugosc2 o jeden
  movb liczba2(,%edx,1), %bl # pobierz ostatni znak liczby do bl

  pushl %eax		# zachowaj wartosc eax na stosie
  
  pushl $podstawa
  pushl %ebx
  call charToInt
  addl $8, %esp
  
  movl %eax, %ebx	# skopiuj wynik funkcji do ebx
  popl %eax		# przywroc poprzednia wartosc eax

  liczba2koniec:
  # tu nalezy sprawdzic czy sumator nie powinien zakonczyc pracy
  cmpl $0, dlugosc1
    jge sumator_continue
  cmpl $0, dlugosc2
    jge sumator_continue
  cmpl $0, %eax
    jne sumator_continue
  cmpl $0, %ebx
    jne sumator_continue
  cmpl $1, przepelnienie
    je  sumator_continue
  jmp end
  
  sumator_continue:
  addl %ebx, %eax	# dodajemy wartosci rejestrow
  addb przepelnienie, %al # dodajemy ewentualne przepelnienie
  movb $0, przepelnienie # zerujemy przepelnienie
  cmpl podstawa, %eax	# jezeli wynik sumy jest mniejszy od podstawy
    jb sumator_not_overflow
  
  # else, wystapilo przepelnienie
  subl podstawa, %eax
  movb $1, przepelnienie
  
  sumator_not_overflow:
  pushl %eax
  call intToChar
  addl $4, %esp
  
  movb %al, wynik(,%edi,1)
  decl %edi

  jmp sumator_begin

end:
movl $WRITE, %eax
movl $STDOUT, %ebx
movl $wynik, %ecx
movl $BAJTY2, %edx
int $LINUX_SYSCALL

movl $EXIT, %eax
movl $0, %ebx
int $LINUX_SYSCALL

# charToInt - zamienia znak na odpowiadajaca mu wartosc
# Argumenty:
# 1. znak 	8(%ebp)
# 2. podstawa	12(%ebp)
# Dane:
# eax - zwracana wartosc liczbowa
# ebx - znak, kopia pierwszego argumentu
.type charToInt,@function
charToInt:
pushl %ebp
movl %esp, %ebp

xorl %ebx, %ebx		# zeruj ebx
movl 8(%ebp), %ebx
subb $0x30, %bl		# odejmij wartosc znaku '0' od znaku, zostaje cyfra
cmpb $10, %bl		# jezeli cyfra mniejsza od 10, przejdz na koniec
  jb charToInt_end
# else - odejmij kolejna wartosc znaku 'a' od znaku 
orb $0b0010000, %bl
subb $0x27, %bl

charToInt_end:
movl 12(%ebp), %eax	# wrzuc wartosc podstawy do eax, oznacza to bedzie ze konwersja sie nie powiodla
cmpl 12(%ebp), %ebx	# cyfra wieksza od podstawy, failura
  jae charToInt_end2

movl %ebx, %eax		# powiodla sie konwersja, przepisz ebx do eax

charToInt_end2:
movl %ebp, %esp
popl %ebp
ret

# intToChar - zamienia cyfre na odpowiadajacy jej znak
# Arugmenty:
# 1. liczba	8(%ebp)
# Dane:
# eax - liczba, kopia pierwszego argumentu
# al  -	zwracany znak
.type intToChar,@function
intToChar:
pushl %ebp
movl %esp, %ebp

movl 8(%ebp), %eax
addb $0x30, %al
cmpb $0x39, %al	# wartosc mniejsza lub rowna '9'
  jbe intToChar_end

addb $0x27, %al

intToChar_end:
movl %ebp, %esp
popl %ebp
ret


