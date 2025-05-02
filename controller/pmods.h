////
// Class: EE324 Microprocessors
// Names: Joshua Pizana, Josiah Kumley, Jack Gardner
// Date: 5/1/2025
// Description: This header file provides hardware interface library for manging two input devices. 
// The 4x4 matrix keypad and analog joystick. The keypad functions include initialization,
// raw data scanning, decoding, and blocking keys and special handling for key mappings. The joystick
// functions configure SPI communication and read analog axis positions. The library uses APIs to handle
// the complex matriix scan for the keypad, as well as debouncing and SPI timing. As well as the functions bitIndex
// for further bit manipulation operations. 
////

// Setup/Get Joystick ──────────────────────────────────────────────────────────────────────────
/*
- Initializes joystick hardware interface
- Confiigures SPI commuinication (Mode 0, 1MHz clock) & CS (pin 10)
- Has to be caled before using getJoystick()
*/
void setupJoystick();

/*
- Reads current joystick position and button states
- @param X-axis position (0-1023)
- @param Y-axis position (0-1023)
- @param Button states (future implementation for hot swap to RC freemode)
- Performs SPI to read analog axes and digital buttons.
- Ttiming delays for reliable operation.
 */
void getJoystick(float& x, float& y, int& button);



// Set up Keypad ──────────────────────────────────────────────────────────────────────────
/*
- Initializes keypad pins for 4x4 matrix scanning
- Configures columns as outputs (pins 2-5) and 4 rows as inputs (pins 6-9) to simulate a 12-pin PMOD interface.
*/
void setupKeypad();

/*
- Scans keypad and returns raw button states
- returns 16-bit mask where each bit represents a key (1 = pressed)
- performs full matrix scan by driving each column low and reading rows.
- Bit positions correspond to physical key layout (remapping).
 */
unsigned int getKeypadRaw();

/*
- Gets single pressed key value
- Returns Integer value of pressed key (0-15) or -1 if none pressed
- Gets keypad raw data and converts the bitmask to a logical key value,
- Hardware-specific key mapping.
 */
int getKeypad();

/*
- Blocks until a key is pressed and released
- Return Valid key value (0-15)
- Includes debouncing and key press detection.
 */
int waitForKey();

/*
- Tests a specific bit in an integer
- @param num Input value to test
- @param index Bit position to check (0 = LSB)
- Return true if bit is set, false otherwise
 */
bool bitIndex(int num, unsigned int index);


