.equ READ, 3
.equ WRITE, 4
.equ STDIN, 0
.equ STDOUT, 1
.equ SYSCALL, 0x80

.data
newline:
  .ascii "BBB\n\0"
  newlinelen = .-newline


.text
.globl printnl
.type printnl,@function
printnl:
  movl $WRITE, %eax
  movl $STDOUT, %ebx
  movl $newline, %ecx
  movl $newlinelen, %edx
  int $SYSCALL
  ret

.globl move
.type move,@function
move:
  movl %edx, %eax
  ret
  