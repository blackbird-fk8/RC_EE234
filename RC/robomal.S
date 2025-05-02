@ EE234: Microprocessors
@ Authors: Josh Pizana and Josiah Kumley
@ Date: May 1, 2025
@
@ Description:
@ This file contains the implementation of the ROBOMAL (Robot Operation Machine Assembly Language)
@ interpreter for the Final Project in EE234: Microprocessors. ROBOMAL is a custom instruction set
@ designed to control the robot's behavior, including data operations, arithmetic, branching, and
@ motor control. The file defines the main execution loop, instruction fetch, decode, and execute
@ stages, as well as specific operations for interacting with hardware components.
@
@ Key functionalities include:
@ - Fetching, decoding, and executing ROBOMAL instructions.
@ - Performing data operations such as reading from and writing to memory.
@ - Executing arithmetic operations (addition, subtraction, multiplication).
@ - Handling branching instructions for conditional and unconditional jumps.
@ - Controlling motors and servos for movement (forward, backward, left, right, braking).
@ - Detecting and responding to collisions using sensor data.
@
@ This file ensures the seamless execution of ROBOMAL instructions, enabling the
@ robot to perform complex tasks and respond dynamically to its environment.

.ifndef ROBOMAL_S_
.set ROBOMAL_S_, 1

@ Motor base addresses
.set MOTOR_0_BASEADDR, 0x43C60000  @ Motor connected to the top row pins of PMODC port
.set MOTOR_1_BASEADDR, 0x43C80000  @ Motor connected to the bottom row pins of PMODC port

@ Include necessary libraries
.include "../src/GPIO.S"          @ GPIO functions
.include "../src/motor.S"         @ Motor control functions
.include "../src/wifi.S"          @ Wi-Fi functions
.include "../src/commands.S"      @ Command definitions

.data

@ Main operation jump-table
r_operation: .word r_dataJump, r_arithmeticJump, r_branchJump, r_controlJump

@ Suboperation jump-table for data operations
r_dataJump: .word r_read, r_write, r_load, r_store, r_lineSensors, r_collisionSensors

@ Suboperation jump-table for arithmetic operations
r_arithmeticJump: .word r_add, r_sub, r_mul

@ Suboperation jump-table for branch operations
r_branchJump: .word r_branch, r_brancheq, r_branchne, r_halt, r_wait

@ Suboperation jump-table for control operations
r_controlJump: .word r_left, r_right, r_forward, r_backward, r_brake

@ ROBOMAL Register File
@ r5  = accumulator register
@ r6  = program counter register
@ r7  = instruction register
@ r8  = opcode register
@ r9  = operand register
@ r10 = multiply top half solution register

.text

runRobomal:
    push {r7, r8, r9, lr}        	@ Save registers
    mov r6, #0                  	@ Initialize program counter

    runRobomalLoop:
        push {r1, r2, r3}           @ Save registers
        bl checkFIFO                @ Check if FIFO has data
        cmp r0, #0                  @ Compare result with 0
        bne leaveCheck              @ Skip if no data

        bl checkForCommand          @ Check for a command
        ldr r1, =readCommand        @ Load readCommand address
        ldrh r1, [r1]               @ Read command value
        ldr r0, =functionMode       @ Load functionMode address
        ldrh r0, [r0]               @ Read current function mode

        mov r3, #0xFF00             @ Mask upper byte
        and r2, r1, r3              @ Extract upper byte
        mov r3, #0xEE00             @ Compare with function mode prefix
        cmp r2, r3
        bne leaveCheck              @ Skip if not a function mode command

        cmp r1, r0                  @ Compare command with current mode
        ldrne r0, =functionMode     @ Update function mode if different
        strneh r1, [r0]
        movne r1, #0x4400           @ Reset readCommand
        ldrne r0, =readCommand
        strneh r1, [r0]
        popne {r1, r2, r3}          @ Restore registers
        bne endRobomalLoop          @ End loop if mode changed

        leaveCheck:
            pop {r1, r2, r3}        @ Restore registers

    bl simClockCycle            @ Simulate a clock cycle
    cmp r8, #0x33               @ Check for halt instruction
    bne runRobomalLoop          @ Continue loop if not halt

    endRobomalLoop:
        pop {r7, r8, r9, lr}        @ Restore registers
