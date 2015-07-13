.section .data
bleep:
  .byte 0x7, 0x0
  length = .-bleep
.text
.globl _start

_start:
movl $4, %eax
movl $1, %ebx
movl $bleep, %ecx
movl $length, %edx
int $0x80

movl $1, %eax
movl $5, %ebx
int $0x80
