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
.equ LICZBA, 33
.lcomm tekst, LICZBA

.equ ZNAK, 3
.lcomm cznak, ZNAK

.data
powitanie:
  .ascii "Konwerter liczb.\nSchemat wprowadzania:\n- 1234 dla liczb dzesietnych\n- ?!1234AB dla liczb o innej podstawie, gdzie:\n  ? - dowolny znak\n  ! - b = 2, o = 8, x = 16\nWprowadz teraz liczbe:\0"
  powitanie_len = .-powitanie
  
pytanie:
  .ascii "Teraz wybierz na jaki format chcesz przekonwertowac liczbe:\nb - binarny, o - osemkowy, d - dziesietny, x - szesnastkowy\n\0"
  pytanie_len = .-pytanie
  
failura:
  .ascii "Podano zly format wyjsciowy!\n\0"
  failura_len = .-failura
  
.text
.globl _start
_start:
movl $WRITE, %eax
movl $STDOUT, %ebx
movl $powitanie, %ecx
movl $powitanie_len, %edx
int $0x80

movl $READ, %eax
movl $STDIN, %ebx
movl $tekst, %ecx
movl $LICZBA, %edx
int $0x80

decl %eax	# usuwamy '\n' z konca

# konwertujemy ciag na liczbe
pushl %eax	# tu znajduje sie dlugosc ciagu
pushl $tekst
call przelicz_ciag
addl $8, %esp

pushl %eax	# odkladamy wartosc liczbowa na stos
# wyrzucamy zapytanie o format wyjsciowy
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

# konwertujemy liczbe na ciag
popl %eax	# przywracamy liczbe ze stosu
pushl $tekst
pushl $cznak
pushl %eax	# w tym miejscu przekazujemy liczbe jako argument do funkcji
call konwertuj_liczbe
addl $12, %esp

cmpl $0, %eax	# sprawdzamy czy konwertuj_liczbe sie NIE udalo
  je program_failure
jmp program_success

program_failure:
movl $WRITE, %eax
movl $STDOUT, %ebx
movl $failura, %ecx
movl $failura_len, %edx	
int $0x80
jmp program_end

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


# Funkcja strlen, idea ta sama co w C
# UWAGA! Policzy wszystkie znaki po za '\0', nawet
# znajdujacy sie na koncu enter
# tak wiec ciag ktory wprowadzimy z klawiatury jako
# "abc" bedzie mial w istocie dlugosc cztery
# Argumenty:
#   1 - adres do ciagu
# Zmienne:
#   (po znaku rownosci - czym zmienne/rejestry sa inicjalizowane)
#   eax - dlugosc ciagu = 0
#   ecx - adres do konkretnego znaku
# Dzialanie:
#   Przejedz ciag znak po znaku az do natrafienia '\0'
#.type strlen,@function
#strlen:
#  pushl %ebp
#  movl %esp, %ebp

#  movl $0, %eax
#  movl 8(%ebp), %ecx
# bl - przechowuje w danym momencie dany znak
#  strlen_begin_loop:
#  movb (%ecx), %bl	# przesun znak pod adresem ecx do bl
#  cmpb $0x0, %bl
#    je strlen_end_loop
#  incl %eax		# zwieksz wartosc zwracana
#  incl %ecx		# zwieksz adres
#  jmp strlen_begin_loop
#  strlen_end_loop:

#  movl %ebp, %esp
#  popl %ebp
#  ret

# Funkcja przelicz_ciag - skanuje podany ciag ascii
# i przelicza na wartosc liczbowa
# Argumenty:
#    1 - adres do ciagu
#    2 - dlugosc ciagu
# Zmienne:
#    (po znaku rownosci - czym zmienne/rejestry sa inicjalizowane)
#    eax - wartosc zwracana = 0
#    ecx - wskaznik do znaku = arg1
#    edx - aktualny znak = 1
#    -4(%ebp) - podstawa liczby
# Kolejnosc wykonywanych dzialan:
# 1. Sprawdzamy czy znak to null lub enter
#    jesli tak - return eax
# 2. Jezeli dlugosc rowna sie 1 ustawiamy
#    system dziesietny i przechodzimy do pkt. 5.
# 3. Sprawdzamy czy drugi znak rowna sie:
#    a) b - liczba binarna
#    b) h - liczba szesnastkowa
#    c) o - liczba osemkowa
#    d) dowolny inny znak - liczba dziesietna
#    Przy okazji sprawdzamy czy liczba jest w stanie
#    zmiescic sie w 4 bajtach
# 4. Przerabiamy ciag na liczbe. Jezeli pojawi
#    sie znak nie bedacy cyfra - eax = 0