bx lr                       		@ Return from function

simClockCycle:
    push {lr}                   @ Save link register
    bl r_fetch                  @ Fetch instruction
    bl r_decode                 @ Decode instruction
    bl r_execute                @ Execute instruction
    pop {lr}                    @ Restore link register
bx lr                           @ Return from function

r_fetch:
    push {r0}                   @ Save register
    ldrh r7, [r1, r6]           @ Fetch instruction from memory
    add r6, r6, #0x2            @ Increment program counter
    pop {r0}                    @ Restore register
bx lr                           @ Return from function

r_decode:
    lsr r8, r7, #8              @ Extract opcode (upper byte)
    and r9, r7, #0xFF           @ Extract operand (lower byte)
bx lr                           @ Return from function

r_execute:
    push {r0, r1, lr}           @ Save registers
    mov r1, r8                  @ Copy opcode to r1
    and r1, #0xF0               @ Mask upper nibble
    sub r1, r1, #0x10           @ Adjust for indexing
    lsr r1, #2                  @ Shift for word indexing
    ldr r0, =r_operation        @ Load operation jump table
    ldr r0, [r0, r1]            @ Get sub-jump table address

    mov r1, r8                  @ Copy opcode to r1
    and r1, #0xF                @ Mask lower nibble
    lsl r1, #2                  @ Shift for word indexing
    ldr r0, [r0, r1]            @ Get operation address
    bx r0                       @ Branch to operation

    r_read:
        mov r1, #1                  @ Set PMOD row to bottom
        bl pmodRead                 @ Read PMOD value
        mov r1, r2                  @ Load data set address
        strh r0, [r1, r9]           @ Store value in data set
    b leave_r_execute           @ Exit operation

    r_write:
        mov r0, r2                  @ Load data set address
        ldrh r1, [r0, r9]           @ Load value from data set
        mov r2, r1                  @ Set data to write
        mov r1, #0                  @ Set PMOD row to top
        bl pmodWrite                @ Write value to PMOD
    b leave_r_execute           @ Exit operation

    r_load:
        mov r0, r2                  @ Load data set address
        ldrh r5, [r0, r9]           @ Load value into accumulator
    b leave_r_execute           @ Exit operation

    r_store:
        mov r0, r2                  @ Load data set address
        strh r5, [r0, r9]           @ Store accumulator value
    b leave_r_execute           @ Exit operation

	r_lineSensors: @ Change drive instruction based on sensor status
		push {r2}                   @ Save r2 register
		mov r1, #1                  @ Set PMOD row to bottom
		bl pmodRead                 @ Read bottom row of PMOD

		pop {r1}                    @ Restore original address
		mov r3, r1                  @ Copy address to r3
		sub r3, r3, #0x8            @ Adjust address for instruction storage
		push {r1}                   @ Re-push r1 for later use

		cmp r0, #0b0011           @ Check if both left and right sensors are active
		mov r2, #0x4204             @ Instruction for moving forward
		streqh r2, [r3, r6]         @ Store instruction if condition is met

		cmp r0, #0b0001           @ Check if only the left sensor is active
		mov r2, #0x4003             @ Instruction for turning left
		streqh r2, [r3, r6]         @ Store instruction if condition is met

		cmp r0, #0b0010           @ Check if only the right sensor is active
		mov r2, #0x4103             @ Instruction for turning right
		streqh r2, [r3, r6]         @ Store instruction if condition is met

		cmp r0, #0                  @ Check if no sensors are active
		mov r2, #0x4204             @ Default instruction for moving forward
		streqh r2, [r3, r6]         @ Store instruction if condition is met

		pop {r2}                    @ Restore r2 register
    b leave_r_execute           	@ Exit operation

	r_collisionSensors:
    	bl collisionDetection       @ Call collision detection function
    b leave_r_execute           	@ Exit operation

    r_add:
        mov r0, r2                  @ Load data set address
        ldrh r0, [r0, r9]           @ Load value from data set
        add r5, r5, r0              @ Add to accumulator
    b leave_r_execute           	@ Exit operation

    r_sub:
        mov r0, r2                  @ Load data set address
        ldrh r0, [r0, r9]           @ Load value from data set
        sub r5, r5, r0              @ Subtract from accumulator
    b leave_r_execute           	@ Exit operation

    r_mul:
        mov r0, r2                  @ Load data set address
        ldrh r0, [r0, r9]           @ Load value from data set
        mul r5, r5, r0              @ Multiply accumulator
    b leave_r_execute           	@ Exit operation

    r_branch:
        mov r6, r9                  @ Set program counter to operand
    b leave_r_execute           	@ Exit operation

    r_brancheq:
        cmp r5, #0                  @ Compare accumulator with 0
        moveq r6, r9                @ Set program counter if equal
    b leave_r_execute           	@ Exit operation

    r_branchne:
        cmp r5, #0                  @ Compare accumulator with 0
        movne r6, r9                @ Set program counter if not equal
    b leave_r_execute           	@ Exit operation

    r_halt:
        b leave_r_execute           @ Exit operation

    r_wait:
        mov r3, r9                  @ Load operand
        lsr r3, r3, #4              @ Extract upper nibble
        cmp r3, #1                  @ Check for collision wait
        and r9, r9, #0xF            @ Mask lower nibble
        beq waitWithCollision       @ Branch if collision wait
        b regularWait               @ Otherwise, perform regular wait

        waitWithCollision:
        ldr r1, =#0x3A97F6          	@ Load collision wait count
        wait_loop1:
            bl collisionDetection       @ Check for collision
            sub r1, r1, #1              @ Decrement count
            cmp r1, #0                  @ Check if count is 0
        bne wait_loop1              @ Repeat if not 0
        sub r9, r9, #1              @ Decrement operand
        cmp r9, #0                  @ Check if operand is 0
        bne waitWithCollision       @ Repeat if not 0
        b doneWithWait              @ Exit wait

        regularWait:
        ldr r1, =#0x18FFFFFB        @ Load regular wait count
        wait_loop2:
            sub r1, r1, #1              @ Decrement count
            cmp r1, #0                  @ Check if count is 0
        bne wait_loop2              @ Repeat if not 0
        sub r9, r9, #1              @ Decrement operand
        cmp r9, #0                  @ Check if operand is 0
        bne regularWait             @ Repeat if not 0

    doneWithWait:
        mov r1, #0
        bl outputToLEDs
    b leave_r_execute           	@ Exit operation

    r_left:
        push {r2, r3, r4}           @ Save registers

        @ Calculate servo angle for turning left
        mov r3, #75                 @ Multiply operand by 75
        mul r3, r3, r9              @ Multiply by operand (r9)
        mov r4, #3800               @ Base servo angle
        sub r4, r4, r3              @ Subtract to adjust angle
        mov r1, r4                  @ Set servo angle
        bl changeAngle            	@ Call function to set servo angle

        @ Calculate motor speed for turning left
        mov r3, r9                  @ Copy operand to r3
        and r3, r3, #0xF            @ Mask lower 4 bits
        mov r4, #93                 @ Multiply operand by 93
        mul r3, r3, r4
        mov r4, #3450               @ Base motor speed
        add r3, r3, r4              @ Add to adjust speed

        @ Configure right motor
        ldr r1, =MOTOR_1_BASEADDR   @ Load motor 1 base address
        mov r2, #1                  @ Set direction to forward
        bl motorDirection        	@ Call function to set direction
        mov r2, #0                  @ Set speed to 0 (slower)
        bl motorSpeed            	@ Call function to set speed

        @ Configure left motor
        ldr r1, =MOTOR_0_BASEADDR   @ Load motor 0 base address
        mov r2, #1                  @ Set direction to forward
        bl motorDirection        	@ Call function to set direction
        mov r2, r3                  @ Set calculated speed
        bl motorSpeed            	@ Call function to set speed

        pop {r2, r3, r4}            @ Restore registers
    b leave_r_execute           	@ Exit operation

    r_right:
        push {r2, r3, r4}           @ Save registers

        @ Calculate servo angle for turning right
        mov r3, #75                 @ Multiply operand by 75
        mul r3, r3, r9              @ Multiply by operand (r9)
        mov r4, #2200               @ Base servo angle
        add r3, r3, r4              @ Add to adjust angle
        mov r1, r3                  @ Set servo angle
        bl changeAngle            	@ Call function to set servo angle

        @ Calculate motor speed for turning right
        mov r3, r9                  @ Copy operand to r3
        and r3, r3, #0xF            @ Mask lower 4 bits
        mov r4, #93                 @ Multiply operand by 93
        mul r3, r3, r4
        mov r4, #3450               @ Base motor speed
        add r3, r3, r4              @ Add to adjust speed

        @ Configure left motor 
        ldr r1, =MOTOR_0_BASEADDR   @ Load motor 0 base address
        mov r2, #1                  @ Set direction to forward
        bl motorDirection        	@ Call function to set direction
        mov r2, r3                  @ Set calculated speed
        bl motorSpeed            	@ Call function to set speed

        @ Configure right motor
        ldr r1, =MOTOR_1_BASEADDR   @ Load motor 1 base address
        mov r2, #1                  @ Set direction to forward
        bl motorDirection        	@ Call function to set direction
        mov r2, #0                  @ Set speed to 0 (slower)
        bl motorSpeed            	@ Call function to set speed

        pop {r2, r3, r4}            @ Restore registers
    b leave_r_execute           	@ Exit operation

    r_forward:
        push {r2, r3, r4}           @ Save registers

        @ Set servo angle for forward movement
        mov r1, #2900               @ Neutral servo angle
        bl changeAngle            	@ Call function to set servo angle

        @ Calculate motor speed for forward movement
        mov r3, r9                  @ Copy operand to r3
        and r3, r3, #0xF            @ Mask lower 4 bits
        mov r4, #90                 @ Multiply operand by 90
        mul r3, r3, r4
        mov r4, #4000               @ Base motor speed
        add r3, r3, r4              @ Add to adjust speed

        @ Configure both motors for forward movement
        ldr r1, =MOTOR_1_BASEADDR   @ Load motor 1 base address
        mov r2, #1                  @ Set direction to forward
        bl motorDirection        	@ Call function to set direction
        mov r2, r3                  @ Set calculated speed
        bl motorSpeed            	@ Call function to set speed

        ldr r1, =MOTOR_0_BASEADDR   @ Load motor 0 base address
        mov r2, #1                  @ Set direction to forward
        bl motorDirection        	@ Call function to set direction
        mov r2, r3                  @ Set calculated speed
        bl motorSpeed            	@ Call function to set speed

        pop {r2, r3, r4}            @ Restore registers
    b leave_r_execute           	@ Exit operation

    r_backward:
        push {r2, r3, r4}           @ Save registers

        @ Set servo angle for backward movement
        mov r1, #2900               @ Neutral servo angle
        bl changeAngle            	@ Call function to set servo angle

        @ Calculate motor speed for backward movement
        mov r3, r9                  @ Copy operand to r3
        and r3, r3, #0xF            @ Mask lower 4 bits
        mov r4, #90                 @ Multiply operand by 90
        mul r3, r3, r4
        mov r4, #3700               @ Base motor speed
        add r3, r3, r4              @ Add to adjust speed

        @ Configure both motors for backward movement
        ldr r1, =MOTOR_0_BASEADDR   @ Load motor 0 base address
        mov r2, #0                  @ Set direction to reverse
        bl motorDirection        	@ Call function to set direction
        mov r2, r3                  @ Set calculated speed
        bl motorSpeed            	@ Call function to set speed

        ldr r1, =MOTOR_1_BASEADDR   @ Load motor 1 base address
        mov r2, #0                  @ Set direction to reverse
        bl motorDirection        	@ Call function to set direction
        mov r2, r3                  @ Set calculated speed
        bl motorSpeed            	@ Call function to set speed

        pop {r2, r3, r4}            @ Restore registers
    b leave_r_execute           	@ Exit operation

    r_brake:
        push {r2}                   @ Save register

        @ Turn on all LEDs to indicate braking
        mov r1, #0b1111           @ Set all LEDs
        bl outputToLEDs             @ Call function to output to LEDs

        @ Stop both motors
        ldr r1, =MOTOR_0_BASEADDR   @ Load motor 0 base address
        mov r2, #0                  @ Set speed to 0
        bl motorSpeed            	@ Call function to set speed

        ldr r1, =MOTOR_1_BASEADDR   @ Load motor 1 base address
        mov r2, #0                  @ Set speed to 0
        bl motorSpeed            	@ Call function to set speed

        pop {r2}                    @ Restore register

    leave_r_execute:
        pop {r0, r1, lr}            @ Restore registers
