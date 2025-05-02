@ EE234: Microprocessors
@ Authors: Josh Pizana and Josiah Kumley
@ Date: May 1, 2025
@
@ Description:
@ This file contains the configuration and handling of the Generic Interrupt Controller (GIC)
@ for the Final Project in EE234: Microprocessors.
@ The GIC is responsible for managing and prioritizing interrupts from various sources,
@ including the Global Timer Counter (GTC) and GPIO buttons.
@ 
@ The file includes functions to configure the GIC, enable and disable interrupts, and handle specific interrupt requests. 
@ It defines the necessary base addresses for GIC registers and provides handlers for:
@ - Global Timer Interrupts (IRQ ID: 27): Used for timer-based operations.
@ - GPIO Button Interrupts (IRQ ID: 52): Triggered by button presses (e.g., BTN4 and BTN5).
@
@ Additionally, this file includes routines to set interrupt priorities,
@ configure interrupt sensitivity (edge or level-triggered), and assign
@ interrupts to specific processors. It also provides utility functions
@ to enable or disable interrupts globally and clear pending interrupts.
@
@ The GIC configuration ensures proper handling of critical events in the
@ system, enabling smooth operation of the Final Project's functionality.

.ifndef GIC_S_
.set GIC_S_, 1

.include "../src/GPIO.S"
.include "../src/timer.S"
.include "../src/handler.S"

.set ICCICR_BASEADDR, 0xF8F00100 @ CPU Interface Control Register
.set ICCPMR_BASEADDR, 0xF8F00104 @ Interrupt Priority Mask Register
.set ICCIAR_BASEADDR, 0xF8F0010C @ Interrupt Acknowledge Register
.set ICCEOIR_BASEADDR, 0xF8F00110 @ End of Interrupt Register
.set ICDDCR_BASEADDR, 0xF8F01000 @ Distributor Control Register
.set ICDISER_BASEADDR, 0xF8F01100 @ Interrupt Set Enable Registers
.set ICDICER_BASEADDR, 0xF8F01180 @ Interrupt Clear Enable Registers
.set ICDIPR_BASEADDR, 0xF8F01400 @ Interrupt Priority Registers
.set ICDIPTR_BASEADDR, 0xF8F01800 @ Interrupt Processor Targets Registers
.set ICDICFR_BASEADDR, 0xF8F01C00 @ Interrupt Configuration Registers

.text

configureGic:
	push {r0,r1,r2,lr} @ Save registers and link register

	@ 1. Disable the GIC distributor (ICDDCR)
	ldr r0, =ICDDCR_BASEADDR 		@ Load distributor control register base address
	mov r1, #0b00 					@ Disable distributor
	str r1, [r0] 					@ Store the value to disable distributor

	@ 2. Drive IRQ from the GIC (ICCICR)
	ldr r0, =ICCICR_BASEADDR 		@ Load CPU interface control register base address
	mov r1, #0b00011 				@ Enable signaling of interrupts
	str r1, [r0] 					@ Store the value to enable signaling

	@ 3. Set GIC priority mask
	ldr r0, =ICCPMR_BASEADDR 		@ Load priority mask register base address
	mov r1, #255 					@ Set the priority mask to allow all priorities
	str r1, [r0] 					@ Store the priority mask value

	@ 4. Configure the settings for specific interrupt IDs we want
	bl gicConfigure_ID27 			@ Configure interrupt ID 27
	bl gicConfigure_ID52 			@ Configure interrupt ID 52

	@ 5. Enable the GIC distributor (ICDDCR)
	ldr r0, =ICDDCR_BASEADDR 		@ Load distributor control register base address
	mov r1, #0b11 					@ Enable distributor
	str r1, [r0] 					@ Store the value to enable distributor

	pop {r0,r1,r2,lr} 				@ Restore registers and link register
bx lr 		@ Return from subroutine