.type przelicz_ciag,@function
przelicz_ciag:
  pushl %ebp
  movl %esp, %ebp
  subl $4, %esp		# tworzymy miejsce na zmienna lokalna
  
  movl $0, %eax
  movl 8(%ebp), %ecx  	# przesuwamy pierwszy argument
			# (adres do ciagu) do ecx
  
# 1.
# bl  - wartosc znaku
  movl $0, %ebx
  movb (%ecx), %bl
  cmpb $0x0, %bl
    je przelicz_ciag_end
  cmpb $0xA, %bl
    je przelicz_ciag_end
# 2.
  cmpb $1, 12(%ebp)	# jezeli dlugosc ciagu == 1
    je przelicz_dzies	# to podano liczbe w formacie dziesietnym
# 3.
# bl  - wartosc znaku
  incl %ecx
  movl $0, %ebx
  movb (%ecx), %bl
  orb  $0b00100000, %bl	# zamieniamy znak w %bl na mala litere
  cmpb $0x62, %bl	# %bl == 'b'
    je przelicz_binary
  cmpb $0x6F, %bl 	# %bl == 'h'
    je przelicz_octal
  cmpb $0x78, %bl	# %bl == 'x'
    je przelicz_hex
  # else - prawdopodobnie liczba dziesietna
  # lub natrafiono na jakas bzdure :P
  # bzdura wyjdzie w punkcie czwartym
  przelicz_dzies:
  movl $1, %edx
  movl $10, -4(%ebp)	# zapisujemy podstawe systemu
  movl 8(%ebp), %ecx	# powracamy do pierwszej cyfry
  jmp przelicz_3_end

  przelicz_binary:
    movl $2, -4(%ebp)
    jmp przelicz_3_inc
  przelicz_octal:
    movl $8, -4(%ebp)
    jmp przelicz_3_inc
  przelicz_hex:
    movl $16, -4(%ebp)
  
  przelicz_3_inc:        
    movl $3, %edx
    incl %ecx	# przeskakujemy do 3. znaku
  przelicz_3_end:
# 4.
# bl - wartosc znaku
  przelicz_loop_begin:
    movl $0, %ebx
    movb (%ecx), %bl
  
    # Teraz nalezy sprawdzic czy cyfra nalezy do podanej podstawy liczby
    # z cyframi 0 - 9 nie ma problemu, wystarczy odjac wartosc $0x30 i
    # porownac czy nie jest wieksza albo mniejsza od wartosci przedzialu.
    # Z cyframi A - F jest wiekszy problem. Usuniemy go poprzez zamiane
    # znaku cyfry na mala litere i odjecie od niej $0x27 (= 0x61 - 0x30 - (0x31 - 0xA))
  
    subb $0x30, %bl  
    cmpl -4(%ebp), %ebx  
      jge przelicz_ciag_loop_16  
    cmpl $0, %ebx
      jl przelicz_ciag_failure  
    jmp przelicz_ciag_loop_Horner
    przelicz_ciag_loop_16:
      orb $0b00100000, %bl
      subb $0x27, %bl
      cmpl -4(%ebp), %ebx
        jge przelicz_ciag_failure
      cmpl $10, %ebx
        jl przelicz_ciag_failure
      jmp przelicz_ciag_loop_Horner	
    przelicz_ciag_loop_Horner:
      addl %ebx, %eax		# dodaj wartosc cyfry do wartosci liczby
      cmpl 12(%ebp), %edx
        je przelicz_loop_end
      imull -4(%ebp), %eax 	# podstawa systemu razy wartosc liczby
      incl %ecx
      incl %edx
      jmp przelicz_loop_begin
    przelicz_ciag_failure:
      movl $0, %eax    
  przelicz_loop_end:

  przelicz_ciag_end:  
  
  addl $4, %esp		# usun zmienna lokalna
  movl %ebp, %esp
  popl %ebp  
  ret

