@ EE234: Microprocessors
@ Authors: Josh Pizana and Josiah Kumley
@ Date: May 1, 2025
@
@ Description:
@ This file contains the configuration and control functions for the
@ Global Timer Counter (GTC) used in the Final Project for EE234: Microprocessors.
@ The GTC is utilized for generating precise timing intervals and managing
@ timer-based operations, such as delays and periodic interrupts.
@
@ Key functionalities include:
@ - Configuring the Global Timer Counter with adjustable comparator values for timing intervals.
@ - Setting up the timer's prescaler and enabling the timer for operation.
@ - Writing to the comparator and autoincrement registers to define timer behavior.
@ - Providing utility functions to manage timer-based events efficiently.
@
@ This file ensures accurate and reliable timing operations, enabling
@ the Final Project to perform time-sensitive tasks effectively.

.ifndef TIMER_S_
.set TIMER_S_, 1

@ Global Timer Counter (GTC) base address
.set GTC_BASEADDR, 0xF8F00200

@ Comparator values for timer interrupts
.set GTC_COMPARATOR_ONESEC, 1302082  @ Comparator value for a 1-second period
.set GTC_COMPARATOR, 1302082         @ Default comparator value (adjustable)

.text

configureGtc:
    push {r0, r1}               @ Save registers r0 and r1

    ldr r0, =GTC_BASEADDR       @ Load the base address of the Global Timer Counter

    ldr r1, =GTC_COMPARATOR     @ Load the comparator value
    str r1, [r0, #0x10]         @ Set the comparator register
    str r1, [r0, #0x18]         @ Set the autoincrement register
    mov r1, #0                  @ Clear the comparator increment value
    str r1, [r0, #0x14]         @ Write to the comparator increment register

    ldr r1, =#0xFF0F            @ Configure prescaler and enable the timer
    str r1, [r0, #0x8]          @ Write to the control register

    pop {r0, r1}                @ Restore registers r0 and r1
    bx lr                       @ Return from the function

.endif