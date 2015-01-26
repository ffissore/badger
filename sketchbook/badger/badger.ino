/*
 Badger, an RFID tracker made with Arduino
 Copyright (C) 2015 Federico Fissore
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include <Bridge.h>
#include <Process.h>
#include <Wire.h>
#include <Adafruit_NFCShield_I2C.h>

#define LOG_SCRIPT "/root/log "

#define IRQ   (6)
#define RESET (3)  // Not connected by default on the NFC Shield

#define GREEN_LED 10
#define RED_LED 9
#define BUZZER 8

Adafruit_NFCShield_I2C nfc(IRQ, RESET);

void setup() {
  pinMode(GREEN_LED, OUTPUT);
  pinMode(RED_LED, OUTPUT);
  pinMode(BUZZER, OUTPUT);

  digitalWrite(GREEN_LED, HIGH);
  digitalWrite(RED_LED, HIGH);
  digitalWrite(BUZZER, LOW);

  Serial.begin(115200);

  Bridge.begin();

  nfcBegin();

  digitalWrite(GREEN_LED, LOW);
  digitalWrite(RED_LED, LOW);
}

void loop() {
  uint32_t uid = readUID();

  if (uid == 0) {
    return;
  }

  boolean success = logUID(uid);

  if (success) {
    notifySuccess();
  } else {
    notifyFailure();
  }
}

void nfcBegin() {
  nfc.begin();

  uint32_t versiondata = nfc.getFirmwareVersion();
  if (! versiondata) {
    while (1); // halt
  }
  // configure board to read RFID tags
  nfc.SAMConfig();
}

void buzzFor(uint32_t ms) {
  digitalWrite(BUZZER, HIGH);
  delay(ms);
  digitalWrite(BUZZER, LOW);
}

void notifySuccess() {
  digitalWrite(RED_LED, LOW);
  digitalWrite(GREEN_LED, HIGH);

  buzzFor(300);

  delay(1500);
  digitalWrite(GREEN_LED, LOW);
}

void notifyFailure() {
  digitalWrite(RED_LED, HIGH);

  for (int i = 0; i < 3; i++) {
    buzzFor(100);
    delay(100);
  }

  delay(4400);
  digitalWrite(RED_LED, LOW);
}

void notifyWorking() {
  digitalWrite(GREEN_LED, HIGH);
  delay(150);
  digitalWrite(GREEN_LED, LOW);
  delay(150);
}

boolean logUID(uint32_t uid) {
  Serial.print("Logging ");
  Serial.println(uid);

  Process p;

  p.runShellCommandAsynchronously(LOG_SCRIPT + String(uid));
  
  while(p.running()) {
    notifyWorking();
  }

  if (p.exitValue() == 0) {
    Serial.println("Card successfully logged");
    return true;
  } else {
    Serial.println("Error while logging");
    while (p.available()) {
      Serial.print((char) p.read());
    }
    return false;
  }
}

uint32_t readUID() {
  uint8_t success;
  uint8_t uid[] = { 0, 0, 0, 0, 0, 0, 0 };  // Buffer to store the returned UID
  uint8_t uidLength;                        // Length of the UID (4 or 7 bytes depending on ISO14443A card type)

  // Wait for an ISO14443A type cards (Mifare, etc.).  When one is found
  // 'uid' will be populated with the UID, and uidLength will indicate
  // if the uid is 4 bytes (Mifare Classic) or 7 bytes (Mifare Ultralight)
  success = nfc.readPassiveTargetID(PN532_MIFARE_ISO14443A, uid, &uidLength);

  if (success) {
    if (uidLength == 4) {
      uint32_t intUid = 0;
      intUid = uid[3];
      intUid <<= 8; intUid |= uid[2];
      intUid <<= 8; intUid |= uid[1];
      intUid <<= 8; intUid |= uid[0];
      Serial.print("Found card with uid ");
      Serial.println(intUid);
      return intUid;
    } else {
      Serial.print("Unable to read card with uid ");
      Serial.print(uidLength);
      Serial.print(" bytes long and uid ");
      nfc.PrintHex(uid, uidLength);
      return 0;
    }
  } else {
    Serial.println("Unable to read card");
    return 0;
  }
}