# Funkcja konwertuj_liczbe - przepisuje liczbe
# do tablicy znakow w podanym formacie
# Argumenty:
#   1 - liczba
#   2 - adres do formatu wyjsciowego
#       liczy sie tylko pierwszy znak:
#       (b - binarny, o - osemkowy, d - dziesietny, x - hex)
#   3 - adres do ciagu
# Zmienne:
#   eax - w razie porazki ustawione na 0, w innym przypadku zwraca dlugosc ciagu
#   ebx - podstawa systemu
#   -4(%ebp) - tu przechowujemy ilosc cyfr
# Kolejnosc wykonywanych dzialan:
#   1. Wyznaczamy podstawe liczby, jezeli podano zly 
#      znak w 2 argumencie - opusc funkcje
#   2. Dzielimy liczbe przez podstawe, odkladamy reszte na stos
#      powtarzamy az do uzyskania zera
#   3. Pobieramy reszty ze stosu, zamieniamy je 
#      na odpowiadajace im znaki.
.type konwertuj_liczbe,@function
konwertuj_liczbe:
  pushl %ebp
  movl %esp, %ebp
  subl $4, %esp

# 1. 
# ebx - najpierw adres do formatu wyjsciowego, potem jak w opisie
# cl - wartosc znaku
  movl $0, %ecx
  movl 12(%ebp), %ebx	# przepisujemy adres zmiennej tekstowej do ebx
  movb (%ebx), %cl 	# przepisujemy zawartosc znajdujaca sie pod danym adresem do cl
  orb  $0b00100000, %cl # konwertujemy literke na mala
  cmpb $0x62, %cl	# b
    je konwertuj_binary
  cmpb $0x64, %cl   # d
    je konwertuj_decimal
  cmpb $0x6F, %cl  # o
    je konwertuj_octal
  cmpb $0x78, %cl  # x
    je konwertuj_hex
  
  movl $0, %eax		# zwroc zero  
  jmp konwertuj_end
  
  konwertuj_binary:
    movl $0b10, %ebx
    jmp konwertuj_end_1
  konwertuj_decimal:
    movl $10, %ebx
    jmp konwertuj_end_1    
  konwertuj_octal:
    movl $010, %ebx
    jmp konwertuj_end_1    
  konwertuj_hex:
    movl $0x10, %ebx

  konwertuj_end_1:
  movl $0, %eax
# 2.
# eax - wynik dzielenia
# ecx - ilosc cyfr
# edx - reszta z dzielenia
  movl 8(%ebp), %eax
  movl $0, %ecx
  konwertuj_2_loop:
  cmpl $0, %eax		# eax == 0, zakoncz
    je konwertuj_2_loop_end  

  incl %ecx	# powieksz ilosc cyfr o jeden
  movl $0, %edx	# wyzeruj edx (potrzebne przy dzieleniu)
  idivl %ebx	# podziel edx:eax przez ebx, reszta dzielenia jest w edx, wynik w eax
  pushl %edx	# odloz edx na stos
  jmp konwertuj_2_loop	# powtarzaj dopoki eax == 0
  konwertuj_2_loop_end:
  movl %ecx, -4(%ebp)
# 3.
# eax - aktualna wartosc
# ecx - ilosc cyfr (ma wartosc z poprzedniego podpunktu)
# edx - adres aktualnego znaku
  movl 16(%ebp), %edx  # przepisz adres bufora do edx

  cmpl $0, %ecx		# sprawdz ile jest cyfr
    je konwertuj_3_zero # warunek sie "uda" takze gdy liczba 
			# podana w argumencie 1. == 0
			# co wynika z dzialania podpunktu 2
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
  