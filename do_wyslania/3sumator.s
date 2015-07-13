# === DO POPRAWNEJ KOMPILACJI WYMAGANE JEST DOLACZENIE PLIKU bignumbers.s === 

# Program sumuje dwie dowolnie duze liczby. Wielkosci buforow to 1MB, mozna to poszerzyc
# zwiekszajac stala BUFORLEN.
# - Zasadniczo mozna podawac liczby o dowolnej podstawie. 
#   W przypadku podstaw wiekszych niz 16 funkcje big_numtostr oraz big_strtonum
#   interpretowaly by kolejne litery alfabetu jako cyfry. Limit zostal jednak
#   ograniczony do podstaw od 2 do 16.
# - Program zakonczy dzialanie z bledem jezeli uzytkownik wpisze cyfre wieksza
#   niz zadana podstawa.

.equ READ, 3
.equ WRITE, 4
.equ STDIN, 0
.equ STDOUT, 1
.equ EXIT, 1
.equ EXIT_SUCCESS, 0
.equ SYSCALL, 0x80

.bss
.equ BUFORLEN, 1024*1024
.equ BUFORELEMENTY, BUFORLEN/4
.equ LENWORD, 4
.lcomm bufor, BUFORLEN
.lcomm bufor2, BUFORLEN
.lcomm liczba1, BUFORLEN
.lcomm liczba2, BUFORLEN
.lcomm dlugosc1, LENWORD
.lcomm podstawa, LENWORD

.data
linia:
  .skip 78, '='
  .byte 0xA, 0x0
  linialen = .-linia
blad:
  .ascii "WYSTAPIL BLAD! \n\0"
  bladlen = .-blad
bladpodstawy:
  .ascii "BLAD! Prosze wpisac liczbe z podanego zakresu (2 - 16): \0"
  bladpodstawylen = .-bladpodstawy
pytanie1format:
  .ascii "Podstawa pierwszej liczby (2 - 16): "
  pytanie1formatlen = .-pytanie1format
pytanie1:
  .ascii "Podaj pierwsza liczbe: \0"
  pytanie1len = .-pytanie1
pytanie2format:
  .ascii "Podstawa drugiej liczby (2 - 16): "
  pytanie2formatlen = .-pytanie2format
pytanie2:
  .ascii "Podaj druga liczbe: \0"
  pytanie2len = .-pytanie2
pytanieWynikFormat:
  .ascii "Podaj w jakiej podstawie chcesz otrzymac wynik (2 - 16): "
  pytanieWynikFormatLen = .-pytanieWynikFormat
  

.text
.globl _start
_start:

movl $WRITE, %eax
movl $STDOUT, %ebx
movl $linia, %ecx
movl $linialen, %edx
int $SYSCALL

movl $WRITE, %eax
movl $STDOUT, %ebx
movl $pytanie1format, %ecx
movl $pytanie1formatlen, %edx
int $SYSCALL

# wywolujemy funkcje pytajaca sie o podstawe liczby
pushl $podstawa		# bufor na wynik funkcji
pushl $bufor		# bufor pomocniczy
pushl $BUFORLEN		# dlugosc bufora wejsciowego
pushl $liczba2		# bufor wejsciowy
call pytaj_podstawa
addl $16, %esp

# teraz pytamy o pierwsza liczbe
movl $WRITE, %eax
movl $STDOUT, %ebx
movl $pytanie1, %ecx
movl $pytanie1len, %edx
int $SYSCALL

movl $READ, %eax
movl $STDIN, %ebx
movl $bufor, %ecx
movl $BUFORLEN, %edx
int $SYSCALL

# ...i przerabiamy ja na wartosc liczbowa, wartosc ta bedzie przechowana
# w tablicy liczba1
pushl podstawa
pushl $liczba2		# bufor pomocniczy
pushl $BUFORELEMENTY	# ilosc elementow tablicy
pushl $liczba1		# tablica z wynikiem
pushl $bufor		# bufor ze znakami
call big_strtonum
addl $20, %esp

# sprawdzamy czy nie bylo bledu, jesli nie wpisujemy dlugosc do zmiennej
# i kontynuujemy
cmpl $-1, %eax
  je failure
  
movl %eax, dlugosc1

movl $WRITE, %eax
movl $STDOUT, %ebx
movl $pytanie2format, %ecx
movl $pytanie2formatlen, %edx
int $SYSCALL

