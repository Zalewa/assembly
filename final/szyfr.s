# Program zamienia dowolny znak w ciagu
# z zakresu [0x20 , 0x7E] na inny znak z tegoz 
# zakresu poprzez dodanie do niego
# liczby podanej przez uzytkownika.
# Znaki z poza tego zakresu beda ignorowane.
# Algorytmy szyfrujace i odszyfrowujace
# uwzgledniaja tez mozliwosc wyjscia 
# sumy wartosci znaku i ziarna szyfru po za zakres
# 4 bajtow dostepnych w rejestrach eXx.
# Jednak konstrukcja programu nie pozwala wprowadzic
# ziarna wiekszego od 999,999,999 co jest znacznie 
# mniejsze niz maksymalna wartosc jaka mozna przechowac
# w 4 bajtach.
# Podanie ziarna bedacego wielokrotnoscia 95 rownoznaczne
# jest z podaniem zera.

.equ EXIT, 1 	# dziala tak samo jak EXIT = 1
.equ STDIN, 0
.equ STDOUT, 1
.equ READ, 3
.equ WRITE, 4
.equ MAX_CHAR, 0x7B
.equ MIN_CHAR, 0x61

.bss 		# sekcja .bss, nie zajmuje miejsca w execu
		# dzieki temu mozna zarezerwowac miejsce na tablice
.equ TEXT_LEN, 122
.lcomm text, TEXT_LEN

.equ SZYFR_LEN, 10
.lcomm szyfr, SZYFR_LEN

.equ lBYTE, 1
.lcomm roznica, lBYTE

.data
pytanie1:
  .ascii "Wpisz tekst: \0"
  pyt1_len = .-pytanie1
  
pytanie2:
  .ascii "Podaj ziarno szyfru: \0"
  pyt2_len = .-pytanie2
  
blad2:
  .ascii "Podaj liczbe!\n\0"
  blad2_len = .-blad2
  
#max_char:
#  .long 0x7F 		# znak nr 127
#min_char:
#  .long 0x20		# spacja
  
.text
.globl _start
_start:

# wyznacz roznice pomiedzy maksymalnym a minimalnym znakiem
movb $MAX_CHAR, roznica
subb $MIN_CHAR, roznica

# wiadomo - wpisz, wypisz
movl $WRITE, %eax
movl $STDOUT, %ebx
movl $pytanie1, %ecx
movl $pyt1_len, %edx
int $0x80

movl $READ, %eax
movl $STDIN, %ebx
movl $text, %ecx
movl $TEXT_LEN, %edx
int $0x80

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
# ===============================================
# TU NASTEPUJE SZYFROWANIE
# ===============================================

# al - aktualny element
# eax - zawiera sume aktualnego elementu i ziarna szyfru
# ecx - indeks aktualnego elementu
# edx - ziarno szyfru

xorl %eax, %eax		# zerujemy eax
xorl %ecx, %ecx		# zerujemy ecx

cipher_begin:
  movb text(,%ecx,1), %al 	# przesuwamy znak z bufora do al
  cmpb $0x0, %al 		# sprawdzamy czy jest on rowny "\0"
    je cipher_end		# jesli tak wychodzimy z petli
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
  movb %al, text(,%ecx,1)	# wrzucamy al spowrotem do bufora
cipher_increment:
  incl %ecx			# zwiekszamy index o jeden
  jmp cipher_begin		# powrot na poczatek petli
cipher_end:

pushl %edx

# wypisz "nowy" bufor
movl $WRITE, %eax
movl $STDOUT, %ebx
movl $text, %ecx
movl $TEXT_LEN, %edx
int $0x80

# ===============================================
# ODCYFROWANIE
# ===============================================

# al - aktualny element
# eax - zawiera sume aktualnego elementu i ziarna szyfru
# ecx - indeks aktualnego elementu
# edx - ziarno szyfru

popl %edx
xorl %eax, %eax
xorl %ecx, %ecx

decipher_begin:
  movb text(,%ecx,1), %al 	# przesuwamy znak z bufora do al
  cmpb $0x0, %al 		# sprawdzamy czy jest on rowny "\0"
    je decipher_end		# jesli tak wychodzimy z petli
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
  movb %al, text(,%ecx,1)	# wrzucamy al spowrotem do bufora
decipher_increment:
  incl %ecx			# zwiekszamy index o jeden
  jmp decipher_begin		# powrot na poczatek petli
decipher_end:

movl $WRITE, %eax
movl $STDOUT, %ebx
movl $text, %ecx
movl $TEXT_LEN, %edx
int $0x80

movl $1, %eax
movl $0, %ebx
int $0x80
