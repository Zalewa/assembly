.equ LINUX_SYSCALL, 0x80
.equ STDIN, 0
.equ STDOUT, 1
.equ EXIT, 1
.equ WRITE, 4
.equ READ, 3
.equ MAXCYFR, 8
.equ LTMPBUFOR, MAXCYFR+2

.bss
.equ BAJTY, 1024
.equ BAJTY2, 2048
.equ LENDWORD, 4
.equ BAJT, 1
.lcomm liczba1, BAJTY
.lcomm liczba2, BAJTY
.lcomm tmpchar, BAJT
.lcomm podstawa, LENDWORD
.lcomm przepelnienie, LENDWORD
.lcomm dlugosc1, LENDWORD
.lcomm dlugosc2, LENDWORD
.lcomm wynik, BAJTY2

.lcomm bPrzepelnienie, BAJT
    
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
teksttmp:
    .skip 10, 0
    
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
  jmp wylicz_przepelnienie
wpisz_16:
  movl $0x10, %eax
  movl %eax, podstawa
  
# wyliczymy jeszcze powyzej jakiej liczby nastapi przepelnienie
# przy danej podstawie
# eax - tutaj dalej znajduje sie podstawa liczby
# ecx - licznik, rowny MAXCYFR, spada do zera
wylicz_przepelnienie:
movl $MAXCYFR, %ecx

wylicz_przepelnienie_loop:
  decl %ecx
  cmpl $0, %ecx
    je pytanie_1_liczba
  imull podstawa, %eax    
  jmp wylicz_przepelnienie_loop

pytanie_1_liczba:
movl %eax, przepelnienie 
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

decl %eax	# pozbadz sie jednego niepotrzebnego znaku z konca stringu ("\n\0")
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
movl %eax, dlugosc2

# tu nastepuje dodanie obu liczb
# najpierw trzeba wyznaczyc ktora liczba jest dluzsza
# dlugosc tej liczby bedzie oznaczac ile razy przejdzie petla dodajaca
# kolejne znaki

movb $0, bPrzepelnienie	# wyzeruj przepelnienie
movl dlugosc1, %edi	# sprawdzamy ktora liczba jest dluzsza...
cmpl dlugosc2, %edi	# ...od tej pory rejestr %edi bedzie wskazywal...
  jg prepare_wynik	# ...miejsce do ktorego sa wpisywane...
movl dlugosc2, %edi	# ...cyfry wyniku

prepare_wynik:
incl %edi		# zrob miejsce na ewentualne przepelnienie
movb $0x20, wynik	# wpisz spacje na poczatek wyniku
incl %edi		# zrob miejsce na znak '\n'
movb $0xa, wynik(,%edi,1) # wpisz enter do wyniku
incl %edi		# zrob miejsce na znak '\0'
movb $0x0, wynik(,%edi,1) # wpisz '\0' do wyniku
incl %edi
movb $0x0, wynik(,%edi,1) # wpisz drugie '\0' do wyniku
decl %edi		
decl %edi		# ustaw licznik na '\n'

sumator_begin:
  xorl %eax, %eax	# eax = 0
  movl dlugosc1, %edx	# pobierz dlugosc pierwszej liczby do rejestru
  cmpl $0, %edx
    jle sumator_2
  movb $0, liczba1(,%edx,1) # ustaw znak '\0'
  subl $8, %edx		# odejmij osiem od edx
  			# bedziemy ladowac osiem znakow do funkcji
			# i przeliczac je na liczbe
  cmpl $0, %edx		# jezeli edx jest wiekszy od zera lub rowny zero
    jge sumator_1_niezeruj
  xorl %edx, %edx
sumator_1_niezeruj:
  movl $liczba1, %ebx	# skopiuj adres do ciagu do ebx
  addl %edx, %ebx 	# dodaj do tego adresu pozycje cyfry od ktorej zaczniemy przerabiac ciag

  pushl podstawa
  pushl %ebx
  call przelicz_ciag
  addl $8, %esp
  subl $8, dlugosc1	# odejmij 8 od dlugosc1
  
sumator_2:
  pushl %eax
  xorl %ebx, %ebx	# koniec pierwszej liczby, eax = 0
  movl dlugosc2, %edx	# pobierz dlugosc pierwszej liczby do rejestru
  cmpl $0, %edx
    jle sumator_check
  movb $0, liczba2(,%edx,1) # ustaw znak '\0'
  subl $8, %edx		# odejmij osiem od edx
  			# bedziemy ladowac osiem znakow do funkcji
			# i przeliczac je na liczbe
  cmpl $0, %edx		# jezeli edx jest wiekszy od zera lub rowny zero
    jge sumator_2_niezeruj
  xorl %edx, %edx
