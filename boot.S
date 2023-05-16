.option norvc
#Disable compressed instruction generation

.section .data

welcome: .ascii "EE-OS\n\0"

.section .text.init
.global _start


_start:
  csrr t0, mhartid
  # branch to write uart to maintain minimal core usage.
  bnez t0, _wait
  call _setup_uart
  la a0, welcome
  call _write_uart
  wfi

_setup_uart:

  # No Interrupts on the UART as per Qemu virt
  li t1, 0x10000001
  sb x0, 0(t1)
  # set the line control register to UART+3 for Qemu virt
  li t1, 0x10000003
  # output will be a char (8 bits)
  li t2, 0x03 
  sb t2, 0(t1)
  ret


_write_uart:
  # Essentially, this is the eqv. of cout<<
  li t1, 0x10000000
  # Load .ascii string
  lb t2, 0(a0)
  beqz t2, _write_uart_end
  sb t2, 0(t1)
  # li t2, 1 (COME BACK IF ERROR)
  addi a0, a0, 1 
  j _write_uart
  

_write_uart_end:
  ret

_wait:
  wfi
  