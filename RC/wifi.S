@ EE234: Microprocessors
@ Authors: Josh Pizana and Josiah Kumley
@ Date: May 1, 2025
@
@ Description:
@ This file contains the configuration and control functions for Wi-Fi
@ communication in the Final Project for EE234: Microprocessors.
@ It provides routines to set up and manage the ESP32 Wi-Fi module,
@ enabling the system to operate as an Access Point (AP) and handle
@ communication with connected devices. The file also includes UART
@ configuration for data transmission and reception.
@
@ Key functionalities include:
@ - Configuring the ESP32 Wi-Fi module to operate as an Access Point (AP).
@ - Setting up UART0 and UART1 for communication with the Wi-Fi module and debugging tools.
@ - Sending and receiving data over UART to manage Wi-Fi commands and responses.
@ - Automating the setup process for the Access Point, including SSID, password, and IP configuration.
@ - Providing utility functions for sending strings, characters, and handling UART FIFO operations.
@
@ This file ensures reliable and efficient Wi-Fi communication, enabling
@ the Final Project to interact with external devices and networks effectively.

.ifndef WIFI_S_
.set WIFI_S_, 1

.include "../src/GPIO.S"        @ Include GPIO functions

@ UART base addresses
.set UART0_BASEADDR, 0xE0000000 @ UART0 base address
.set UART1_BASEADDR, 0xE0001000 @ UART1 base address

.data
@ Station Commands
@ Commands to automate the setup process for the Access Point (AP)
setModeAP:   .ascii "AT+CWMODE=2\r\n\0"                 @ Set Wi-Fi mode to Access Point
setCWSAP:    .ascii "AT+CWSAP=\"blkbrdf8\",\"blkbrdf8\",1,2,4,0\r\n\0" @ Set SSID and password
setAPIP:     .ascii "AT+CIPAP=\"192.168.4.1\",\"192.168.4.1\"\r\n\0"   @ Set static IP for AP
setMux:      .ascii "AT+CIPMUX=1\r\n\0"                 @ Enable multiple connections
setServer:   .ascii "AT+CIPSERVER=1,80\r\n\0"           @ Start server on port 80
sendFromAP:  .ascii "AT+CIPSEND=0,4\r\n\0"              @ Send data from AP

@ Example message format received from Wi-Fi sources
messageReceived: .ascii "+IPD,0,4:1234"                 @ Example message: user 0 sent "1234"

.text

