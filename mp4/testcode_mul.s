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

    # RISC-V Assembly Test Code for M Extension

.section .text
.globl _start

_start:
    # Initialize values
    lw x1, test_1         
    lw x2, test_2         
    lw x3, test_3 
    lw x4, test_4
    lw x6, test_6
    lw x7, test_7
    lw x20, test_20
    lw x21, test_21

    mul x8, x1, x2
    
    # MULH
    mulh x9, x2, x3
    
    # MULHSU - Multiply high (signed-unsigned)
    mulhsu x11, x4, x3
    
    # MULHU - Multiply high (unsigned)
    mulhu x12, x3, x2

    mul x12, x1, x2

    addi x25, x12, 0x0
    add x26, x12, x25
    add x27, x12, x26

    # # DIV - Divide
    div x14, x20, x21
    rem x15, x20, x21
    mulhu x20, x14, x15
    mulh x20, x14, x15
    divu x28, x15, x14
    mulhsu x29, x14, x15


    lui x7, 0x10000
    lw x20, test_1
    lw x20, test_20
    div x15, x20, x21
    sw x15, 0(x7)
    # # DIVU - Divide unsigned
    divu x16, x6, x7
    remu x17, x6, x7
    add x23, x16, x17

    lui x1, 0
    divu x4, x20, x1


halt:                 # Infinite loop to keep the processor
    beq x0, x0, halt  # from trying to execute the data below.
                      # Your own programs should also make use
                      # of an infinite loop at the end
.section .rodata

bad:        .word 0xdeadbeef
threshold:  .word 0x00000040
result:     .word 0x00000000
good:       .word 0x600d600d
test_1:     .word 0x00000069
test_2:     .word 0x00000002
test_3:     .word 0x0f0f0f0f
test_4:     .word 0xffffffff
test_6:     .word 0x0000000f
test_7:     .word 0x00000004
test_20:    .word 0xfffffff1    # -15
test_21:    .word 0xfffffffb    # -5
.section ".tohost"
.globl tohost
tohost: .dword 0
.section ".fromhost"
.globl fromhost
fromhost: .dword 0
