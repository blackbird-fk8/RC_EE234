@ EE234: Microprocessors
@ Authors: Josh Pizana and Josiah Kumley
@ Date: May 1, 2025
@
@ Description:
@ This file contains the configuration and handling of GPIO
@ (General-Purpose Input/Output)for the Final Project in EE234: Microprocessors.
@ It provides functions to interact with on-board peripherals
@ such as buttons, LEDs, switches, and the seven-segment display.
@ Additionally, it includes routines to configure and control
@ PMOD peripherals for both input and output operations.
@
@ Key functionalities include:
@ - Reading and writing to GPIO peripherals (buttons, LEDs, switches).
@ - Configuring and controlling the seven-segment display for output.
@ - Setting up PMOD peripherals for input and output, including top and bottom row configurations.
@ - Utility functions for enabling and disabling GPIO pins, as well as configuring interrupt behavior for buttons.
@
@ This file ensures seamless interaction with GPIO peripherals,
@ enabling the Final Project to handle user inputs and display outputs effectively.

.ifndef GPIO_S_
.set GPIO_S_, 1

@ GPIO Addresses
.set GPIO_BASEADDR, 0xE000A000  @ Base address for GPIO
.set BUTTONS, 0x41200000        @ Address for on-board buttons
.set LEDS, 0x41210000           @ Address for on-board LEDs
.set SVNSEG, 0x43C10000         @ Address for seven-segment display
.set SWITCHES, 0x41220000       @ Address for on-board switches

@ PMOD B Addresses
.set DATA_2, 0xE000A048         @ Data register for PMOD-B
.set DATA_2_RO, 0xE000A068      @ Read-only data register for PMOD-B
.set DIR_2, 0xE000A284          @ Direction register for PMOD-B
.set OE_2, 0xE000A288           @ Output enable register for PMOD-B
.set PMODB_TOP_MASK, 0x0780     @ Mask for top row of PMOD-B
.set PMODB_BOTTOM_MASK, 0x7800  @ Mask for bottom row of PMOD-B

.text

setupSVNSEG:
    ldr r0, =SVNSEG             @ Load the base address of the seven-segment display
    mov r1, #0b01               @ Set the display to an initial state
    str r1, [r0]                @ Write the value to the display
bx lr                       	@ Return from the function

