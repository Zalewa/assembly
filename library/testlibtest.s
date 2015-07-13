.equ EXIT_SUCCESS, 0
.equ EXIT, 1
.equ SYSCALL, 0x80

.text
.globl _start
_start:
movl $0, %edx
movl $1, %edx
call printnl
call move

movl $EXIT, %eax
movl $EXIT_SUCCESS, %ebx
int $SYSCALL
