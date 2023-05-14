.option norvc
#Disable compressed instruction generation

.section .text.init
.global _start

_start:
  csrr t0, mhartid
  # branch to write uart to maintain minimal core usage.
  bnez t0, _wait
  j   _write_uart
  wfi

  # No Interrupts on the UART as per Qemu virt
  li t1, 0x10000001
  sb x0, 0(t1)
  # set the line control register to UART+3 for Qemu virt
  li t1, 0x10000003f
  # output will be a char (8 bits)
  li t2, 0x03 
  sb t2, 0(t1)


_write_uart:
  # Write to UART LCR
  li t1, 0x10000003
  li t2, 0x03
  sb t2, 0(t1)
  li t1, 0x10000000
  # Load 'A' via ASCII
  li t2, 65
  sb t2, 0(t1)
  

_wait:
  wfi
  