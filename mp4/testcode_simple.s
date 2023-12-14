testcode.s:
.align 4
.section .text
.globl _start
    # Refer to the RISC-V ISA Spec for the functionality of
    # the instructions in this test program.
_start:
    # Note that the comments in this file should not be taken as
    # an example of good commenting style!!  They are merely provided
    # in an effort to help you understand the assembly style.

    lui x9, 0x40000
    lw x20, test
    addi x1, x20, 0x1
    add x2, x1, x1
    sw x2, 0(x9)
    lw x4, 0(x9)
    la x16, addr3
    jalr 0(x16)
    addi x3, x4, 0x23
    slli x3, x3, 1    # X3 <= X3 << 1
addr3:
    xori x5, x2, 127  # X5 <= XOR (X2, 7b'1111111)
    jal addr2
    addi x5, x5, 1    # X5 <= X5 + 1
    addi x4, x4, 4    # X4 <= X4 + 8

addr2:
    lw x10, test
    addi x28, x10, 0x12
    addi x2, x28, 0x1
    beq x10, x0, addr1
    lw x19, test
    addi x7, x0, 0x34
    add x20, x19, x19
    addi x1, x1, 0x89
    xor x17, x10, x10
    add x8, x2, x4

addr1:
    auipc x7, 8         # X7 <= PC + 8
    lw x8, good         # X8 <= 0x600d600d
    la x10, result      # X10 <= Addr[result]
    sb x8, 0(x10)       # [Result] <= 0x600d600d
    lh x9, result       # X9 <= [Result]
    

    
       
halt:                 # Infinite loop to keep the processor
    beq x0, x0, halt  # from trying to execute the data below.
                      # Your own programs should also make use
                      # of an infinite loop at the end
.section .rodata

bad:        .word 0xdeadbeef
threshold:  .word 0x00000040
result:     .word 0x00000000
good:       .word 0x600d600d
test:       .word 0x00000069

.section ".tohost"
.globl tohost
tohost: .dword 0
.section ".fromhost"
.globl fromhost
fromhost: .dword 0