/*
 * lab4_3b.asm
 *
 *  Created: 2022/3/2 21:22:51
 *   Author: Administrator
 */ 
 /*
 * lab4_3a.asm
 *
 *  Created: 2022/3/2 21:22:38
 *   Author: Administrator
 */ 

.include "ATxmega128A1Udef.inc"
.include"sram_data_asm.inc"
;***********INITIALIZATIONS***************************************
.equ SRAM_START_ADDR = 0x678000			
.equ SRAM_START_ADDR_END = 0x67ffff



.org 0x1000
MAIN:
	; initializing stack
	ldi r16, 0xFF
	sts CPU_SPL, r16
	ldi r16, 0x3F
	sts CPU_SPH, r16

	rcall EBI_INIT


XY_INIT:
; Point to the SRAM_START_ADDR with X
	ldi XL, byte1(SRAM_START_ADDR)
	ldi XH, byte2(SRAM_START_ADDR)
	ldi r16, byte3(SRAM_START_ADDR)
	out CPU_RAMPX, r16

	ldi YL, byte1(SRAM_START_ADDR_END)
	ldi YH, byte2(SRAM_START_ADDR_END)
	ldi r16, byte3(SRAM_START_ADDR_END)
	out CPU_RAMPY, r16



Loop:

	;first read and then write back
	ld r16,X;read back from external sram
	ld r17,Y;read back from external sram
	ldi r17,0x0E;write some nonzero four-bit value
	st X,r16 ;store to Y ,that is write to ouput port address
	st Y,r17 ;store to Y ,that is write to ouput port address


	
	
	;go back
	rjmp Loop



EBI_INIT:

	push r16

	ldi r16,  0b01010011

	sts PORTH_OUTSET, r16

	ldi r16,  0b00000100

	sts PORTH_OUTCLR, r16

  ;ouput pin PH6(CS2),PH4(CS0),PH2(ALE),PH1(RE),PH0(WE)

	ldi r16, 0b01010111  
	sts PORTH_DIRSET, r16
	
; Initialize PORTK pins for outputs (A15-A8,A7-A0)
	ldi r16, 0xFF
	sts PORTK_DIRSET, r16

; Initialize PORTJ pins for outputs (D7-D0), because manual says so!
	ldi r16, 0xFF
	sts PORTJ_DIRSET, r16
	
; Initialize EBI_CTRL for 3-port (H, J, K) (IFMODE), ALE1 (SRMODE)
; Instead of BIT0, can use EBI_IFMODE_3PORT_gc | EBI_SRMODE_ALE1_gc 
	ldi r16, EBI_IFMODE_3PORT_gc | EBI_SRMODE_ALE1_gc 
	sts EBI_CTRL, r16

;Reserve a CS zone for our input port. The base address register  
;  is made up of 12 bits for address (A23:A12). 
;  Lower 12 bits of the address (A11-A0) are assumed to be zero. 
;    This limits our choice of the base addresses.
;Initialize low byte of the EBI CS0 base address (byte2 of address).
	ldi r16, byte2(SRAM_START_ADDR)
	sts EBI_CS0_BASEADDR, r16

;Load the highest byte (A23:16) of the 3-byte address into a 
;  register and store it as the HIGH byte of the Base Address.
;Initialize high byte of the EBI CS0 base address (byte3 of address).
	ldi r16, byte3(SRAM_START_ADDR)
	sts EBI_CS0_BASEADDR+1, r16
	
; Set to 32k CS space and turn on SRAM mode
	ldi r16, EBI_CS_ASPACE_32KB_gc | EBI_CS_MODE_SRAM_gc ; 0x15
	sts EBI_CS0_CTRLA, r16					



	pop r16
	ret


