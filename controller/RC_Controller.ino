////
// Class: EE324 Microprocessors
// Names: Joshua Pizana, Josiah Kumley, Jack Gardner
// Date: 5/1/2025
// Description: Controller code is designed to transmit/send commands from a keypad & joycon 
// NINA WiFi to the RC that takes the commands via BLACKBOARD. As well as providing visual feedback using an
// 128x64 OLED display. The controller system uses a keypad and analog joystick to capture user inputs, which are
// then converted into 4 character hexadecimal commands. The commands are further then transmitted via WiFi
// to a central blackboard server using WiFiNINA library, to obtain a connection to gain access point with SSID
// blkbrdf8. The joystick allows directional control, assigning codes for movements left, right, up, down & brake.
// While the keypad uses inputs read as hex 0-F. Visual Feedback was also incorprated through the OLED display that
// shows a animation startup to indicate the 33 IoT has powered on. Followed by the startup are directional commands
// for each joystck movement. Shown as arrows for each direction and a brake indicator. The system ensures
// to only send updated commands to avoid reduendent transmissions. 
////
#include "wifi.h"
#include "pmods.h"
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <Wire.h>
#include <string.h>

// OLED configuration ──────────────────────────────────────────────────────────────────────────
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_RESET     -1
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

// Thresholds for joysticks ────────────────────────────────────────────────────────────────────
#define lower_thresh 250
#define higher_thresh 750

// Input state
int key;
bool keyPressed = false;

float x;
float y;
int b;

// Initial values set to zero to avoid garbage values ────────────────────────────────────────────
String joystickCommand = "0000";
String prevJoystickCommand = "0000";
String command = "0000";
byte commandIndex = 0;

// Set time stamp with an initial value zero
long sendTimestamp = 0;

// ────────────────────────────────────────────────────────────────────────────────────────────────
// "Draw" stick figure poses using x, y, and scale to animate on screen with different poses
//  since each animation needs to be manually made on each pixle, difficult but hey it works!
void drawStickmanPose(int x, int y, int scale, int pose) {
  // circle as head of stick figure
  display.drawCircle(x, y, 3 * scale, SSD1306_WHITE);

  // line as body of stick figure
  display.drawLine(x, y + 3 * scale, x, y + 12 * scale, SSD1306_WHITE);

  // lines as arms of stick figure (with different poses)
  if (pose % 2 == 0) {
    // straight arms of stick figure
    display.drawLine(x - 5 * scale, y + 6 * scale, x + 5 * scale, y + 6 * scale, SSD1306_WHITE);
  } 
  else {
    // upward arms of stick figure
    display.drawLine(x, y + 6 * scale, x - 4 * scale, y + 2 * scale, SSD1306_WHITE);
    display.drawLine(x, y + 6 * scale, x + 4 * scale, y + 2 * scale, SSD1306_WHITE);
  }

  // legs of stick figure (different stance on display)
  if (pose % 2 == 0) {
    display.drawLine(x, y + 12 * scale, x - 4 * scale, y + 18 * scale, SSD1306_WHITE);
    display.drawLine(x, y + 12 * scale, x + 4 * scale, y + 18 * scale, SSD1306_WHITE);
  } else {
    // kicking pose for animation at end (essentially its supposed to be like kungfu/street fighter
    // but uh, I tried)
    display.drawLine(x, y + 12 * scale, x - 6 * scale, y + 14 * scale, SSD1306_WHITE);
    display.drawLine(x, y + 12 * scale, x + 2 * scale, y + 18 * scale, SSD1306_WHITE);
  }
}


void startupAnimation() {
  // set initial positions for left & right figures on display
  int startLeft = 10; // start of X position for left stick figure
  int startRight = SCREEN_WIDTH - 10; // start of Y position for right stick figure
  int y = 18; // the base position for both stick figures

  // animation loop: this loop runs 6 times to display a "crisp" & "all natural 4k" intro
  for (int i = 0; i < 6; i++) {
    display.clearDisplay(); // clear the display for next animation to display

    // "zoom in" effect by increasing the scale of the screen after 3 iterations
    // scale will alternate between 1 (small) & 2 (large)
    int scale = 1 + (i / 3); // either 1 or 2 // i/3 will evaluate to 0 for the first 3 frames or 
    // 1 (last 3 frames). 

    // to animate the motion of teh stick figure: will move right by (+i*3) & up by (-i)
    drawStickmanPose(startLeft + i * 3, y - i, scale, i);
    // to animate the motion of teh stick figure: will move right by (-i*3) & up by (-i)
    drawStickmanPose(startRight - i * 3, y - i, scale, i);

    display.display();  // render the frame
    delay(150); // short pause for animation effect (150ms per frame)
  }

  // Zoom-in hold with final pose
  // Creates a "on/off or flicker effect" effect and display "READY" with the stick figures in their final pose
  for (int flicker = 0; flicker < 3; flicker++) {
    display.clearDisplay(); // Clears the display to refresh the display
    // centers the position for the final pose of the stick figures
    // left stick figure positioned at (30,10), scale 2, pose 1 (arms raised)
    // right stick figure code positioned at (screen width - 30, 10), scale 2, pose 0 (arms straight)
    drawStickmanPose(30, 10, 2, 1);
    drawStickmanPose(SCREEN_WIDTH - 30, 10, 2, 0);

    // display "on/off or flicker effect" on every iiteration to create the  effect
    if (flicker % 2 == 0) {
      display.setTextSize(2); // large text size
      display.setTextColor(SSD1306_WHITE);  // white text
      display.setCursor((SCREEN_WIDTH - 70) / 2, 45); // center text horizontally
      display.print("READY"); // display the "READY" message
    }

    display.display();  // render frame
    delay(200); // delay to make the message visible for 200ms per frame
  }

  // final dramatic pose hold
  // show final pose with ready text for a longer period
  display.clearDisplay();
  // re-animate the stick figures in final position
  drawStickmanPose(30, 10, 2, 1);
  drawStickmanPose(SCREEN_WIDTH - 30, 10, 2, 0);
  // display the "READY" text constantly 
  display.setTextSize(2);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor((SCREEN_WIDTH - 70) / 2, 45);
  display.print("READY");
  display.display(); // render final frame
  delay(1500); // delay to hold the frame

  // clear to prepare the system for wifi then commands or debugging 
  display.clearDisplay();
  display.display();
}