setupWifi:
    push {r0, r1, r2, lr}        @ Save registers

    @ Setup UART0 and UART1 for communication
    ldr r0, =UART0_BASEADDR      @ Load UART0 base address
    bl setupUart                 @ Configure UART0
    ldr r0, =UART1_BASEADDR      @ Load UART1 base address
    bl setupUart                 @ Configure UART1

    @ Configure GPIO pin for ESP32 enable (MIO26)
    ldr r0, =GPIO_BASEADDR       @ Load GPIO base address
    ldr r1, =0x4000000           @ Set bit 26 (ESP32_EN pin)
    str r1, [r0, #0x204]         @ Set pin as output
    str r1, [r0, #0x208]         @ Enable output
    str r1, [r0, #0x40]          @ Drive pin high (enable ESP32)

    @ Initialize network settings
    ldr r2, =UART0_BASEADDR      @ Load UART0 base address

    mov r1, #0b0000000011        @ Update LEDs
    bl outputToLEDs
    ldr r1, =setModeAP           @ Load "Set Mode" command
    bl sendString            	 @ Send command via UART
    bl uartDummyDelay            @ Wait for response

    mov r1, #0b00000111          @ Update LEDs
    bl outputToLEDs
    ldr r1, =setCWSAP            @ Load "Set SSID and Password" command
    bl sendString            	 @ Send command via UART
    bl uartDummyDelay            @ Wait for response

    mov r1, #0b0000011111        @ Update LEDs to indicate progress
    bl outputToLEDs              @ Output the LED status
    ldr r1, =setCWSAP            @ Load "Set SSID and Password" command
    bl sendString            	 @ Send command via UART
    bl uartDummyDelay            @ Wait for the command to complete

    mov r1, #0b0001111111        @ Update LEDs
    bl outputToLEDs
    ldr r1, =setMux              @ Load "Set Multiplexing" command
    bl sendString            	 @ Send command via UART
    bl uartDummyDelay            @ Wait for response

    mov r1, #0b0011111111        @ Update LEDs
    bl outputToLEDs
    ldr r1, =setServer           @ Load "Start Server" command
    bl sendString            	 @ Send command via UART
    bl uartDummyDelay            @ Wait for response

    mov r1, #0b1111111111        @ Update LEDs
    bl outputToLEDs
    ldr r1, =sendFromAP          @ Load "Send Data" command
    bl sendString            	 @ Send command via UART
    bl uartDummyDelay            @ Wait for response

    mov r1, #0                   @ Clear LEDs
    bl outputToLEDs

    pop {r0, r1, r2, lr}         @ Restore registers

bx lr                            @ Return from function

setupUart:
    @ Reset the UART controller
    mov r1, #0b1101011
    str r1, [r0]

    @ Set the BAUDGEN clock divider (115200 baud)
    mov r1, #124
    str r1, [r0, #0x18]

    @ Set the Baud Rate Divider for bit-clock
    mov r1, #6
    str r1, [r0, #0x34]

    @ Enable transmitter, receiver, and reset
    mov r1, #0b100010111
    str r1, [r0]

    @ Configure mode: 8-bit, no parity, 1 stop bit
    mov r1, #0b0000100000
    str r1, [r0, #0x04]

    @ Set timeout to 1
    mov r1, #1
    str r1, [r0, #0x1C]

    @ Disable all interrupts
    mov r1, #0xFFF
    str r1, [r0, #0x0C]

bx lr                            @ Return from function

sendString:
    push {r2, r3, lr}            @ Save registers
    ldr r0, =UART0_BASEADDR      @ Load UART0 base address
    mov r2, #0                   @ Initialize string index

    send_string:
        ldrb r3, [r1, r2]            @ Load the next character
        cmp r3, #0                   @ Check for null terminator
        beq end_send_string          @ Exit if end of string

        waitForTX:
            ldr r4, [r0, #0x2C]          @ Check TX FIFO status
            and r4, r4, #0b10000         @ Mask TX FIFO full bit
            cmp r4, #0                   @ Check if FIFO is full
            bne waitForTX                @ Wait if FIFO is full

        push {r1}                    @ Save r1
        mov r1, r3                   @ Move character to r1
        bl sendChar              	 @ Send character
        pop {r1}                     @ Restore r1

        add r2, r2, #1               @ Increment string index
 
    b send_string                	 @ Repeat for next character

    end_send_string:
        pop {r2, r3, lr}             @ Restore registers
        bx lr                        @ Return from function

sendChar:
    push {r0, lr}                @ Save registers
    ldr r0, =UART0_BASEADDR      @ Load UART0 base address
    str r1, [r0, #0x30]          @ Write character to TX buffer
    pop {r0, lr}                 @ Restore registers
bx lr                            @ Return from function

sendCharPutty:
    push {r0}                    @ Save register
    ldr r0, =UART1_BASEADDR      @ Load UART1 base address
    str r1, [r0, #0x30]          @ Write character to TX buffer
    pop {r0}                     @ Restore register
bx lr                            @ Return from function

recieveChar:
    push {r1, r2, lr}            @ Save registers
    ldr r0, =UART0_BASEADDR      @ Load UART0 base address
    mov r1, #0                   @ Initialize r1

waitForRX:
    ldr r2, [r0, #0x2C]          @ Check RX FIFO status
    and r2, r2, #0b10            @ Mask RX FIFO empty bit
    cmp r2, #0                   @ Check if FIFO is empty
    bne waitForRX                @ Wait if FIFO is empty

    ldr r0, [r0, #0x30]          @ Read character from RX buffer
    mov r1, r0                   @ Move character to r1
    bl sendCharPutty             @ Send character to Putty
    pop {r1, r2, lr}             @ Restore registers
bx lr                            @ Return from function

checkFIFO:
    push {r1}                    @ Save register
    ldr r0, =UART0_BASEADDR      @ Load UART0 base address
    ldr r1, [r0, #0x2C]          @ Read FIFO status
    and r1, r1, #0b10            @ Mask RX FIFO empty bit
    mov r0, r1                   @ Move result to r0
    pop {r1}                     @ Restore register
bx lr                            @ Return from function

uartDummyDelay:
    push {r1}                    @ Save register
    ldr r1, =#0x4FFFFFF          @ Load delay count
uartDummyDelayLoop:
    sub r1, r1, #1               @ Decrement delay count
    cmp r1, #0                   @ Check if delay is complete
    bne uartDummyDelayLoop       @ Repeat if not complete
    pop {r1}                     @ Restore register
bx lr                            @ Return from function

.endif