sumator_2_niezeruj:
  movl $liczba2, %ebx	# skopiuj adres do ciagu do ebx
  addl %edx, %ebx 	# dodaj do tego adresu pozycje cyfry od ktorej zaczniemy przerabiac ciag

  pushl podstawa
  pushl %ebx
  call przelicz_ciag
  addl $8, %esp
  subl $8, dlugosc2	# odejmij 8 od dlugosc1

  movl %eax, %ebx	# skopiuj wynik funkcji do ebx
  popl %eax		# przywroc poprzednia wartosc eax

sumator_check:
  # tu nalezy sprawdzic czy sumator nie powinien zakonczyc pracy
  cmpl $0, dlugosc1
    jg sumator_continue
  cmpl $0, dlugosc2
    jg sumator_continue
  cmpl $0, %eax
    jne sumator_continue
  cmpl $0, %ebx
    jne sumator_continue
  cmpl $1, bPrzepelnienie
    je sumator_dopisz_jeden
  jmp sumator_end   

sumator_continue:
  xorl %ecx, %ecx
  addl %ebx, %eax	# dodajemy wartosci rejestrow
  jnc sumator_noflagoverflow1
  movl $1, %ecx
sumator_noflagoverflow1:
  addb bPrzepelnienie, %al # dodajemy ewentualne przepelnienie
  jnc sumator_noflagoverflow2
  movl $1, %ecx
sumator_noflagoverflow2:  
  andb $0, bPrzepelnienie # zerujemy przepelnienie
  cmpl $1, %ecx
    je sumator_overflow	# flaga przepelnienia na CPU byla ustawiona
  cmpl przepelnienie, %eax
    jl sumator_not_overflow
  
sumator_overflow:
  # else, wystapilo przepelnienie
  subl przepelnienie, %eax
  orb $1, bPrzepelnienie
sumator_not_overflow:
  subl $8, %edi		# wskaznik na wynik, odejmij 8
  cmpl $1, %edi		# jezeli edi wiekszy/rowny 1
    jge sumator_wynik_niejedynkuj 
  movl $1, %edi		# else, wpisz 1 do edi
sumator_wynik_niejedynkuj:  
  movl $wynik, %ebx
  addl %edi, %ebx
  pushl $MAXCYFR
  pushl %ebx
  pushl podstawa
  pushl %eax
  call konwertuj_liczbe
  addl $12, %esp
  
  jmp sumator_begin
sumator_dopisz_jeden:
  pushl $wynik
  pushl podstawa
  pushl $1
  call konwertuj_liczbe
  addl $12, %esp
sumator_end:


movl $WRITE, %eax
movl $STDOUT, %ebx
movl $wynik, %ecx
movl $BAJTY2, %edx
int $LINUX_SYSCALL

movl $EXIT, %eax
movl $0, %ebx
int $LINUX_SYSCALL

# Funkcja przelicz_ciag - skanuje podany ciag ascii
# przerabia go na wartosci liczbowe
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

xorl %eax, %eax
movl 8(%ebp), %ecx
xorl %ebx, %ebx		# zeruj ebx
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
# 4. ilosc zer z lewej strony 20(%ebp)
# Dane:
# 1. ebx - podstawa liczby, kopia arg2
# 2. eax - dlugosc zwracanego ciagu
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
  addl 20(%ebp), %edx	# zrob miejsce na wiodace zera
  subl %ecx, %edx	# odejmij od edx ilosc cyfr
  cmpl 16(%ebp), %edx	# jezeli adres wciaz jest wiekszy od 16(%ebp)
    jge konwertuj_3_loop
  movl 16(%ebp), %edx

  konwertuj_3_loop:
    cmpl $0, %ecx
      je konwertuj_3_zero
      
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
    movb $0x30, (%edx)

  konwertuj_3_end:
    movl 20(%ebp), %eax	# przepisz ilosc wiodacych zer
    subl -4(%ebp), %eax # odejmij od tej ilosci ilosc cyfr
    movl 16(%ebp), %edx
    konwertuj_3_zera_loop:
      cmpl $0, %eax
        jle konwertuj_end
      movb $0x30, (%edx)
      incl %edx
      jmp konwertuj_3_zera_loop

  konwertuj_end:
  addl $4, %esp
  movl %ebp, %esp
  popl %ebp
  ret
  