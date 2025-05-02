# EE234 Final Project 
Team: Deck Of Jacks
- Contributors
    - Joshua Pizana
    - Josiah Kumley
    - Jack Gardner
Description: This repsitory contains the ARM assembly code for a RC robot system final project for EE324: Microprocessors. The project features wirless communication (ESP32 WiFi), 12V-DC brushless motor, SERVO control steering, IR sensors for Line following and collision detection. Multiple operations are supported, such as autonomous, line-following, programmable execution. As well it contains the Controller code, that is based on a Arduino Nano IoT 33. The controller has a 4x4 matrix keypad and analog joystick for user input, that converts commands into 4-character hexadecimal strings transmitted via WiFi using the WiFiNINA Library. Connects to "blkbrdf8" newtwork and communicates with the blackboard server at 192.168.4.1 with autoconnection attempts. This controller code also implements a 128x64 OLED display that provides visual feedback with directional arrows and animations and a startup sequence with a stick figure graphics. 
Demonstration Video: https://youtu.be/6OfPX8mVC1E