bx lr                               @ Return from function

collisionDetection:
    push {r1, r2, lr}           	@ Save registers
    mov r1, #0                  	@ Initialize r1
        bl pmodRead                 @ Read PMOD value
            cmp r0, #0b1111	   		  @ Check if no collision is detected
            beq noCollide				   @ Branch to noCollide if no collision

            cmp r0, #0b1100              @ Check for left-side collision
            beq colReverseLeft             @ Branch to colReverseLeft if detected

            cmp r0, #0b1101              @ Check for left-side collision with additional sensor
            beq colReverseLeft             @ Branch to colReverseLeft if detected

            cmp r0, #0b1110              @ Check for left-side collision with another sensor combination
            beq colReverseLeft             @ Branch to colReverseLeft if detected

            cmp r0, #0b0011              @ Check for right-side collision
            beq colReverseRight            @ Branch to colReverseRight if detected

            cmp r0, #0b1011              @ Check for right-side collision with additional sensor
            beq colReverseRight            @ Branch to colReverseRight if detected

            cmp r0, #0b0111              @ Check for right-side collision with another sensor combination
            beq colReverseRight            @ Branch to colReverseRight if detected

        colReverseRight:
            push {r2}                   @ Save r2
            mov r1, #2200               @ Set servo angle for reverse right
            bl changeAngle
            ldr r1, =MOTOR_0_BASEADDR   @ Load motor 0 base address
            mov r2, #0                  @ Set direction to reverse
            bl motorDirection
            mov r2, #3295               @ Set speed
            bl motorSpeed
            ldr r1, =MOTOR_1_BASEADDR   @ Load motor 1 base address
            mov r2, #0                  @ Set direction to reverse
            bl motorDirection
            mov r2, #3295               @ Set speed
            bl motorSpeed
            pop {r2}                    @ Restore r2
            bl dummyTimer               @ Wait for reverse
            b noCollide                 @ Exit collision handling

        colReverseLeft:
            push {r2}                   @ Save r2
            mov r1, #3500               @ Set servo angle for reverse left
            bl changeAngle
            ldr r1, =MOTOR_0_BASEADDR   @ Load motor 0 base address
            mov r2, #0                  @ Set direction to reverse
            bl motorDirection
            mov r2, #3295               @ Set speed
            bl motorSpeed
            ldr r1, =MOTOR_1_BASEADDR   @ Load motor 1 base address
            mov r2, #0                  @ Set direction to reverse
            bl motorDirection
            mov r2, #3295               @ Set speed
            bl motorSpeed
            pop {r2}                    @ Restore r2
            bl dummyTimer               @ Wait for reverse
            b noCollide                 @ Exit collision handling

        noCollide:
            pop {r1, r2, lr}            @ Restore registers

bx lr                                   @ Return from function

.endif