@ EE234: Microprocessors
@ Authors: Josh Pizana and Josiah Kumley
@ Date: May 1, 2025
@
@ Description:
@ This file contains interrupt handlers for the Final Project in EE234: Microprocessors.
@ It includes handlers for the Global Timer Interrupt (IRQ ID: 27) and GPIO Button Interrupts (IRQ ID: 52).
@ These handlers are designed to manage specific events such as timer-based operations and button presses.
@ The file also includes necessary library imports for Generic Interrupt Controller (GIC), Timer, GPIO, and Wi-Fi functionalities.

.ifndef HANDLER_S_               @ Prevent multiple inclusions of this file
.set HANDLER_S_, 1

@ Include necessary libraries
.include "../src/gic.S"          @ Include Generic Interrupt Controller functions
.include "../src/timer.S"        @ Include Timer functions
.include "../src/GPIO.S"         @ Include GPIO functions
.include "../src/wifi.S"         @ Include Wi-Fi functions

.text

@ Handler for Global Timer Interrupt (IRQ ID: 27)
@ Description: This interrupt is triggered by the global timer.
gic_IRQID27:
    push {lr}                    @ Save the link register (return address)
    
    pop {lr}                     @ Restore the link register
    bx lr                        @ Return from the interrupt

@ Handler for GPIO Button 4 Interrupt (IRQ ID: 52, Subcase: Button 4)
@ Description: This interrupt is triggered when Button 4 is pressed.
gic_IRQID52_BTN4:
    
    bx lr                        @ Return from the interrupt

@ Handler for GPIO Button 5 Interrupt (IRQ ID: 52, Subcase: Button 5)
@ Description: This interrupt is triggered when Button 5 is pressed.
gic_IRQID52_BTN5:
    
    bx lr                        @ Return from the interrupt

.endif