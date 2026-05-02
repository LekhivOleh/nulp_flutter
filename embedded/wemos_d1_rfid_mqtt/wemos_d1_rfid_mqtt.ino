#include <ESP8266WiFi.h>
#include <LittleFS.h>
#include <MFRC522.h>
#include <PubSubClient.h>
#include <SPI.h>
#include <Wire.h>
#include <time.h>

#include <Adafruit_GFX.h>
#include <Adafruit_SH110X.h>

const char* WIFI_SSID = "TP-Link_A623";
const char* WIFI_PASS = "Oleh04052006";

const char* MQTT_HOST = "broker.hivemq.com";
const uint16_t MQTT_PORT = 1883;
const char* MQTT_USER = "";
const char* MQTT_PASS = "";

const char* MQTT_TOPIC_EVENTS = "nulp/access/events";
const char* DEVICE_ID = "wemos-d1-rfid-01";
const char* CARDS_FILE_PATH = "/cards.csv";

constexpr uint8_t RFID_SS_PIN = D8;
constexpr uint8_t RFID_RST_PIN = D3;

constexpr uint8_t LED_RED_PIN = D0;
constexpr uint8_t LED_GREEN_PIN = D4;

constexpr uint8_t OLED_SCL_PIN = D1;
constexpr uint8_t OLED_SDA_PIN = D2;
constexpr uint8_t OLED_I2C_ADDR = 0x3C;

WiFiClient espClient;
PubSubClient mqttClient(espClient);
MFRC522 mfrc522(RFID_SS_PIN, RFID_RST_PIN);
Adafruit_SH1106G display(128, 64, &Wire, -1);

struct CardState {
  String uid;
  bool inside;
};

struct CardEntry {
  String uid;
  String person;
  String userId;
  bool isAdmin;
};

constexpr size_t MAX_TRACKED_CARDS = 64;
CardState states[MAX_TRACKED_CARDS];
size_t statesCount = 0;

constexpr size_t MAX_REGISTERED_CARDS = 128;
CardEntry registeredCards[MAX_REGISTERED_CARDS];
size_t registeredCardsCount = 0;

bool filesystemReady = false;
bool displayReady = false;
bool rfidReady = false;
String lastUid = "";
unsigned long lastScanMs = 0;
constexpr unsigned long SCAN_DEBOUNCE_MS = 1500;
unsigned long lastRfidRetryMs = 0;
constexpr unsigned long RFID_RETRY_INTERVAL_MS = 5000;

String uidToString(const MFRC522::Uid& uid) {
  String out;
  for (byte i = 0; i < uid.size; i++) {
    if (i > 0) {
      out += ':';
    }
    if (uid.uidByte[i] < 0x10) {
      out += '0';
    }
    out += String(uid.uidByte[i], HEX);
  }
  out.toUpperCase();
  return out;
}

String normalizeUid(String value) {
  value.trim();
  value.toUpperCase();
  value.replace(" ", "");
  return value;
}

void addRegisteredCard(
    const String& uid,
    const String& person,
    const String& userId,
    bool isAdmin) {
  if (registeredCardsCount >= MAX_REGISTERED_CARDS) {
    return;
  }

  registeredCards[registeredCardsCount].uid = normalizeUid(uid);
  registeredCards[registeredCardsCount].person = person;
  registeredCards[registeredCardsCount].userId = userId;
  registeredCards[registeredCardsCount].isAdmin = isAdmin;
  registeredCardsCount++;
}

bool parseIsAdminValue(String value) {
  value.trim();
  value.toLowerCase();
  return value == "1" || value == "true" || value == "yes" || value == "y" || value == "admin";
}

