.equ STDIN, 0
.equ STDOUT, 1
.equ READ, 3
.equ WRITE, 4
.equ EXIT, 1
.equ EXIT_SUCCESS, 0
.equ SYSCALL, 0x80

.bss
.equ LBUFOR, 1048576
.equ LWYNIK, 32
.equ LDWORD, 4
.lcomm bufor, LBUFOR
.lcomm wynik, LWYNIK
.lcomm reszta, LWYNIK
.lcomm reszta2, LDWORD
.lcomm elementy, LDWORD

.data
long1: .long 1,20,30
long2: .long 0,20,30,0

long3: .long 0xffffffff, 0xffffffff, 0xffffffff
long4: .long 0xffffffff, 0xffffffff, 0xffffffff

long5: .long 0xffffffff, 0xffffffff, 0xfffffffe
long6: .long 0xfffffffe, 0xfffffffe, 0xffffffff

long7: .long 499997
long8: .long 111111
.equ LLONG7, 1
.equ LLONG8, 1

long9: .long 1, 2, 3, 4, 5, 6
long10: .long 0, 0, 0, 0, 0
.equ LLONG9, 5

long11: .long 0xffffffff, 0xffffffff, 0xffffffff
long12: .long 0
.equ LLONG11, 3
.equ LLONG12, 1

long13: .long 123456789, 0
.equ LLONG13, 2

.text
.globl _start
_start:

xorl %edx, %edx
movl $LWYNIK, %eax
movl $4, %ebx
idivl %ebx
movl %eax, elementy

pushl $4
pushl $long2
pushl $3
pushl $long1
call big_compare
addl $16, %esp

pushl elementy
pushl $wynik
pushl $3
pushl $long3
pushl $3
pushl $long4
call big_add
addl $24, %esp

movl $0, %edi
zeruj_wynik:
  movl $0, wynik(,%edi,4)
  incl %edi
  cmpl elementy, %edi
    jb zeruj_wynik 

pushl elementy
pushl $wynik
pushl $3
pushl $long6
pushl $3
pushl $long5
call big_sub
addl $24, %esp

movl $0, %edi
zeruj_wynik2:
  movl $0, wynik(,%edi,4)
  incl %edi
  cmpl elementy, %edi
    jb zeruj_wynik2 

movl elementy, %edi
decl %edi
movl $20, wynik(,%edi,4)
pushl elementy
pushl $wynik
pushl $LLONG7
pushl $long7
pushl $LLONG8
pushl $long8
call big_mull
addl $24, %esp

pushl $long10
pushl $LLONG9
pushl $long9
call big_mov
addl $12, %esp

movl $0, %edi
zeruj_wynik3:
  movl $0, wynik(,%edi,4)
  incl %edi
  cmpl elementy, %edi
    jb zeruj_wynik3

# powinno zwrocic blad bo long12 to zero
pushl elementy
pushl $reszta
pushl elementy
pushl $wynik
pushl $LLONG12
pushl $long12
pushl $LLONG11
pushl $long11
call big_div
addl $32, %esp

pushl $reszta2
pushl elementy
pushl $wynik
pushl $10
pushl $LLONG11
pushl $long11
call big_div2
addl $24, %esp

pushl $10
pushl $LBUFOR
pushl $bufor
pushl $LLONG13
pushl $long13
call big_numtostr
addl $16, %esp

movl %eax, %edx
movl $WRITE, %eax
movl $STDOUT, %ebx
movl $bufor, %ecx
int $SYSCALL

movl $READ, %eax
movl $STDIN, %ebx
movl $bufor, %ecx
movl $LBUFOR, %edx
int $SYSCALL

pushl $10
pushl $reszta
pushl elementy
pushl $wynik
pushl $bufor
call big_strtonum
addl $16, %esp

movl %eax, %ebx
movl $EXIT, %eax
#movl $EXIT_SUCCESS, %ebx
int $SYSCALL
