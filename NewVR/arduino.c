////
////  arduino.swift
////  NewVR
////
////  Created by 櫻井絵理香 on 2025/06/13.
////
//
//
//#include <Arduino.h>
//#include <BLEDevice.h>
//#include <BLEUtils.h>
//#include <BLEServer.h>
//
//// BLEサービスとキャラクタリスティックのUUID
//#define SERVICE_UUID        "12345678-1234-1234-1234-123456789ABC"
//#define CHARACTERISTIC_UUID "87654321-4321-4321-4321-CBA987654321"
//
//#define BUTTON_PIN 15  // ボタンは GPIO15 に接続されている想定（適宜変更）
//#define LED_PIN    13  // GPIO13 を LED 出力用に使用する
//
//const int buttonOn = LOW;
//const int buttonOff = HIGH;
//
//BLEServer *pServer = nullptr;
//BLECharacteristic *pCharacteristic = nullptr;
//bool deviceConnected = false;
//int buttonState = buttonOff;
//
//// BLE接続状態のコールバック
//class BLECallbacks: public BLEServerCallbacks {
//    void onConnect(BLEServer* pBLEServer) override {
//        deviceConnected = true;
//        Serial.println("✅ Device connected");
//    }
//
//    void onDisconnect(BLEServer* pBLEServer) override {
//        deviceConnected = false;
//        Serial.println("❌ Device disconnected");
//    }
//};
//
//void setup() {
//    Serial.begin(115200);
//
//    // ピン設定
//    pinMode(BUTTON_PIN, INPUT_PULLUP);  // ボタン入力
//    pinMode(LED_PIN, OUTPUT);           // LED出力
//
//    // 初期LED消灯
//    digitalWrite(LED_PIN, LOW);
//
//    // BLE初期化
//    BLEDevice::init("ESP32 Button");
//    pServer = BLEDevice::createServer();
//    pServer->setCallbacks(new BLECallbacks());
//
//    BLEService *pService = pServer->createService(SERVICE_UUID);
//
//    pCharacteristic = pService->createCharacteristic(
//        CHARACTERISTIC_UUID,
//        BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
//    );
//
//    pService->start();
//    pServer->getAdvertising()->start();
//    Serial.println("🚀 Waiting for client connection...");
//}
//
//void loop() {
//    if (deviceConnected) {
//        bool currentButtonState = digitalRead(BUTTON_PIN);
//        if (buttonState != currentButtonState) {
//            if (currentButtonState == buttonOn) {
//                Serial.println("🔘 Button Pressed");
//
//                // BLE通知
//                pCharacteristic->setValue("button");
//                pCharacteristic->notify();
//
//                // LED点灯
//                digitalWrite(LED_PIN, HIGH);
//                delay(200); // 点灯時間
//                digitalWrite(LED_PIN, LOW);
//            }
//            buttonState = currentButtonState;
//        }
//    }
//    delay(10);
//}
//
//
//