outputSVNSEG:
    push {r0, lr}               @ Save r0 and the link register
    bl formatSVNSEGData         @ Format the data for the seven-segment display
    mov r1, r0                  @ Move the formatted data to r1
    ldr r0, =SVNSEG             @ Load the base address of the seven-segment display
    str r1, [r0, #0x4]          @ Write the formatted data to the display
    pop {r0, lr}                @ Restore r0 and the link register
bx lr                       	@ Return from the function

formatSVNSEGData:
    and r0, r1, #0xF            @ Extract the lower 4 bits of r1
    push {r2, r3}               @ Save r2 and r3
    and r2, r1, #0xF0           @ Extract bits 4-7 of r1
    orr r0, r0, r2, lsl #4      @ Shift left by 4 and OR with r0
    and r2, r1, #0xF00          @ Extract bits 8-11 of r1
    orr r0, r0, r2, lsl #8      @ Shift left by 8 and OR with r0
    mov r3, #0xF000             @ Prepare a mask for bits 12-15
    and r2, r1, r3              @ Extract bits 12-15 of r1
    orr r0, r0, r2, lsl #12     @ Shift left by 12 and OR with r0
    pop {r2, r3}                @ Restore r2 and r3
bx lr                       	@ Return from the function

outputSVNSEGDeci:
    push {r0, lr}               @ Save r0 and the link register
    bl formatSVNSEGDeci     	@ Format the decimal data for the display
    mov r1, r0                  @ Move the formatted data to r1
    ldr r0, =SVNSEG             @ Load the base address of the seven-segment display
    str r1, [r0, #0x4]          @ Write the formatted data to the display
    pop {r0, lr}                @ Restore r0 and the link register
bx lr                       	@ Return from the function

formatSVNSEGDeci:
    push {r2, r3, lr}           @ Save r2, r3, and the link register
    mov r2, #10                 @ Set divisor to 10
    bl intDivide                @ Divide r1 by 10
    mov r2, r1                  @ Store the quotient in r2

    push {r0}                   @ Save r0
    bl intMod                   @ Get the remainder of r1 % 10
    mov r0, r3                  @ Store the remainder in r0
    pop {r0}                    @ Restore r0
    orr r0, r0, r3, lsl #4      @ Shift remainder left by 4 and OR with r0

    mov r2, #10                 @ Set divisor to 10
    bl intDivide                @ Divide r1 by 10
    mov r2, r1                  @ Store the quotient in r2

    push {r0}                   @ Save r0
    bl intMod                   @ Get the remainder of r1 % 10
    mov r0, r3                  @ Store the remainder in r0
    pop {r0}                    @ Restore r0
    orr r0, r0, r3, lsl #8      @ Shift remainder left by 8 and OR with r0

    mov r2, #10                 @ Set divisor to 10
    bl intDivide                @ Divide r1 by 10
    mov r2, r1                  @ Store the quotient in r2

    push {r0}                   @ Save r0
    bl intMod                   @ Get the remainder of r1 % 10
    mov r0, r3                  @ Store the remainder in r0
    pop {r0}                    @ Restore r0
    orr r0, r0, r3, lsl #12     @ Shift remainder left by 12 and OR with r0

    mov r2, #10                 @ Set divisor to 10
    bl intDivide                @ Divide r1 by 10
    mov r2, r1                  @ Store the quotient in r2

    pop {r2, r3, lr}            @ Restore r2, r3, and the link register
bx lr                       	@ Return from the function

outputToLEDs:
    push {r0}                   @ Save r0
    ldr r0, =LEDS               @ Load the base address of the LEDs
    str r1, [r0]                @ Write the value in r1 to the LEDs
    pop {r0}                    @ Restore r0
bx lr                       	@ Return from the function

getButtonStates:
    push {r1}                   @ Save r1
    ldr r1, =BUTTONS            @ Load the base address of the buttons
    ldr r0, [r1]                @ Read the button states into r0
    pop {r1}                    @ Restore r1
bx lr                       	@ Return from the function

getSwitchStates:
    push {r1}                   @ Save r1
    ldr r1, =SWITCHES           @ Load the base address of the switches
    ldr r0, [r1]                @ Read the switch states into r0
    pop {r1}                    @ Restore r1
bx lr                       	@ Return from the function

ExtraGpio:
    push {r0, r1, r2}           @ Save registers
    ldr r0, =GPIO_BASEADDR      @ Load the base address of GPIO

    @ Configure LED 12 as an output
    ldr r1, =#0x70000           @ Mask for bits 16-18
    ldr r2, [r0, #0x204]        @ Read the direction register
    orr r2, r2, r1              @ Set bits 16-18 to output
    str r2, [r0, #0x204]        @ Write back to the direction register

    ldr r2, [r0, #0x208]        @ Read the output enable register
    orr r2, r2, r1              @ Enable output for bits 16-18
    str r2, [r0, #0x208]        @ Write back to the output enable register

    @ Clear LED 12 (turn it off)
    mvn r1, r1                  @ Invert the mask
    ldr r2, [r0, #0x60]         @ Read the data register
    and r2, r2, r1              @ Clear bits 16-18
    str r2, [r0, #0x40]         @ Write back to the data register

    @ Configure Buttons 4 and 5 as inputs
    ldr r1, =#0xC0000           @ Mask for bits 18-19
    mvn r1, r1                  @ Invert the mask
    ldr r2, [r0, #0x244]        @ Read the direction register
    and r2, r2, r1              @ Clear bits 18-19 to input
    str r2, [r0, #0x244]        @ Write back to the direction register

    @ Disable interrupts for Buttons 4 and 5
    ldr r1, =#0xC0000           @ Mask for bits 18-19
    str r1, [r0, #0x254]        @ Disable interrupts

    @ Configure Buttons 4 and 5 as edge-sensitive
    ldr r2, [r0, #0x25C]        @ Read the interrupt type register
    orr r2, r2, r1              @ Set bits 18-19 to edge-sensitive
    str r2, [r0, #0x25C]        @ Write back to the interrupt type register

    @ Configure Buttons 4 and 5 as rising-edge
    ldr r2, [r0, #0x260]        @ Read the interrupt polarity register
    orr r2, r2, r1              @ Set bits 18-19 to rising-edge
    str r2, [r0, #0x260]        @ Write back to the interrupt polarity register

    @ Clear any spurious interrupt requests
    str r1, [r0, #0x258]        @ Clear interrupt requests

    @ Enable interrupts for Buttons 4 and 5
    str r1, [r0, #0x250]        @ Enable interrupts

    pop {r0, r1, r2}            @ Restore registers
bx lr                       	@ Return from the function

setupPmod:
	push {r3,r4}                @ Save r3 and r4 on the stack

	cmp r2, #0                 @ Check if r2 is 0 (top row or bottom row)
	beq topRowSetup            @ If r2 is 0, branch to topRowSetup
	b bottomRowSetup           @ Otherwise, branch to bottomRowSetup

	topRowSetup:
		cmp r1, #0             @ Check if r1 is 0 (input or output)
		beq topRowInput        @ If r1 is 0, branch to topRowInput
		b topRowOutput         @ Otherwise, branch to topRowOutput

		topRowInput:
			ldr r3, =PMODB_TOP_MASK @ Load the top row mask
			mvn r3, r3              @ Invert the mask
			and r4, r4, r3          @ Clear the top row bits in r4

			ldr r3, =OE_2           @ Load the output enable register address
			str r4, [r3]            @ Write the updated value to the register

			ldr r3, =PMODB_TOP_MASK @ Load the top row mask again
			mvn r3, r3              @ Invert the mask
			and r4, r4, r3          @ Clear the top row bits in r4

			ldr r3, =DIR_2          @ Load the direction register address
			str r4, [r3]            @ Write the updated value to the register

			b leaveSetupPmod        @ Branch to leaveSetupPmod

		topRowOutput:
			ldr r3, =PMODB_TOP_MASK @ Load the top row mask
			orr r4, r4, r3          @ Set the top row bits in r4

			ldr r3, =OE_2           @ Load the output enable register address
			str r4, [r3]            @ Write the updated value to the register

			ldr r3, =PMODB_TOP_MASK @ Load the top row mask again
			orr r4, r4, r3          @ Set the top row bits in r4

			ldr r3, =DIR_2          @ Load the direction register address
			str r4, [r3]            @ Write the updated value to the register

			b leaveSetupPmod        @ Branch to leaveSetupPmod

	bottomRowSetup:
		cmp r1, #0             @ Check if r1 is 0 (input or output)
		beq bottomRowInput     @ If r1 is 0, branch to bottomRowInput
		b bottomRowOutput      @ Otherwise, branch to bottomRowOutput

		bottomRowInput:
			ldr r3, =PMODB_BOTTOM_MASK @ Load the bottom row mask
			mvn r3, r3                @ Invert the mask
			and r4, r4, r3            @ Clear the bottom row bits in r4

			ldr r3, =OE_2             @ Load the output enable register address
			str r4, [r3]              @ Write the updated value to the register

			ldr r3, =PMODB_BOTTOM_MASK @ Load the bottom row mask again
			mvn r3, r3                @ Invert the mask
			and r4, r4, r3            @ Clear the bottom row bits in r4

			ldr r3, =DIR_2            @ Load the direction register address
			str r4, [r3]              @ Write the updated value to the register

			b leaveSetupPmod          @ Branch to leaveSetupPmod

		bottomRowOutput:
			ldr r3, =PMODB_BOTTOM_MASK @ Load the bottom row mask
			orr r4, r4, r3            @ Set the bottom row bits in r4

			ldr r3, =OE_2             @ Load the output enable register address
			ldr r4, [r3]              @ Read the current value of the register

			ldr r3, =PMODB_BOTTOM_MASK @ Load the bottom row mask again
			orr r4, r4, r3            @ Set the bottom row bits in r4

			ldr r3, =DIR_2            @ Load the direction register address
			str r4, [r3]              @ Write the updated value to the register

	leaveSetupPmod:
		pop {r3,r4}            @ Restore r3 and r4 from the stack
	bx lr                      @ Return from the function

pmodRead:
	push {r2,r3,r4,lr}         @ Save r2, r3, r4, and the link register

	mov r2, r1                 @ Copy r1 to r2
	mov r1, #0                 @ Set r1 to 0 (input mode)
	bl setupPmod               @ Call setupPmod to configure the PMOD

	cmp r2, #0                 @ Check if r2 is 0 (top row or bottom row)
	beq topRowPmodRead         @ If r2 is 0, branch to topRowPmodRead
	b bottomRowPmodRead        @ Otherwise, branch to bottomRowPmodRead

	topRowPmodRead:
		ldr r3, =DATA_2_RO     @ Load the read-only data register address
		ldr r4, [r3]           @ Read the data from the register

		and r4, r4, #PMODB_TOP_MASK @ Mask the top row bits
		lsr r4, #7             @ Shift the bits to the right by 7

		b leavePmodRead        @ Branch to leavePmodRead

	bottomRowPmodRead:
		ldr r3, =DATA_2_RO     @ Load the read-only data register address
		ldr r4, [r3]           @ Read the data from the register

		and r4, r4, #PMODB_BOTTOM_MASK @ Mask the bottom row bits
		lsr r4, #11            @ Shift the bits to the right by 11

	leavePmodRead:
		mov r0, r4             @ Move the result to r0
		pop {r2,r3,r4,lr}      @ Restore r2, r3, r4, and the link register
	bx lr                      @ Return from the function

pmodWrite:
	push {r3,r4,r5,lr}         @ Save r3, r4, r5, and the link register

	mov r5, r2                 @ Copy r2 to r5

	mov r2, r1                 @ Copy r1 to r2
	mov r1, #1                 @ Set r1 to 1 (output mode)
	bl setupPmod               @ Call setupPmod to configure the PMOD

	cmp r2, #0                 @ Check if r2 is 0 (top row or bottom row)
	beq topRowPmodWrite        @ If r2 is 0, branch to topRowPmodWrite
	b bottomRowPmodWrite       @ Otherwise, branch to bottomRowPmodWrite

	topRowPmodWrite:
		ldr r3, =DATA_2        @ Load the data register address
		ldr r4, [r3]           @ Read the current value of the register

		ldr r3, =PMODB_TOP_MASK @ Load the top row mask
		mvn r3, r3             @ Invert the mask

		and r4, r4, r3         @ Clear the top row bits in r4

		lsl r5, #7             @ Shift r5 to the left by 7
		and r5, r5, #PMODB_TOP_MASK @ Mask the top row bits
		orr r4, r4, r5         @ Set the top row bits in r4

		b leavePmodWrite       @ Branch to leavePmodWrite

	bottomRowPmodWrite:
		ldr r3, =DATA_2        @ Load the data register address
		ldr r4, [r3]           @ Read the current value of the register

		ldr r3, =PMODB_BOTTOM_MASK @ Load the bottom row mask
		mvn r3, r3             @ Invert the mask

		and r4, r4, r3         @ Clear the bottom row bits in r4

		lsl r5, #11            @ Shift r5 to the left by 11
		and r5, r5, #PMODB_BOTTOM_MASK @ Mask the bottom row bits
		orr r4, r4, r5         @ Set the bottom row bits in r4

	leavePmodWrite:
		ldr r3, =DATA_2        @ Load the data register address
		str r4, [r3]           @ Write the updated value to the register

		pop {r3,r4,r5,lr}      @ Restore r3, r4, r5, and the link register
	bx lr                      @ Return from the function

dummyTimer:
	push {r0}                  @ Save r0 on the stack

	ldr r0, =#0x7FFFFFF        @ Load a large value into r0

	DummyTimerLoop:
		sub r0, r0, #1         @ Decrement r0

		cmp r0, #0             @ Check if r0 is 0
		bge DummyTimerLoop     @ If not, branch back to DummyTimerLoop

	pop {r0}                   @ Restore r0 from the stack
	bx lr                      @ Return from the function

intDivide:
	push {r3,r4,r5,r6}         @ Save r3, r4, r5, and r6 on the stack
	mov r3, r1                 @ Copy r1 to r3 (remainder)
	mov r4, r2                 @ Copy r2 to r4 (divisor)
	mov r6, #0                 @ Initialize counter to 0

	cmp r1, #0                 @ Check if r1 is positive or negative
	bge posDivOp			   @ If positive, branch to posDivOp
	ble negDivOp       		   @ If negative, branch to negDivOp
	beq leaveIntDivide         @ If zero, branch to leaveIntDivide

	posDivOp:
		cmp r2, #0             @ Check if r2 is positive or negative
		movge r5, #1           @ If positive, set r5 to 1
		movle r5, #-1          @ If negative, set r5 to -1
		suble r4, r4, #1       @ Make r4 positive (part 1)
		mvnle r4, r4           @ Make r4 positive (part 2)
		beq leaveIntDivide     @ If dividing by zero, branch to leaveIntDivide

	posDivOpLoop:
		sub r3, r3, r4         @ Subtract r4 from r3 repeatedly

		cmp r3, #0             @ Check if r3 is zero or negative
		addge r6, r6, r5       @ Increment counter if r3 is non-negative
		bge posDivOpLoop 	   @ Branch back to posDivOpLoop if r3 is non-negative
		b leaveIntDivide       @ Branch to leaveIntDivide

	negDivOp:
		cmp r2, #0             @ Check if r2 is positive or negative

		movge r5, #-1          @ If positive, set r5 to -1
		movle r5, #1           @ If negative, set r5 to 1

		suble r4, r4, #1       @ Make r4 positive (part 1)
		mvnle r4, r4           @ Make r4 positive (part 2)
		beq leaveIntDivide     @ If dividing by zero, branch to leaveIntDivide

	negDivOpLoop:
		add r3, r3, r4         @ Add r4 to r3 repeatedly

		cmp r3, #0             @ Check if r3 is zero or positive
		addle r6, r6, r5       @ Increment counter if r3 is non-positive
		ble negDivOpLoop 	   @ Branch back to negDivOpLoop if r3 is non-positive

	leaveIntDivide:
		mov r0, r6             @ Move the result to r0
		pop {r3,r4,r5,r6}      @ Restore r3, r4, r5, and r6 from the stack
	bx lr                      @ Return from the function

intMod:
	push {r3,r4}               @ Save r3 and r4 on the stack
	mov r3, r1                 @ Copy r1 to r3 (remainder)
	mov r4, r2                 @ Copy r2 to r4 (divisor)

	cmp r2, #0                 @ Check if dividing by zero
	beq leaveIntMod            @ If so, branch to leaveIntMod

	cmp r1, #0                 @ Check if r1 is positive or negative
	bge posModOp       @ If positive, branch to posModOp
	ble negModOp       @ If negative, branch to negModOp
	beq leaveIntMod            @ If zero, branch to leaveIntMod

	posModOp:
		sub r3, r3, r4         @ Subtract r4 from r3 repeatedly

		cmp r3, #0             @ Check if r3 is zero or negative
		addle r3, r3, r4       @ Step back one if r3 is negative
		bge posModOp   @ Branch back to posModOp if r3 is non-negative

		b leaveIntMod          @ Branch to leaveIntMod

	negModOp:
		add r3, r3, r4         @ Add r4 to r3 repeatedly

		cmp r3, #0             @ Check if r3 is zero or positive
		subge r3, r3, r4       @ Step back one if r3 is positive
		ble negModOp   @ Branch back to negModOp if r3 is non-positive

	leaveIntMod:
		mov r0, r3             @ Move the result to r0
		pop {r3,r4}            @ Restore r3 and r4 from the stack
	bx lr                      @ Return from the function


.endif 