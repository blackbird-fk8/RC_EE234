@ EE234: Microprocessors
@ Authors: Josh Pizana and Josiah Kumley
@ Date: May 1, 2025
@
@ Description:
@ This file contains the configuration and control functions for motors
@ and servos used in the Final Project for EE234: Microprocessors.
@ It provides routines to initialize and control motor speed, direction,
@ and servo angles. The file also includes functions to configure
@ the Triple Timer Counter (TTC) for generating PWM signals required for
@ motor and servo control.
@
@ Key functionalities include:
@ - Initializing motors with default settings (speed, direction, and PWM frequency).
@ - Setting motor speed and direction dynamically during operation.
@ - Configuring and controlling servo angles for precise movements.
@ - Utilizing the TTC to generate PWM signals for motor and servo control.
@
@ This file ensures smooth and precise control of motors and servos, enabling
@ the Final Project to perform complex movements and operations effectively.

.ifndef MOTOR_S_
.set MOTOR_S_, 1

@ Motor base addresses
.set MOTOR_0_BASEADDR, 0x43C60000  @ Motor connected to the top row pins of PMODC port
.set MOTOR_1_BASEADDR, 0x43C80000  @ Motor connected to the bottom row pins of PMODC port

@ Timer base address
.set TTC0_BASEADDR, 0xF8001000     @ Triple Timer Counter base address

.text

setupMotor:
    @ Initialize motor speed to 0 (motors off)
    mov r0, #0
    str r0, [r1, #0x08]

    @ Set initial motor direction to clockwise (0)
    mov r0, #0
    str r0, [r1, #0x04]

    @ Set PWM frequency to 24.42kHz (100MHz / 4095)
    mov r0, #4095
    str r0, [r1, #0x14]

    @ Enable the H-Bridge
    mov r0, #1
    str r0, [r1]

bx lr  					   @ Return from function

motorSpeed:
    push {r3, r4}          @ Save registers r3 and r4
    mov r3, r2             @ Copy motor speed to r3
    mov r4, #0xFFF         @ Set maximum speed mask (12 bits)
    and r3, r3, r4         @ Mask the speed value
    str r3, [r1, #0x08]    @ Write the speed value to the motor speed register
    pop {r3, r4}           @ Restore registers r3 and r4
bx lr                  	   @ Return from function

motorDirection:
    push {r3, lr}          @ Save register r3 and link register
    ldr r3, [r1, #0x04]    @ Load the current motor direction
    and r3, r3, #1         @ Mask to get the direction bit
    cmp r3, r2             @ Compare current direction with desired direction
    beq leaveMotorDir      @ Skip if the direction is already correct

    push {r2}              @ Save desired direction
    mov r2, #0             @ Set motor speed to 0 before changing direction
    bl motorSpeed       @ Call motorSpeed to stop the motor
    pop {r2}               @ Restore desired direction
    str r2, [r1, #0x04]    @ Write the new direction to the motor direction register

	leaveMotorDir:
    pop {r3, lr}           @ Restore register r3 and link register
bx lr                  	   @ Return from function

setupServo:	
    push {r0, r1}          @ Save registers r0 and r1

    @ Configure clock control: prescaler = 5, f_ttc = 1.7361MHz
    ldr r0, =TTC0_BASEADDR @ Load the base address of the timer
    ldr r1, =0b0001011     @ Set prescaler enable and value
    str r1, [r0]           @ Write to clock control register

    @ Set interval value for 20ms (1.7361MHz * 20ms = 34,722)
    ldr r1, =34722
    str r1, [r0, #0x24]    @ Write interval value to interval register

    @ Set match value for 1.5ms pulse width (1736 * 1.5 = 2604)
    mov r1, #2900
    str r1, [r0, #0x30]    @ Write match value to match register

    @ Configure counter control: enable match and interval
    ldr r1, =0b1001010
    str r1, [r0, #0x0C]    @ Write to counter control register

    pop {r0, r1}           @ Restore registers r0 and r1
bx lr					   @ Return from function

changeAngle:
    push {r0, r2}          @ Save registers r0 and r2

    @ Set the match value to adjust the servo angle
    ldr r0, =TTC0_BASEADDR @ Load the base address of the timer
    str r1, [r0, #0x30]    @ Write the desired angle to the match register

    pop {r0, r2}           @ Restore registers r0 and r2
bx lr                  	   @ Return from function

.endif