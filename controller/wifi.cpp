

// Include files
#include "wifi.h"
#include <WiFiNINA.h>

// Network Configuration──────────────────────────────────────────────────────────────────────────
char ssid[] = AP_SSID;                // Network SSID (Service Set Identifier)
char pass[] = AP_PASSWORD;           // Network password (WPA2)

// Blackboard server IP address with local access point (192.168.4.1)
byte blackboardAccessPoint[4] = {192,168,4,1};

// Global Network Variable ────────────────────────────────────────────────────────────────────────
int status = WL_IDLE_STATUS;          // Current WiFi connection status
WiFiClient blackboard;                // TCP client for blackboard communication

// WiFi Connection Managment ──────────────────────────────────────────────────────────────────────
// Established connection to WiFi and Blackboard server
// Attempts to connect up to 10 times with a 5 second interval
/*
- Sucessfully connected:
  - Prints Local and gateway IP adresses 
  - Established TCP connection to blackboard on port 80

- Failed to connect:
  - Prints error message to serial monitor
*/
void connectToBlackboard() {
  byte count = 0;

  // Connection loop (for attempt)
  while (status != WL_CONNECTED && count != 10) { // wait until connected, or until 10 failed attempts
    Serial.print("Attempting to connect to network: "); // displays current status attempt to connect to network
    Serial.println(ssid); // prints to serial monitor (prints ssid)
    status = WiFi.begin(ssid, pass);  // uses defined ssid&pass from h file to look for blacboard
    delay(5000); // wait 5 seconds between the 10 attempts
    count++;
  }
  
  if(count != 10) {
    // If connection is successful display Local IP and Gateway IP in serial monitor
    Serial.print("Local IP: "); // displays local IP
    Serial.println(WiFi.localIP());
    Serial.print("Gateway IP: "); // displays gateway IP
    Serial.println(WiFi.gatewayIP());

    // TCP connection to Blackboard
    if(blackboard.connect(blackboardAccessPoint,80)) {
      Serial.println("Connected to access point"); // prints if connected to access point
    } else {
      Serial.println("Failed to connect to access point"); // prints if failed to connect to acess point
    }

  } 
  // Prints to serial mointor to indicate Failed to join Network
  else { 
    Serial.println("Failed to join the network");
  }

}

// Data Transmission──────────────────────────────────────────────────────────────────────
// Sends data string to Blackboard server, sent as raw data for blackboard handling
void sendBlackboardData(const char data[]) {
  blackboard.write(data);
}