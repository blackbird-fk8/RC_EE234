////
// Class: EE324 Microprocessors
// Names: Joshua Pizana, Josiah Kumley, Jack Gardner
// Date: 5/1/2025
// Description: This header file defines WiFi configuration and communication interface for connecting to
// a blackboard. It establishes the network credentials such as the SSID and password for the WiFi connection
// with automatic retry, and for transmitting data strings to the connected blackboard server. This Arduino
// Nano 33 IoT uses WiFiNINA, to be able to wirlessly transmit data to the pre-defined black sever endpoint 
// (192.168.4.1). 
////

// WiFi Network Credentials──────────────────────────────────────────────────────────────────────────
// WiFi network name (SSID) for Blackboard access
#define AP_SSID "blkbrdf8"       
// WiFi network password for Blackboard access
#define AP_PASSWORD "blkbrdf8"

// Blackboard Communication API───────────────────────────────────────────────────────────────────────
// Sets up connection to WiFi and blackboard server
// Implements retry logic
/* 
- 5 second interval between attempts
- Maximum 10 connections
- Debug for connection status
- Requires AP_SSID and AP_PASSWORD
*/
void connectToBlackboard();
// Transmits data to connect blackboard server
void sendBlackboardData(const char data[]);