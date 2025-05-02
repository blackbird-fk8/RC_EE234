@ EE234: Microprocessors
@ Authors: Josh Pizana and Josiah Kumley
@ Date: May 1, 2025
@
@ Description:
@ This file serves as the main entry point for the Final Project in EE234: Microprocessors.
@ It orchestrates the initialization and execution of various subsystems, including GPIO,
@ motors, Wi-Fi, and ROBOMAL instructions. The file defines the main program loop,
@ which processes user inputs, executes commands, and manages different operational modes.
@
@ Key functionalities include:
@ - Initializing hardware components such as motors, servos, seven-segment displays, and Wi-Fi modules.
@ - Managing operational modes, including autonomous, remote control, line following, and programmable modes.
@ - Handling user inputs from switches, buttons, and Wi-Fi commands.
@ - Executing ROBOMAL instructions for controlling the robot's behavior.
@ - Providing a flexible framework for switching between modes and executing corresponding instruction sets.
@
@ This file ensures seamless integration of all subsystems, enabling the
@ Final Project to perform complex tasks and respond to user inputs effectively.

.global main
.global functionMode

.global command
.global readCommand
.global lineInstruct
.global autoInstruct

.include "../src/robomal.S"      @ Include ROBOMAL functionality
.include "../src/commands.S"     @ Include command definitions
.include "../src/GPIO.S"         @ Include GPIO functions
.include "../src/motor.S"        @ Include motor control functions
.include "../src/wifi.S"         @ Include Wi-Fi functions

.data

command: .hword 1,1,1,1          @ Command storage
readCommand: .hword 0x4400       @ Command read buffer
functionMode: .hword 0xEE00      @ Current function mode

@ Autonomous mode instructions and data
autoInstruct: .hword 0x4400, 0x3412, 0x4202, 0x3412, 0x4202, 0x4304, 0x3412, 0x4204, 0x3415, 0x3300
autoData: .hword 0x1111          @ Autonomous mode data

@ Remote control mode instructions and data
remtInstruct: .hword 0x4400, 0x3300
remtData: .hword 0x1111          @ Remote control mode data

@ Line following mode instructions and data
lineInstruct: .hword 0x1400, 0x4400, 0x1500, 0x3300
lineData: .hword 0x1111          @ Line following mode data

@ Programmable mode instructions and data
progInstruct: .hword 0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300, 0x3300
progData: .hword 0x1111          @ Programmable mode data
progIndex: .hword 0x0            @ Index for programmable mode

.text

main:
    mov r1, #0                  @ Initialize PMOD row
    mov r2, #1                  @ Set PMOD mode to output
    bl setupPmod                @ Configure PMOD for output
    mov r2, #0                  @ Set PMOD mode to input
    bl setupPmod                @ Configure PMOD for input

    bl setupSVNSEG              @ Initialize seven-segment display
    bl setupWifi           	    @ Initialize Wi-Fi host

    ldr r1, =MOTOR_0_BASEADDR   @ Load motor 0 base address
    bl setupMotor               @ Initialize motor 0

    ldr r1, =MOTOR_1_BASEADDR   @ Load motor 1 base address
    bl setupMotor               @ Initialize motor 1

    bl setupServo               @ Initialize servo motor

mainloop:
    @ Check if FIFO has data, otherwise skip trying to get a command
    bl checkFIFO
    cmp r0, #0
    bne skipUart

    @ Check if there is a command to be read
    bl checkForCommand

skipUart:
    @ Get switch states and store to functionMode memory location
    ldr r0, =readCommand
    ldrh r0, [r0]
    and r1, r0, #0xFF00
    cmp r1, #0xEE00
    bne continueMain

    ldr r1, =functionMode
    strh r0, [r1]

