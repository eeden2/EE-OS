.option norvc
#Disable compressed instruction generation

.section .data

welcome: .ascii "EE-OS\n\0"
hartdata: .ascii "HART \0"
newline: .ascii "\n\0"

_hartlock:
  .skip 1,0

_space:
  .skip 1024,0

.section .text.init
.global _start


_start:
  # make all HARTs except 0 wait (one core usage)
  csrr t0, mhartid
  bnez t0, _announce

  #Setup connection and print message
  call _setup_uart
  la a0, welcome
  call _write_uart
  j _announce
  wfi

# a0 prematurely contians address of string to print
# Write new line follows on UART
_write_new_line:
  mv s0, ra
  call _write_uart
  la a0, newline
  call _write_uart
  mv ra, s0
  ret

_setup_uart:

  # No Interrupts on the UART as per Qemu virt
  li t1, 0x10000001
  sb x0, 0(t1)
 
  # set the line control register to UART+3 for Qemu virt
  li t1, 0x10000003
 
  # output will be a char (8 bits)
  li t2, 0x03 
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

_announce:
  #First loads the address, then loads the value to that register
  #REMEMBER: Registers are Objects
  fence
  la t0, _hartlock
  lw t0, 0(t0)
  
  csrr t1, mhartid 
  bne t0, t1, _announce

  # Write msg 
  la a0, hartdata
  call _write_uart

  # x30 to Hart ID to get ASCII Number
  csrr t1, mhartid 
  li t2, 0x30
  add t1, t2, t1

  # Load Scratchpad RAM into a0
  la a0, _space
  # Store ASCII 0 into Scratchpad
  sb t1, 0(a0)
  call _write_new_line

  # Increment hart lock
  csrr t0, mhartid
  li t1, 0x01
  add t1, t0, t1
  la t2, _hartlock
  sw t1, 0(t2)

  la t0, _hartlock
  lw t1, 0(t0)
   
  fence

  j _announce


_wait:
  wfi
  