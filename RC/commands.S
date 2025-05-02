@ EE234: Microprocessors
@ Authors: Josh Pizana and Josiah Kumley
@ Date: May 1, 2025
@
@ Description:
@ This file contains the implementation of command handling for the
@ Final Project in EE234: Microprocessors. It provides routines to
@ process incoming commands from the UART interface and convert them
@ into actionable instructions. The file includes functionality to
@ parse commands, validate their format, and store them for execution
@ by other subsystems.
@
@ Key functionalities include:
@ - Receiving and processing commands from the UART interface.
@ - Parsing commands into a standardized format for further processing.
@ - Validating command structure and converting ASCII characters to numerical values.
@ - Storing parsed commands in a buffer for execution by the main program loop.
@ - Providing utility functions to output command status codes to the seven-segment display.
@
@ This file ensures reliable and efficient command handling, enabling the
@ Final Project to respond dynamically to user inputs and external devices.

.ifndef COMMANDS_S_
.set COMMANDS_S_, 1

.include "../src/wifi.S"        @ Include Wi-Fi functions
.include "../src/GPIO.S"        @ Include GPIO functions

.data

.text

@ Command Status Codes
@ 0113 -> Ready to connect
@ 0CE7 -> Connecting
@ F1F0 -> Connected
@ 0405 -> Connection closed

checkForCommand:
    push {r0, r1, r2, r3, lr}   @ Save registers

    bl recieveChar          @ Receive a character from UART
    cmp r0, #0x3A               @ Check if the character is ':'
    bne leaveCheckForCommand    @ Exit if not ':'

    ldr r1, =command            @ Load the address of the command buffer

    @ Get the first character from UART FIFO buffer
    bl recieveChar          @ Receive a character
    cmp r0, #0x39               @ Check if the character is <= '9'
    suble r0, r0, #0x30         @ Convert ASCII to decimal if <= '9'
    subgt r0, r0, #0x37         @ Convert ASCII to decimal if > '9'
    str r0, [r1]                @ Store the character in the command buffer

    @ Get the second character from UART FIFO buffer
    bl recieveChar          @ Receive a character
    cmp r0, #0x39               @ Check if the character is <= '9'
    suble r0, r0, #0x30         @ Convert ASCII to decimal if <= '9'
    subgt r0, r0, #0x37         @ Convert ASCII to decimal if > '9'
    str r0, [r1, #1]            @ Store the character in the command buffer

    @ Get the third character from UART FIFO buffer
    bl recieveChar          @ Receive a character
    cmp r0, #0x39               @ Check if the character is <= '9'
    suble r0, r0, #0x30         @ Convert ASCII to decimal if <= '9'
    subgt r0, r0, #0x37         @ Convert ASCII to decimal if > '9'
    str r0, [r1, #2]            @ Store the character in the command buffer

    @ Get the fourth character from UART FIFO buffer
    bl recieveChar          @ Receive a character
    cmp r0, #0x39               @ Check if the character is <= '9'
    suble r0, r0, #0x30         @ Convert ASCII to decimal if <= '9'
    subgt r0, r0, #0x37         @ Convert ASCII to decimal if > '9'
    str r0, [r1, #3]            @ Store the character in the command buffer

    @ Combine the four characters into a single command number
    mov r0, #0                  @ Initialize the command number
    ldrh r2, [r1]               @ Load the first character
    and r2, #0xF                @ Mask the lower 4 bits
    orr r0, r0, r2              @ Add to the command number
    lsl r0, #4                  @ Shift left by 4 bits

    ldrh r2, [r1, #1]           @ Load the second character
    and r2, #0xF                @ Mask the lower 4 bits
    orr r0, r0, r2              @ Add to the command number
    lsl r0, #4                  @ Shift left by 4 bits

    ldrh r2, [r1, #2]           @ Load the third character
    and r2, #0xF                @ Mask the lower 4 bits
    orr r0, r0, r2              @ Add to the command number
    lsl r0, #4                  @ Shift left by 4 bits

    ldrh r2, [r1, #3]           @ Load the fourth character
    and r2, #0xF                @ Mask the lower 4 bits
    orr r0, r0, r2              @ Add to the command number

    ldr r1, =readCommand        @ Load the address of the readCommand variable
    mov r2, #0xFFFF             @ Mask the lower 16 bits
    and r0, r0, r2              @ Apply the mask
    strh r0, [r1]               @ Store the command in readCommand

    mov r1, r0                  @ Copy the command to r1
    bl outputSVNSEG           	@ Output the command to the seven-segment display

leaveCheckForCommand:
    pop {r0, r1, r2, r3, lr}    @ Restore registers
    bx lr                       @ Return from the function

.endif