.section .data

.section .text
.globl _start

_start:
movl $1, %eax
movl $0, %ebx
#addl $5, %ebx #add
#imull $4, %ebx #multiply
int $0x80