void loadCardsFromLittleFs() {
  registeredCardsCount = 0;

  if (!filesystemReady) {
    return;
  }

  if (!LittleFS.exists(CARDS_FILE_PATH)) {
    return;
  }

  File file = LittleFS.open(CARDS_FILE_PATH, "r");
  if (!file) {
    return;
  }

  while (file.available()) {
    String line = file.readStringUntil('\n');
    line.trim();

    if (line.length() == 0 || line.startsWith("#")) {
      continue;
    }

    const int commaIndex = line.indexOf(',');
    const int lastIndex = static_cast<int>(line.length()) - 1;
    if (commaIndex <= 0 || commaIndex >= lastIndex) {
      continue;
    }

    const int secondCommaIndex = line.indexOf(',', commaIndex + 1);
    String uid = line.substring(0, commaIndex);
    String person;
    String userId;
    bool isAdmin = false;

    if (secondCommaIndex > commaIndex) {
      person = line.substring(commaIndex + 1, secondCommaIndex);
      const int thirdCommaIndex = line.indexOf(',', secondCommaIndex + 1);

      if (thirdCommaIndex > secondCommaIndex) {
        userId = line.substring(secondCommaIndex + 1, thirdCommaIndex);
        String isAdminRaw = line.substring(thirdCommaIndex + 1);
        isAdmin = parseIsAdminValue(isAdminRaw);
      } else {
        userId = line.substring(secondCommaIndex + 1);
      }
    } else {
      continue;
    }

    uid = normalizeUid(uid);
    person.trim();
    userId.trim();

    if (uid.length() == 0 || person.length() == 0 || userId.length() == 0) {
      continue;
    }

    addRegisteredCard(uid, person, userId, isAdmin);
  }

  file.close();
}

const CardEntry* findCardByUid(const String& uid) {
  for (size_t i = 0; i < registeredCardsCount; i++) {
    if (uid.equals(registeredCards[i].uid)) {
      return &registeredCards[i];
    }
  }
  return nullptr;
}

bool* getInsideStateRef(const String& uid) {
  for (size_t i = 0; i < statesCount; i++) {
    if (states[i].uid == uid) {
      return &states[i].inside;
    }
  }

  if (statesCount >= MAX_TRACKED_CARDS) {
    return nullptr;
  }

  states[statesCount].uid = uid;
  states[statesCount].inside = false;
  statesCount++;
  return &states[statesCount - 1].inside;
}

String getIsoTimestamp() {
  time_t now = time(nullptr);
  if (now < 100000) {
    const unsigned long s = millis() / 1000UL;
    const unsigned long h = (s / 3600UL) % 24UL;
    const unsigned long m = (s / 60UL) % 60UL;
    const unsigned long sec = s % 60UL;

    char fallback[32];
    snprintf(fallback, sizeof(fallback), "UNSYNC_%02lu:%02lu:%02lu", h, m, sec);
    return String(fallback);
  }

  struct tm tmNow;
  localtime_r(&now, &tmNow);

  char buf[32];
  strftime(buf, sizeof(buf), "%Y-%m-%dT%H:%M:%S", &tmNow);
  return String(buf);
}

void showDisplay(const String& line1, const String& line2, const String& line3) {
  if (!displayReady) {
    return;
  }

  display.clearDisplay();
  display.setTextColor(SH110X_WHITE);

  display.setTextSize(1);
  display.setCursor(0, 0);
  display.println("RFID Access");

  display.setCursor(0, 16);
  display.println(line1);
  display.setCursor(0, 30);
  display.println(line2);
  display.setCursor(0, 44);
  display.println(line3);

  display.display();
}

void blinkLed(uint8_t pin, uint8_t times, uint16_t onMs = 120, uint16_t offMs = 120) {
  for (uint8_t i = 0; i < times; i++) {
    digitalWrite(pin, HIGH);
    delay(onMs);
    digitalWrite(pin, LOW);
    delay(offMs);
  }
}

void ensureWifiConnected() {
  if (WiFi.status() == WL_CONNECTED) {
    return;
  }

  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASS);

  showDisplay("WiFi connecting...", "", WiFi.SSID());

  unsigned long start = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - start < 15000UL) {
    delay(250);
  }

  if (WiFi.status() == WL_CONNECTED) {
    showDisplay("WiFi connected", WiFi.localIP().toString(), "");
  } else {
    showDisplay("WiFi failed", "offline mode", "");
  }
}

void ensureMqttConnected() {
  if (mqttClient.connected() || WiFi.status() != WL_CONNECTED) {
    return;
  }

  showDisplay("MQTT connecting...", String(MQTT_HOST), "");

  String clientId = String(DEVICE_ID) + '-' + String(ESP.getChipId(), HEX);

  bool ok;
  if (strlen(MQTT_USER) > 0) {
    ok = mqttClient.connect(clientId.c_str(), MQTT_USER, MQTT_PASS);
  } else {
    ok = mqttClient.connect(clientId.c_str());
  }

  if (ok) {
    showDisplay("MQTT connected", String(MQTT_TOPIC_EVENTS), "");
  } else {
    showDisplay("MQTT failed", String(mqttClient.state()), "");
  }
}

bool initializeDisplay() {
  displayReady = display.begin(OLED_I2C_ADDR, true);
  if (!displayReady) {
    return false;
  }

  display.clearDisplay();
  display.display();
  return true;
}