gicConfigure_ID27:
	@ Configure interrupt ID 27
	ldr r0, =ICDIPTR_BASEADDR 		@ Load processor targets register base address
	ldr r1, =#0x3000000 			@ Mask for clearing target processor bits
	mvn r1, r1 						@ Invert the mask
	ldr r2, [r0, #0x18] 			@ Load current value for ID 27
	and r2, r2, r1 					@ Clear target processor bits
	str r2, [r0, #0x18] 			@ Store updated value

	ldr r0, =ICDICER_BASEADDR 		@ Load interrupt clear enable register base address
	ldr r1, =#0x8000000 			@ Mask for disabling ID 27
	str r1, [r0] 					@ Disable interrupt ID 27

	@ 4b. Set Interrupt Sensitivity for ID 27
	ldr r0, =ICDICFR_BASEADDR 		@ Load configuration register base address
	ldr r1, =#0xC00000 				@ Mask for edge-triggered sensitivity
	ldr r2, [r0, #0x04] 			@ Load current configuration for ID 27
	orr r2, r2, r1 					@ Set edge-triggered sensitivity
	str r2, [r0, #0x04] 			@ Store updated configuration

	@ 4c. Set Interrupt Priority for ID 27
	ldr r0, =ICDIPR_BASEADDR 		@ Load priority register base address
	ldr r1, =#0xFF000000 			@ Mask for clearing priority bits
	mvn r1, r1 						@ Invert the mask
	ldr r2, [r0, #0x18] 			@ Load current priority for ID 27
	and r2, r2, r1 					@ Clear priority bits
	ldr r1, =#0x50000000 			@ Set priority to 0x50
	orr r2, r2, r1 					@ Update priority
	str r2, [r0, #0x18] 			@ Store updated priority

	@ 4d. Enable Interrupts from ID 27 now that we are done modifying settings
	ldr r0, =ICDIPTR_BASEADDR 		@ Load processor targets register base address
	ldr r1, =#0x1000000 			@ Mask for enabling target processor
	ldr r2, [r0, #0x18] 			@ Load current value for ID 27
	orr r2, r2, r1 					@ Enable target processor
	str r2, [r0, #0x18] 			@ Store updated value
	ldr r0, =ICDISER_BASEADDR 		@ Load interrupt set enable register base address
	ldr r1, =#0x8000000 			@ Mask for enabling ID 27
	str r1, [r0] 					@ Enable interrupt ID 27

bx lr 		@ Return from subroutine

gicConfigure_ID52:
	@ Interrupt ID 52 = GPIO Interrupts (i.e. from BTN4 or BTN5)
	ldr r0, =ICDIPTR_BASEADDR 		@ Load processor targets register base address
	mvn r1, #0b11 					@ Mask for clearing target processor bits
	ldr r2, [r0, #0x34] 			@ Load current value for ID 52
	and r2, r2, r1 					@ Clear target processor bits
	str r2, [r0, #0x34] 			@ Store updated value

	ldr r0, =ICDICER_BASEADDR 		@ Load interrupt clear enable register base address
	ldr r1, =#0x100000 				@ Mask for disabling ID 52
	str r1, [r0, #0x04] 			@ Disable interrupt ID 52

	@ 4b. Set Interrupt Sensitivity for ID 52
	ldr r0, =ICDICFR_BASEADDR 		@ Load configuration register base address
	mvn r1, #0b1100000000 			@ Mask for clearing sensitivity bits
	ldr r2, [r0, #0x0C] 			@ Load current configuration for ID 52
	and r2, r2, r1 					@ Clear sensitivity bits
	mov r1, #0b0100000000 			@ Set level-sensitive configuration
	orr r2, r2, r1 					@ Update sensitivity
	str r2, [r0, #0x0C] 			@ Store updated configuration

	@ 4c. Set Interrupt Priority for ID 52
	ldr r0, =ICDIPR_BASEADDR 		@ Load priority register base address
	mvn r1, #0xFF 					@ Mask for clearing priority bits
	ldr r2, [r0, #0x34] 			@ Load current priority for ID 52
	and r2, r2, r1 					@ Clear priority bits
	mov r1, #0xA0 					@ Set priority to 0xA0
	orr r2, r2, r1 					@ Update priority
	str r2, [r0, #0x34] 			@ Store updated priority

	@ 4d. Enable Interrupts from ID 52 now that we are done modifying settings
	ldr r0, =ICDIPTR_BASEADDR 		@ Load processor targets register base address
	mov r1, #0b01 					@ Mask for enabling target processor
	ldr r2, [r0, #0x34] 			@ Load current value for ID 52
	orr r2, r2, r1 					@ Enable target processor
	str r2, [r0, #0x34] 			@ Store updated value
	ldr r0, =ICDISER_BASEADDR 		@ Load interrupt set enable register base address
	ldr r1, =#0x100000 				@ Mask for enabling ID 52
	str r1, [r0, #0x04] 			@ Enable interrupt ID 52

bx lr 		@ Return from subroutine

disableInterrupts:
	push {r0} 						@ Save register r0
	
	mrs r0, cpsr 					@ Move current program status register to r0
	orr r0, r0, #0b10000000 		@ Set interrupt disable bit
	msr cpsr_c, r0 					@ Write back to CPSR

	pop {r0} 						@ Restore register r0
bx lr 		@ Return from subroutine

enableInterrupts:
	push {r0,r1} 					@ Save registers r0 and r1
	
	mrs r0, cpsr 					@ Move current program status register to r0
	mvn r1, #0b10000000 			@ Invert interrupt disable bit mask
	and r0, r0, r1 					@ Clear interrupt disable bit
	msr cpsr_c, r0 					@ Write back to CPSR
	
	pop {r0,r1} 					@ Restore registers r0 and r1
bx lr 		@ Return from subroutine

GpioInterrupts:
	push {r0,r1} 					@ Save registers r0 and r1
	
	@ Disable interrupts
	ldr r0, =GPIO_BASEADDR 			@ Load GPIO base address
	ldr r1, =#0xFFFFFFFF 			@ Mask for disabling all interrupts
	str r1, [r0, #0x214] 			@ Disable interrupts for GPIO bank 1
	str r1, [r0, #0x254] 			@ Disable interrupts for GPIO bank 2
	
	@ Setup interrupt sensitivity for buttons 4 and 5
	ldr r1, =#0xC0000 				@ Mask for setting sensitivity
	str r1, [r0, #0x25C] 			@ Set sensitivity for bank 2
	str r1, [r0, #0x260] 			@ Set sensitivity for bank 3
	
	mov r1, #0 						@ Clear any pending interrupts
	str r1, [r0, #0x264] 			@ Clear pending interrupts for bank 3
	
	ldr r1, =#0xFFFFFFFF 			@ Mask for enabling interrupts
	str r1, [r0, #0x258] 			@ Enable interrupts for bank 2
	
	ldr r1, =#0xC0000 				@ Mask for enabling specific interrupts
	str r1, [r0, #0x250] 			@ Enable interrupts for bank 1
	
	pop {r0,r1} 					@ Restore registers r0 and r1
bx lr 		@ Return from subroutine

irqHandler:
	push {r0,r1,r2,r3,lr} 			@ Save registers and link register
	
	ldr r0, =ICCIAR_BASEADDR 		@ Load interrupt acknowledge register base address
	ldr r1, [r0] 					@ Read interrupt ID
	
	ldr r0, =GPIO_BASEADDR 			@ Load GPIO base address
	ldr r2, [r0, #0x258] 			@ Read interrupt status
	lsr r2, r2, #18 				@ Shift to isolate button interrupt bits
	and r2, r2, #0b11 				@ Mask to get button interrupt bits
	
	cmp r1, #27 					@ Check if interrupt ID is 27 (GTC Interrupt)
	beq irqHandle27 				@ Branch if true
	cmp r1, #52 					@ Check if interrupt ID is 52 (GPIO Interrupt)
	beq irqHandle52 				@ Branch if true
	b leaveIrqHandler 				@ Otherwise, leave IRQ handler

@ Handle timer interrupt
irqHandle27:
	.ifdef GIC_IRQID27
		bl GIC_IRQID27 				@ Call user-defined handler for ID 27
	.endif

	ldr r3, =GTC_BASEADDR 			@ Load GTC base address
	mov r2, #1 						@ Clear timer interrupt
	str r2, [r3,#0x0C] 				@ Write to clear interrupt
	b leaveIrqHandler 				@ Leave IRQ handler
	
irqHandle52:
	cmp r2, #0b01 					@ Check if BTN4 caused the interrupt
	beq irqButton4 					@ Branch if true
	cmp r2, #0b10 					@ Check if BTN5 caused the interrupt
	beq irqButton5 					@ Branch if true
	b leaveIrqHandler 				@ Otherwise, leave IRQ handler

@ Handle BTN4 interrupt
irqButton4: 
	.ifdef GIC_IRQID52_BTN4
		bl GIC_IRQID52_BTN4 		@ Call user-defined handler for BTN4
	.endif
	
	ldr r3, =0x40000 				@ Clear BTN4 interrupt
	str r3, [r0, #0x258] 			@ Write to clear interrupt
	b leaveIrqHandler 				@ Leave IRQ handler

@ Handle BTN5 interrupt
irqButton5:
	.ifdef GIC_IRQID52_BTN5
		bl GIC_IRQID52_BTN5 		@ Call user-defined handler for BTN5
	.endif
	
	ldr r3, =0x80000 				@ Clear BTN5 interrupt
	str r3, [r0, #0x258] 			@ Write to clear interrupt
	
leaveIrqHandler:
	ldr r0, =ICCEOIR_BASEADDR 		@ Load end of interrupt register base address
	str r1, [r0] 					@ Acknowledge that interrupt has been serviced
	
	pop {r0,r1,r2,r3,lr} 			@ Restore registers and link register
bx lr 		@ Return from subroutine

.endif