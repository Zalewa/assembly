# Program szyfruje tekst podany z pliku
# Parametry programu:
# - W przypadku nie podania zadnego parametru jako plik wejscia
#   uzyty zostanie plik "szyfr_file_input" a jako plik wyjscia
#   plik "szyfr_file_output"
# - W przypadku podania jednego parametru nazwa pliku wejscia bedzie
#   taka jak podana w parametrze a pliku wyjscia jak w przypadku powyzej
# - W przypadku podania dwoch parametrow nazwy pliku wejscia oraz pliku wyjscia
#   zostana odczytane z parametrow
.equ EXIT, 1 	
.equ STDIN, 0
.equ STDOUT, 1
.equ READ, 3
.equ WRITE, 4
.equ OPEN, 5
.equ CLOSE, 6
.equ SYSCALL, 0x80
.equ MAX_CHAR, 0x7B
.equ MIN_CHAR, 0x61

.bss 		
.equ BUFORLEN, 512
.lcomm bufor, BUFORLEN

.equ SZYFR_LEN, 10
.lcomm szyfr, SZYFR_LEN

.equ lBYTE, 1
.lcomm roznica, lBYTE

.equ LDWORD, 4
.lcomm inameaddr, LDWORD
.lcomm onameaddr, LDWORD
.lcomm file1, LDWORD
.lcomm file2, LDWORD
.lcomm ziarno, LDWORD
.lcomm readsize, LDWORD

.data
file_input:
  .ascii "szyfr_file_input\0"

file_output:
  .ascii "szyfr_file_output\0"  

pytanie2:
  .ascii "Podaj ziarno szyfru: \0"
  pyt2_len = .-pytanie2
  
blad2:
  .ascii "Podaj liczbe!\n\0"
  blad2_len = .-blad2
  
  
.text
.globl _start
_start:

# inicjalizujemy wskazniki
movl %esp, %ebp
movl $file_input, %eax
movl %eax, inameaddr
movl $file_output, %eax
movl %eax, onameaddr

cmpl $2, (%esp) 	# sprawdzamy czy liczba parametrow rowna/wieksza 2
  jb program

# uaktualniamy wskaznik do nazwy pliku wejsciowego
# tak aby wskazywal na ciag podany jako argument
movl 8(%esp), %ecx
movl %ecx, inameaddr

cmpl $3, (%esp)		# sprawdzamy czy liczba parametrow rowna/wieksza 3
  jb program

# uaktualniamy wskaznik do nazwy pliku wyjsciowego
# tak aby wskazywal na ciag podany jako argument
movl 12(%esp), %ecx
movl %ecx, onameaddr

program:
# wyznacz roznice pomiedzy maksymalnym a minimalnym znakiem
movb $MAX_CHAR, roznica
subb $MIN_CHAR, roznica

# pytamy o ziarno szyfru
ask_szyfr:
movl $WRITE, %eax
movl $STDOUT, %ebx
movl $pytanie2, %ecx
movl $pyt2_len, %edx
int $0x80

movl $READ, %eax
movl $STDIN, %ebx
movl $szyfr, %ecx
movl $SZYFR_LEN, %edx
int $0x80

movl $0, %ecx
movl %eax, %edx			# w eax mamy ilosc wpisanych znakow, przepisujemy do edx
subl $2, %edx			# obnizamy o 2 pomijajac znak "\0"
				# oraz biorac pod uwage fakt, ze
				# index zaczyna sie od zera

# =======================================================
# KONWERSJA ZIARNA SZYFRU PODANEGO Z KLAWIATURY NA LICZBE
# (ascii to long)
# =======================================================

# eax - ziarno szyfru
# bl - aktualny element
# ecx - indeks aktualnego elementu
# edx - dlugosc podanego szyfru

xorl %eax, %eax
loop_szyfr:
  xorl %ebx, %ebx		# zerujemy eax, just in case
  movb szyfr(,%ecx,1), %bl 	# przesuwamy znak z bufora do al
  cmpb $0x30, %bl		# sprawdzamy czy jest mniejszy od "0"
    jl bad_szyfr		# jesli tak wywalamy blad
  cmpb $0x39, %bl		# sprawdzamy czy jest wiekszy od "9"
    jg bad_szyfr		# jesli tak wywalamy blad
  subb $0x30, %bl		# odejmujemy wartosc ASCII, 
				# tak zeby zostala nam sama cyfra
  addl %ebx, %eax		# schemat Hornera
  cmpl %ecx, %edx		# sprawdzamy czy natrafiono na ostatnia cyfre
    je end_szyfr		# koniec petli
  imull $10, %eax		# schemat Hornera
  incl %ecx			# zwiekszamy index o jeden
  jmp loop_szyfr		# powrot na poczatek petli
    
bad_szyfr:
  movl $WRITE, %eax
  movl $STDOUT, %ebx
  movl $blad2, %ecx
  movl $blad2_len, %edx
  int $0x80
  jmp ask_szyfr			# wracamy na poczatek

end_szyfr:

# ===============================================
# Wyciagamy modulo z ziarna szyfru
# dzieki temu zabiegowi ziarno nigdy nie bedzie
# wieksze niz roznica max_znaku i min_znaku
# ===============================================
# eax - ziarno szyfru
xorl %edx, %edx
divl roznica
movl %edx, ziarno

