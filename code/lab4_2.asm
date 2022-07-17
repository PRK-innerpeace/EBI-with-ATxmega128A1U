/* Input_Port.asm
 *
 * Modified: 1 Mar 2022
 * Authors:  
 *
 * This is the minimum code required to setup an input port with
 * address decoding utilizing the CS of the XMEGA. This solution
 * assumes the user is providing their own output enable, OE(L), 
 * to the input port's tri-state buffer chip using CS2(L) and RE(L), 
 * i.e., OE (from PLD to tri-state buffer) = f(CS2,RE).
 */
.include "ATxmega128A1Udef.inc"
;***********INITIALIZATIONS***************************************
.equ IN_PORT = 0xC84000			
.equ IN_PORT_END = 0xC8401F

.org 0x0000	
	rjmp MAIN

.org 0x200
MAIN:

	; initializing stack
	ldi r16, 0xFF
	sts CPU_SPL, r16
	ldi r16, 0x3F
	sts CPU_SPH, r16

	rcall EBI_INIT

; Point to the IN_PORT with X
	ldi XL, byte1(IN_PORT)
	ldi XH, byte2(IN_PORT)
	ldi r16, byte3(IN_PORT)
	sts CPU_RAMPX, r16

; Repeatedly read the input port and output to LED
TEST:
	ld r16, X ;ld instruction just load data from data memory space to register16
	st X,r16  ;Stores one byte indirect from a register to data space.
	rjmp TEST


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
	ldi r16, byte2(IN_PORT)
	sts EBI_CS2_BASEADDR, r16

;Load the highest byte (A23:16) of the 3-byte address into a 
;  register and store it as the HIGH byte of the Base Address.
;Initialize high byte of the EBI CS0 base address (byte3 of address).
	ldi r16, byte3(IN_PORT)
	sts EBI_CS2_BASEADDR+1, r16
	
; Set to 256 CS space and turn on SRAM mode, 0xC84000-0xC8401F
	ldi r16, EBI_CS_ASPACE_256B_gc | EBI_CS_MODE_SRAM_gc ; 0x15
	sts EBI_CS2_CTRLA, r16					

	pop r16
	ret