// ──────────────────────────────────────────────────────────────────────────────────────────────────
// Animated Arrow Function
// animates the direction of the arrows on the OLED display for left, right, up, down and brake using param direction
// string to specify it
void animateArrow(String direction) {
  const int cycles = 3; // animation cycles (3-cycles)
  const int shift = 3;  // pixle offset for bouncing effect
  int x = 48, y = 16; // sets base posistion for arrow animation

  for (int i = 0; i < cycles; i++) {
    display.clearDisplay();
    display.setTextSize(3); // sets large text for the arrows
    display.setTextColor(SSD1306_WHITE);

    // if statement handles the different directions with offset positions
    if (direction == "left") {
      display.setCursor(x - shift, y);  // shift left for bounce effect
      display.print("<");
    } else if (direction == "right") {
      display.setCursor(x + shift, y);  // shift right
      display.print(">");
    } else if (direction == "up") {
      display.setCursor(x, y - shift);  // shift up
      display.print("^");
    } else if (direction == "down") {
      display.setCursor(x, y + shift);  // shift down
      display.print("v");
    } else if (direction == "brake") {  
      display.setTextSize(2); // // smaller text for brake
      display.setCursor(20, y); // centered brake position on display 
      display.print("BRAKE");
      display.display();
      delay(500); // show brake for 500ms
      return; // exits brake
    }

    display.display();  // displays offset position
    delay(100); 
    // returns the center position for bounce effect 
    display.clearDisplay();
    display.setCursor(x, y);
    display.print(
      direction == "left" ? "<" : // ternary operator to select the related symbol for the directions
      direction == "right" ? ">" :
      direction == "up" ? "^" :
      direction == "down" ? "v" : ""
    );
    display.display();
    delay(100); // to display in center position
  }
}

// ─────────────────────────────────────────────────────────────────────────────────────────────────────
void setup() {
  Serial.begin(9600);

  // OLED init
  if (!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
    Serial.println(F("OLED failed"));
    while (true);
  }
  display.clearDisplay();
  startupAnimation();

  // WiFi + device connection
  connectToBlackboard();
  sendBlackboardData("F1F0");

  setupKeypad();
  setupJoystick();
}

// ────────────────────────────────────────────────────────────────────────────────────────────────
// Main loop (continous)
// keypad input, joystick, display joystick commands, sends commands to blacboard, visual feedback
void loop() {
  // handles the iinput of the keypad
  key = getKeypad(); // reads current keypad state (-1 if no key is pressed)

  // if a valid key is pressed and not already processed
  if (key != -1 && !keyPressed) {
    // converts the key value to ASCII character
    // Numbers 0-9 as '0' - '9' (key + '0')
    // values 10-15 as 'A' - 'F' (key + 0x37)
    command[commandIndex] = (key < 0xA) ? (key + '0') : (key + 0x37);
    commandIndex++; // move to next character position
    keyPressed = true;  // mark key as processed
  }

  // if statement for 4 character command buffer is full
  if (commandIndex == 4) {
    commandIndex = 0;
    Serial.println(command);
    sendBlackboardData(command.c_str());
  }

  // key release detection 
  if (key == -1 && keyPressed) {
    keyPressed = false;
  }

// Joystick Input ──────────────────────────────────────────────────────────────────────────
  getJoystick(x, y, b); // updates joystick position (x,y) and button state (b)

  // X - axis direction logic ─────────────────────────────────────
  if (x < lower_thresh) {
    joystickCommand = "4000"; // left command
  } else if (x > higher_thresh) {
    joystickCommand = "4100"; // right command
  } else {
    joystickCommand = "4400"; // brake command (default command essentially idle)
  }

  // Y - axis direction logic (will override the X - axis commands when active by user input)
  if (y < lower_thresh) {
    joystickCommand = "4300"; //down command
  } else if (y > higher_thresh) {
    joystickCommand = "4200"; // up command
  // reverts to brake if no direction input
  } else if (joystickCommand != "4000" && joystickCommand != "4100") {
    joystickCommand = "4400"; // brake command
  }

  // Command processing ──────────────────────────────────────────────────────────────────────────
  // if statement will only execute if the command has changed from the previous iterations
  if (joystickCommand != prevJoystickCommand) {
    sendBlackboardData(joystickCommand.c_str());  // new command
    Serial.println(joystickCommand);  // debugging output

    prevJoystickCommand = joystickCommand; // store the current command

    // Visual Feedback System ─────────────────────────────────────────────────────────────────────
    // plays the arrow animations to its respective command
    if (joystickCommand == "4000") {
      animateArrow("left"); // animate left arrow
    } else if (joystickCommand == "4100") {
      animateArrow("right");  // animate right arrow
    } else if (joystickCommand == "4200") {
      animateArrow("up"); // animate up arrow
    } else if (joystickCommand == "4300") {
      animateArrow("down"); // animate down arrow
    } else if (joystickCommand == "4400") {
      animateArrow("brake");  // display BRAKE text
    }
  }
}