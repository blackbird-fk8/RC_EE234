# EE234 Final Project 
Team: Deck Of Jacks
- Contributors
    - Joshua Pizana
    - Josiah Kumley
    - Jack Gardner
- Description: This repsitory contains the ARM assembly code for an RC robot and controller system for the final project for EE324: Microprocessor Systems. The project features wirless communication (ESP32 WiFi), 12V-DC brushless motor, SERVO control steering, and IR sensors for Line following and collision detection. Multiple operation modes are supported, such as: autonomous, remote control, line-following, programmable, and execution. The controller, an Arduino Nano IoT 33, has a 4x4 matrix keypad and an analog joystick for user input. The commands are converted into 4-character hexadecimal strings, which are then transmitted via WiFi to the Blackboard on the RC using the WiFiNINA Library. This controller code also implements a 128x64 OLED display that provides visual feedback with directional arrows, animations, and a startup sequence with stick figure graphics.

- Demonstration Video: https://youtu.be/6OfPX8mVC1E
