.equ EXIT, 1
.equ EXIT_SUCCESS, 0

.text
.globl _start
_start:

# Wywolanie funkcji, cos w stylu eax = odejmij(8, 3)
pushl $3
pushl $8
call odejmij
addl $8, %esp 		# wywalamy dwa poprzednie pushe ze stosu

pushl $4
call silnia
addl $4, %esp

movl %eax, %ebx
movl $EXIT, %eax
int $0x80

# Funkcja odejmuje dwie liczby
# Arg. 1 - odjemna
# Arg. 2 - odjemnik
.type odejmij,@function
odejmij:
  pushl %ebp
  movl %esp, %ebp

  movl 8(%ebp), %eax	# 1. argument
  movl 12(%ebp), %ebx	# 2. argument
  subl %ebx, %eax

  movl %ebp, %esp
  popl %ebp
  ret

# Funkcja rekurencyjna
# Arg. 1 - wartosc silni
.type silnia,@function
silnia:
  pushl %ebp
  movl %esp, %ebp
  
  movl 8(%ebp), %eax

  cmpl $1, %eax
  je end_silnia
  
  # wywolanie funkcji rownoznaczne z eax = silnia(arg1 - 1)
  decl %eax
  pushl %eax
  call silnia
 
  movl 8(%ebp), %ebx 	# przywracamy poprzednia wartosc
  imull %ebx, %eax
 end_silnia:
  movl %ebp, %esp
  popl %ebp
  ret
  