continueMain:
    ldr r0, =functionMode
    ldrh r0, [r0]

    @ Determine which instruction set to perform
    mov r1, #0xEE00
    cmp r0, r1
    beq mainloop                @ No mode

    mov r1, #0xEE01
    cmp r0, r1
    beq instructSet_Noll        @ Autonomous mode

    mov r1, #0xEE02
    cmp r0, r1
    beq instructSet_Ett         @ Remote-control mode

    mov r1, #0xEE03
    cmp r0, r1
    beq instructSet_Tva         @ Line following mode

    mov r1, #0xEE04
    cmp r0, r1
    beq instructSet_Tre         @ Programmable mode

    mov r1, #0xEE05
    cmp r0, r1
    ldreq r2, =progIndex        @ Reset programming index
    moveq r3, #0
    streqh r3, [r2]
    beq instructSet_Fyra        @ Programmable execution mode

    b mainloop

instructSet_Noll:               @ Autonomous mode
    ldr r1, =autoInstruct       @ Load autonomous instructions
    b continueToExecute

instructSet_Ett:                @ Remote-control mode
    ldr r2, =readCommand        @ Load readCommand address
    ldrh r2, [r2]               @ Read command value
    ldr r1, =remtInstruct       @ Load remote instructions
    bl skipCheck                @ Skip invalid commands
    cmp r0, #1                  @ Check if command is valid
    beq instructSet_EttSkip
    strh r2, [r1]               @ Store command in instructions
instructSet_EttSkip:
    b continueToExecute

instructSet_Tva:                @ Line following mode
    ldr r1, =lineInstruct       @ Load line following instructions
    ldr r2, =lineData           @ Load line following data
    b continueToExecute

instructSet_Tre:                @ Programmable mode programming
    ldr r2, =readCommand        @ Load readCommand address
    ldrh r2, [r2]               @ Read command value
    ldr r1, =progInstruct       @ Load programmable instructions
    cmp r2, #0                  @ Check if command is 0
    beq mainloop                @ Return to mainloop if no command
    bl skipCheck                @ Skip invalid commands
    cmp r0, #1                  @ Check if command is valid
    beq instructSet_EttSkip
    ldr r4, =progIndex          @ Load programmable index
    ldrh r4, [r4]               @ Read current index
    cmp r4, #32                 @ Check if index exceeds limit
    beq executeProg             @ Execute program if limit reached
    lsl r4, r4, #1              @ Multiply index by 2
    strh r2, [r1, r4]           @ Store command in instructions
    mov r5, #0                  @ Clear readCommand
    ldr r6, =readCommand
    strh r5, [r6]
    lsr r4, r4, #1              @ Divide index by 2
    add r3, r4, #1              @ Increment index
    ldr r4, =progIndex
    strh r3, [r4]               @ Update index
    mov r3, #0x3300             @ Check for end of program
    cmp r2, r3
    bne continueToGetInstruct

executeProg:
    ldr r0, =functionMode       @ Load functionMode address
    mov r1, #0xEE05             @ Set to execution mode
    strh r1, [r0]

continueToGetInstruct:
    b mainloop

instructSet_Fyra:               @ Programmable mode execution
    ldr r1, =progInstruct       @ Load programmable instructions
    ldr r2, =progData           @ Load programmable data
    b continueToExecute

continueToExecute:
    bl runRobomal               @ Execute ROBOMAL instructions
    b mainloop                  @ Return to mainloop

skipCheck:
    push {r3, r4}               @ Save registers
    mov r3, #0x0113             @ Check for informational commands
    cmp r2, r3
    moveq r0, #1
    mov r3, #0x0CE7
    cmp r2, r3
    moveq r0, #1
    mov r3, #0xF1F0
    cmp r2, r3
    moveq r0, #1
    mov r3, #0x0405
    cmp r2, r3
    moveq r0, #1
    mov r3, #0x2235
    cmp r2, r3
    moveq r0, #1
    mov r3, #0x0110
    cmp r2, r3
    moveq r0, #1
    mov r4, r2
    mov r3, #0xFF00
    and r4, r4, r3
    mov r3, #0xEE00
    cmp r4, r3
    moveq r0, #1
    pop {r3, r4}                @ Restore registers
    bx lr                       @ Return from function

.end