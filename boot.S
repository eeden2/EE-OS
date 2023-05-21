.option norvc
#Disable compressed instruction generation

.section .data

welcome: .ascii "EE-OS\n\0"
hartdata: .ascii "HART \0"
interrupts_state: .ascii "Interrupts Status: "
machinemode: .ascii "Mode: Machine\0"
newline: .ascii "\n\0"


_hartlock:
  .skip 8,0

_space:
  .skip 1024,0

_stack:
  .skip 8192, 0


.section .text.init
.global _start


_start:
  # make all HARTs except 0 wait (one core usage)
  csrr t0, mhartid

  # Setup stack for HARTS
  la t1, _stack
  li t2, 1024
  mul t3, t2, t0
  add sp, t3, s1

  bnez t0, _announce


  #Setup connection and print message
  call _setup_uart
  la a0, welcome
  call _write_uart

  call _scheck

  j _announce
  wfi

.macro push
  sd ra, 0(sp)
  li t0, 8
  add sp, sp, t0
.endm

.macro pop
  li t0, -8
  add sp, sp, t0
  ld ra, 0(sp)
.endm

_scheck:
  push
  csrr t0, mstatus
  li t1, 0xC00
  and t0,t1,t2
  beq t1, t2, _scheck_interrupt
  la a0, machinemode
  call _write_new_line

_scheck_interrupt:
  csrr t0, mstatus
  li t1,0x8
  and t0, t1, t2
  la a0, interrupts_state
  call _write_uart
  
  li t3, 0x30
  srai t2, t2, 3
  add t1, t3, t2
  li t1, 0x30
  # Load Scratchpad RAM into a0
  la a0, _space
  # Store ASCII 0 into Scratchpad
  sb t1, 0(a0)
  call _write_new_line

_scheck_e:
  pop
  ret

# a0 prematurely contians address of string to print
# Write new line follows on UART
_write_new_line:
  push
  call _write_uart
  la a0, newline
  call _write_uart
  pop
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
  li t1, 0x10000005
_write_uart_loop:
  # Load .ascii string
  lb t2, 0(a0)
  li t3, 0x30
  and t2,t3,t1
  beqz t1, _write_uart_loop
  li t1, 0x10000000
  lb t2, 0(a0)
  beqz t2, _write_uart_end
  sb t2, 0(t1)
  
  # li t2, 1 (COME BACK IF ERROR)
  addi a0, a0, 1 
  j _write_uart_loop
  
_write_uart_end:
  pop
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
  