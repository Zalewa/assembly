.section .text
.globl _start

_start:
movl $1, %ebx
movl $21, %ebx
int $0x80
