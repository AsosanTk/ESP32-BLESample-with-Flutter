//ESP32 G3-Theme Temperature-and-disinfection

#include <ESP32Servo.h>
#include <Wire.h>
#include <Adafruit_MLX90614.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
//BLE
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>



//Stateless value
const int Echo_Pin = 25;
const int Trigger_Pin = 26;
const int SDA_Pin = 21;
const int SCL_Pin = 22;
const int Servo_Pin = 27;
const int ALED_Pin = 18;
const int Buzzer_Pin = 32;
const double adjustTemp = 2.7;
const double leastTemp = 35.0;
const double mostTemp = 37.0;
const double farFromHand = 10;
const char OLED_address = 0x3C;

double latestTemp;
Servo servo;

Adafruit_MLX90614 mlx = Adafruit_MLX90614();
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 32
#define OLED_RESET 4
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);


void setup() {
  // put your setup code here, to run once:
  Serial.begin(115200);
  pinMode(Trigger_Pin, OUTPUT);
  pinMode(Echo_Pin, INPUT);
  pinMode(ALED_Pin, OUTPUT);
  pinMode(Buzzer_Pin, OUTPUT);
  digitalWrite(Trigger_Pin, LOW);
  digitalWrite(ALED_Pin, HIGH);
  digitalWrite(Buzzer_Pin, LOW);
  servo.attach(Servo_Pin);
  mlx.begin();
  display.begin(SSD1306_SWITCHCAPVCC, OLED_address);
  initBLE();
}


//--function--
void sendTrigger() {
  digitalWrite(Trigger_Pin, HIGH);
  delayMicroseconds(10);
  digitalWrite(Trigger_Pin, LOW);
}

double bodytemp() {
  delay(500); //体温計の前に来てからのラグを判定(値に根拠なし)
  double count = 0;
  for (int i = 0; i < 20; i++) {
      count += mlx.readObjectTempC();
      delay(5);
  }
  double temp = count / 20;
  if (temp > 99) {
    temp = 0;
  }
  temp += adjustTemp;
  return temp;
}
void showtemp(double temp) {
  display_double(temp);
  if (leastTemp < temp && temp < mostTemp) {
    display_temptext("Success!");
  } else if (mostTemp <= temp) {
    display_temptext("Oops, High!");
  } else  {
    display_temptext("Failed...");
  }
}

void disinfection() {
  for (int i = 0; i < 3; i++) {
    servo.write(180);
    delay(1000);
    servo.write(0);
    delay(1000);
  }
}

void buzzerandled() {
  digitalWrite(ALED_Pin, LOW);
  digitalWrite(Buzzer_Pin, HIGH);
  delay(500);
  digitalWrite(ALED_Pin, HIGH);
  digitalWrite(Buzzer_Pin, LOW);
}

void display_text(char* text) {
  display.clearDisplay();
  display.setTextColor(SSD1306_WHITE);
  display.setTextSize(2);
  display.setCursor(0, 0);
  display.println(text);
  display.display();
}
void display_temptext(char* text) {
  display.setTextColor(SSD1306_WHITE);
  display.setTextSize(2);
  display.setCursor(0, 16);
  display.println(text);
  display.display();
}
void display_double(double number) {
  display.clearDisplay();
  display.setTextColor(SSD1306_WHITE);
  display.setTextSize(2);
  display.setCursor(0, 0);
  display.println(number);
  display.display();
}


//////////////////
// Bluetooth LE //
//////////////////
#define LOCAL_NAME "ESP32"
#define SERVICE_UUID "ee16e67a-8310-11eb-8dcd-0242ac130003"
#define CHARACTERISTIC_UUID_NOTIFY "ee16eb34-8310-11eb-8dcd-0242ac130003"
BLEServer *pServer = NULL;
BLECharacteristic * pNotifyCharacteristic;
bool deviceConnected = false;
bool oldDeviceConnected = false;

class MyServerCallbacks: public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) {
    deviceConnected = true;
  }
  void onDisonnect(BLEServer* pServer) {
    deviceConnected = false;
  }
};

// Bluetooth LE initialize
void initBLE() {
  BLEDevice::init(LOCAL_NAME);
  // Create the BLE Server
  pServer = BLEDevice::createServer();
  pServer -> setCallbacks(new MyServerCallbacks());
  // Create the BLE Service
  BLEService *pService = pServer -> createService(SERVICE_UUID);
  // Create a BLE Characteristic
  pNotifyCharacteristic = pService -> createCharacteristic(CHARACTERISTIC_UUID_NOTIFY,BLECharacteristic::PROPERTY_NOTIFY);
  pNotifyCharacteristic -> addDescriptor(new BLE2902());
  // Start the service
  pService -> start();
  // Start advertising
  pServer -> getAdvertising() -> start();
}

// BLE Loop
void loopBLE() {
  // Connecting
  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
  }
  // Disconnecting
  if (deviceConnected && !oldDeviceConnected) {
    delay(500);
    pServer -> startAdvertising();
    Serial.println("startAdvertising");
    oldDeviceConnected = deviceConnected;
  }
}

void tempBLE() {
  if (deviceConnected) {
    char upTemp[6];
    dtostrf(latestTemp, 4, 1, upTemp);
    pNotifyCharacteristic -> setValue(upTemp);
    pNotifyCharacteristic -> notify();
  }
}




//--loop--
void loop() {
  // put your main code here, to run repeatedly:
  sendTrigger();
  double time = pulseIn(Echo_Pin, HIGH);
  double distance = (time / 1000 / 1000) / 2 * (340 * 100);
  Serial.println(distance);
  display_text("Hold your hand...");

  if (distance < farFromHand) {
    double count = 0;
    for (int i = 0; i < 10; i++) {
      sendTrigger();
      double time = pulseIn(Echo_Pin, HIGH);
      double distance = (time / 1000 / 1000) / 2 * (340 * 100);
      count += distance;
      delay(50);
    }
    if (count < farFromHand * 10) {
      latestTemp = bodytemp();
      showtemp(latestTemp);
      buzzerandled();
      disinfection();
    }
  }
  loopBLE();
  tempBLE();
  delay(10);
}