bool initializeRfidReader() {
  mfrc522.PCD_Init();
  delay(4);

  const byte version = mfrc522.PCD_ReadRegister(MFRC522::VersionReg);
  if (version == 0x00 || version == 0xFF) {
    return false;
  }

  mfrc522.PCD_SetAntennaGain(mfrc522.RxGain_max);
  return true;
}

void publishAccessEvent(
    const String& uid,
    const String& userId,
    const String& person,
    bool isAdmin,
    const String& direction,
    const String& timestamp) {
  if (!mqttClient.connected()) {
    return;
  }

  String payload = "{";
  payload += "\"device\":\"" + String(DEVICE_ID) + "\",";
  payload += "\"uid\":\"" + uid + "\",";
  payload += "\"userId\":\"" + userId + "\",";
  payload += "\"name\":\"" + person + "\",";
  payload += "\"isAdmin\":" + String(isAdmin ? "true" : "false") + ",";
  payload += "\"direction\":\"" + direction + "\",";
  payload += "\"timestamp\":\"" + timestamp + "\"";
  payload += "}";

  mqttClient.publish(MQTT_TOPIC_EVENTS, payload.c_str(), false);
}

void handleCardScan() {
  if (!rfidReady) {
    return;
  }

  if (!mfrc522.PICC_IsNewCardPresent()) {
    return;
  }

  if (!mfrc522.PICC_ReadCardSerial()) {
    return;
  }

  const String uid = uidToString(mfrc522.uid);

  if (uid == lastUid && (millis() - lastScanMs) < SCAN_DEBOUNCE_MS) {
    mfrc522.PICC_HaltA();
    mfrc522.PCD_StopCrypto1();
    return;
  }

  lastUid = uid;
  lastScanMs = millis();

  const CardEntry* card = findCardByUid(uid);
  const String timestamp = getIsoTimestamp();

  if (card == nullptr) {
    showDisplay("Unknown card", uid, timestamp);
    blinkLed(LED_RED_PIN, 2);

    publishAccessEvent(uid, "unknown", "UNKNOWN", false, "DENIED", timestamp);

    mfrc522.PICC_HaltA();
    mfrc522.PCD_StopCrypto1();
    return;
  }

  bool* insideRef = getInsideStateRef(uid);
  if (insideRef == nullptr) {
    showDisplay("State full", "Cannot track card", "");
    blinkLed(LED_RED_PIN, 3, 80, 80);
    mfrc522.PICC_HaltA();
    mfrc522.PCD_StopCrypto1();
    return;
  }

  *insideRef = !(*insideRef);
  const String direction = *insideRef ? "IN" : "OUT";

  const String rolePrefix = card->isAdmin ? "ADMIN " : "USER ";
  const String displayLine2 = rolePrefix + direction;

  showDisplay(card->person, displayLine2, timestamp);
  blinkLed(LED_GREEN_PIN, 1, 180, 80);

  publishAccessEvent(
      uid,
      card->userId,
      card->person,
      card->isAdmin,
      direction,
      timestamp);

  mfrc522.PICC_HaltA();
  mfrc522.PCD_StopCrypto1();
}

void setup() {
  pinMode(LED_RED_PIN, OUTPUT);
  pinMode(LED_GREEN_PIN, OUTPUT);
  digitalWrite(LED_RED_PIN, LOW);
  digitalWrite(LED_GREEN_PIN, LOW);

  Serial.begin(115200);
  delay(100);

  Wire.begin(OLED_SDA_PIN, OLED_SCL_PIN);
  initializeDisplay();

  SPI.begin();
  rfidReady = initializeRfidReader();

  mqttClient.setServer(MQTT_HOST, MQTT_PORT);

  filesystemReady = LittleFS.begin();
  loadCardsFromLittleFs();

  showDisplay("Booting...", String(DEVICE_ID), "");

  ensureWifiConnected();
  configTime(0, 0, "pool.ntp.org", "time.google.com");
  ensureMqttConnected();

  showDisplay("Ready", "Scan card...", "");
}

void loop() {
  if (WiFi.status() != WL_CONNECTED) {
    ensureWifiConnected();
  }

  if (!mqttClient.connected()) {
    ensureMqttConnected();
  }

  if (!rfidReady && (millis() - lastRfidRetryMs) >= RFID_RETRY_INTERVAL_MS) {
    lastRfidRetryMs = millis();
    rfidReady = initializeRfidReader();
  }

  mqttClient.loop();
  handleCardScan();
}