# wywolujemy funkcje pytajaca sie o podstawe drugiej liczby
pushl $podstawa		# bufor na wynik funkcji
pushl $bufor		# bufor pomocniczy
pushl $BUFORLEN		# dlugosc bufora wejsciowego
pushl $liczba2		# bufor wejsciowy
call pytaj_podstawa
addl $16, %esp

# pytamy o druga liczbe
movl $WRITE, %eax
movl $STDOUT, %ebx
movl $pytanie2, %ecx
movl $pytanie2len, %edx
int $SYSCALL

movl $READ, %eax
movl $STDIN, %ebx
movl $bufor, %ecx
movl $BUFORLEN, %edx
int $SYSCALL

# przerabiamy ciag znakow na druga liczbe
pushl podstawa
pushl $bufor2
pushl $BUFORELEMENTY
pushl $liczba2
pushl $bufor
call big_strtonum
addl $20, %esp

# sprawdzamy tak jak dla pierwszej liczby
cmpl $-1, %eax
  je failure
  
pushl $BUFORELEMENTY
pushl $bufor
pushl %eax	# ilosc miejsc w tablicy zajetych przez druga liczbe
pushl $liczba2
pushl dlugosc1
pushl $liczba1
call big_add
addl $24, %esp

# zachowujemy dlugosc wyniku w zmiennej
movl %eax, dlugosc1

# teraz zapytamy w jakim formacie chcemy otrzymac wynik
movl $WRITE, %eax
movl $STDOUT, %ebx
movl $pytanieWynikFormat, %ecx
movl $pytanieWynikFormatLen, %edx
int $SYSCALL

pushl $podstawa		# bufor na wynik funkcji
pushl $bufor2		# bufor pomocniczy
pushl $BUFORLEN		# dlugosc bufora wejsciowego
pushl $liczba2		# bufor wejsciowy
call pytaj_podstawa
addl $16, %esp

# przerabiamy wynik na ciag znakow
pushl podstawa
pushl $BUFORLEN
pushl $bufor2
pushl dlugosc1
pushl $bufor
call big_numtostr
addl $20, %esp

# i wypisujemy
movl %eax, %edx		# dlugosc ciagu
movl $WRITE, %eax
movl $STDOUT, %ebx
movl $bufor2, %ecx
int $SYSCALL

jmp success

failure:
movl $WRITE, %eax
movl $STDOUT, %ebx
movl $blad, %ecx
movl $bladlen, %edx
int $SYSCALL

movl $EXIT, %eax
movl $1, %ebx
int $SYSCALL

success:
movl $EXIT, %eax
movl $EXIT_SUCCESS, %ebx
int $SYSCALL


# Funkcja pytaj_podstawa
# Argumenty:
# 8(%ebp) - adres bufora wejsciowego
# 12(%ebp) - wielkosc bufora wejsciowego
# 16(%ebp) - adres bufora pomocniczego
# 20(%ebp) - adres bufora wyjsciowego
.type pytaj_podstawa,@function
pytaj_podstawa:
  pushl %ebp
  movl %esp, %ebp

pytaj_podstawa_pytaj:
  # pobieramy ciag znakow z klawiatury
  movl $READ, %eax
  movl $STDIN, %ebx
  movl 8(%ebp), %ecx
  movl 12(%ebp), %edx
  int $SYSCALL

  # przerabiamy ten ciag znakow na liczbe 32-bitowa
  pushl $10
  pushl 16(%ebp)
  pushl $1
  pushl 20(%ebp)
  pushl 8(%ebp)
  call big_strtonum
  addl $20, %esp

  # sprawdzamy czy wpisano poprawna liczbe
  # jezeli nie - wypisujemy blad i powracamy na poczatek funkcji
  cmpl $-1, %eax
    je pytaj_podstawa_blad
  movl 20(%ebp), %esi
  movl (%esi), %eax
  cmpl $16, %eax
    ja pytaj_podstawa_blad
  cmpl $2, %eax
    jb pytaj_podstawa_blad

  movl %ebp, %esp
  popl %ebp
  ret  
pytaj_podstawa_blad:
  movl $WRITE, %eax
  movl $STDOUT, %ebx
  movl $bladpodstawy, %ecx
  movl $bladpodstawylen, %edx
  int $SYSCALL
  jmp pytaj_podstawa_pytaj