# otwieramy plik do odczytu
movl $OPEN, %eax
movl inameaddr, %ebx
movl $0, %ecx
movl $0666, %edx
int $SYSCALL
movl %eax, file1

# otwieramy plik do zapisu
movl $OPEN, %eax
movl onameaddr, %ebx
movl $03101, %ecx
movl $0666, %edx
int $SYSCALL
movl %eax, file2

# petla read
read:
# czytamy BUFORLEN bajtow z pliku
movl $READ, %eax
movl file1, %ebx
movl $bufor, %ecx
movl $BUFORLEN, %edx
int $SYSCALL

cmpl $0, %eax	# sprawdzamy czy nie natrafiono na EOF
  jle quit 
movl %eax, readsize	# ilosc przeczytanych bajtow do zmiennej

# uruchamiamy funkcje szyfrujaca
pushl ziarno
pushl %eax
pushl $bufor
call cipher
addl $12, %esp

# zapisujemy zaszyfrowany bufor do pliku wyjsciowego
movl $WRITE, %eax
movl file2, %ebx
movl $bufor, %ecx
movl readsize, %edx
int $SYSCALL
jmp read

quit:
# zamykamy oba pliki
movl $CLOSE, %eax
movl file1, %ebx
int $SYSCALL
movl $CLOSE, %eax
movl file2, %ebx
int $SYSCALL

movl $EXIT, %eax
movl $0, %ebx
int $SYSCALL

# Funkcja cipher
# 8(%ebp)	- adres do bufora
# 12(%ebp)	- dlugosc bufora
# 16(%ebp)	- ziarno szyfru
.type cipher,@function
cipher:
pushl %ebp
movl %esp, %ebp
# al - aktualny element
# eax - zawiera sume aktualnego elementu i ziarna szyfru
# ecx - indeks aktualnego elementu
# edx - ziarno szyfru

movl 8(%ebp), %esi
movl 16(%ebp), %edx

xorl %eax, %eax		# zerujemy eax
xorl %ecx, %ecx		# zerujemy ecx

cipher_begin:
  movb (%esi), %al 		# przesuwamy znak z bufora do al
  orb $0b00100000, %al		# zamieniamy litere na mala
  cmpb $MIN_CHAR, %al		# sprawdzamy czy jest mniejszy od znaku minimalnego
    jl cipher_increment		# jesli tak przechodzimy do nastepnego znaku
  cmpb $MAX_CHAR, %al		# sprawdzamy czy znak jest wiekszy lub rowny znakowi maksymalnemu
    jge cipher_increment
  subb $MIN_CHAR, %al		# odejmujemy minimalny znak od wartosci znaku
  addb %dl, %al			# dodajemy ziarno do wartosci znaku
  cmpb roznica, %al		# wynik miesci sie w granicy
    jl cipher_move
  subb roznica, %al		# jezeli nie miesci sie
cipher_move:
  addb $MIN_CHAR, %al		# dodajemy spowrotem minimalny znak do wartosci znaku
  movb %al, (%esi)		# wrzucamy al spowrotem do bufora
cipher_increment:
  incl %ecx			# zwiekszamy index o jeden
  cmpl %ecx, 12(%ebp)
    je cipher_end
  incl %esi			# zwiekszamy adres o jeden
  jmp cipher_begin		# powrot na poczatek petli
cipher_end:

movl %ebp, %esp
popl %ebp
ret

# ===============================================
# ODCYFROWANIE
# ===============================================

# Funkcja decipher
# 8(%ebp)	- adres do bufora
# 12(%ebp)	- dlugosc bufora
# 16(%ebp)	- ziarno szyfru
.type decipher,@function
decipher:
pushl %ebp
movl %esp, %ebp

# al - aktualny element
# eax - zawiera sume aktualnego elementu i ziarna szyfru
# ecx - indeks aktualnego elementu
# edx - ziarno szyfru

movl 8(%ebp), %esi
movl 16(%ebp), %edx
xorl %eax, %eax
xorl %ecx, %ecx

decipher_begin:
  movb (%esi), %al 	# przesuwamy znak z bufora do al
  cmpb $MIN_CHAR, %al		# sprawdzamy czy jest mniejszy od znaku minimalnego
    jl decipher_increment	# jesli tak przechodzimy do nastepnego znaku
  cmpb $MAX_CHAR, %al		# sprawdzamy czy znak jest wiekszy lub rowny znakowi maksymalnemu
    jge decipher_increment
  subb $MIN_CHAR, %al		# odejmujemy minimalna wartosc znaku
  subb %dl, %al			# odejmujemy ziarno od wartosci w al
  cmpb $0, %al			# al wieksze/rowne 0
    jge	decipher_move
  addb roznica, %al
decipher_move:
  addb $MIN_CHAR, %al
  movb %al, (%esi)		# wrzucamy al spowrotem do bufora
decipher_increment:
  incl %ecx			# zwiekszamy index o jeden
  cmpl %ecx, 12(%ebp)
    je decipher_end
  incl %esi
  jmp decipher_begin		# powrot na poczatek petli
decipher_end:

movl %ebp, %esp
popl %ebp
ret

