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

.equ IN_PORT = 0xC84000	

.equ F_CPU=2000000
.equ CLK_PRE=8
.equ Daoshu_time=4;=1/per 250 ms,
.equ EOT=0

.cseg

.org 0x1000
MAIN:
	; initializing stack
	ldi r16, 0xFF
	sts CPU_SPL, r16
	ldi r16, 0x3F
	sts CPU_SPH, r16

	rcall EBI_INIT
	rcall TCC0_INIT

XZ_INIT:
; Point to the SRAM_START_ADDR with X
	ldi XL, byte1(SRAM_START_ADDR)
	ldi XH, byte2(SRAM_START_ADDR)
	ldi r16, byte3(SRAM_START_ADDR)
	out CPU_RAMPX, r16

	ldi ZH,byte2(0x0000)
	ldi ZL,byte1(0x0000)
OUTPUT_frame:
	;write data to SRAM from program memory  .Now in program memory, there are sram_data_asm file data.
	lpm r16,Z+
	st X+,r16
	cpi r16,EOT ;cpi just compare r16 and EOT,just do r16-EOT
	breq Next_Frame ;Writing  complete! following breq just branch if equal,that is if r16-EOT=0,then branch to Next_frame
	rjmp OUTPUT_frame;if not r16 =EOT ,then continue writing to external SRAM


Next_Frame:
; Point to the SRAM_START_ADDR with X
	ldi XL, byte1(SRAM_START_ADDR)
	ldi XH, byte2(SRAM_START_ADDR)
	ldi r16, byte3(SRAM_START_ADDR)
	out CPU_RAMPX, r16

	ldi YL, byte1(IN_PORT)
	ldi YH, byte2(IN_PORT)
	ldi r16, byte3(IN_PORT)
	sts CPU_RAMPY, r16

Loop:
	lds r17,TCC0_INTFLAGS
	sbrs r17,TC0_OVFIF_bp;just the same as sbrs  r17 ,0 .that is  ,detect overflow bit.
	rjmp Loop ;Continue to check the overflow bit when there is no overflow

	;When the time is up, write down what you need to do here
	;writing each read byte of data to the external I/O port 

	ld r16,X+;read back from external sram
	st Y,r16 ;store to Y ,that is write to ouput port address




	;clear overflow bit
	ldi r17,0b00000001 ;ldi r17 TC0_OVFIF_bm(bit mask)
	sts TCC0_INTFLAGS ,r17

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


TCC0_INIT:
	push r16
	clr r16
	sts TCC0_CNT, r16
	sts(TCC0_CNT+1), r16
	;set registers
	ldi r16, low((F_CPU/CLK_PRE)/Daoshu_time) ;active low, show frame
	sts TCC0_PER, r16
	ldi r16, high((F_CPU/CLK_PRE)/Daoshu_time) ;active high, show frame
	sts (TCC0_PER + 1), r16
	;starts timer counter with prescaler value of 2
	ldi r16, TC_CLKSEL_DIV8_gc
	sts TCC0_CTRLA, r16
	pop r16
	ret
