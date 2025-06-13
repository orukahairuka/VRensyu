//
//  Untitled.swift
//  NewVR
//
//  Created by 櫻井絵理香 on 2025/06/13.
//

#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>
#include <IRremote.h>

// --- BLE 定義 ---
#define SERVICE_UUID        "12345678-1234-1234-1234-123456789ABC"
#define CHARACTERISTIC_UUID "87654321-4321-4321-4321-CBA987654321"
#define LED_PIN 13

// --- 赤外線 定義 ---
const int IR_RECV_PIN = 32; // 赤外線受信用ピン
IRrecv irrecv(IR_RECV_PIN);
decode_results results;

BLEServer* pServer = nullptr;
BLECharacteristic* pCharacteristic = nullptr;
bool deviceConnected = false;

// --- BLE 接続コールバック ---
class BLECallbacks : public BLEServerCallbacks {
    void onConnect(BLEServer* pBLEServer) override {
        deviceConnected = true;
        Serial.println("✅ Device connected");
    }

    void onDisconnect(BLEServer* pBLEServer) override {
        deviceConnected = false;
        Serial.println("❌ Device disconnected");
    }
};

void setup() {
    Serial.begin(115200);
    pinMode(LED_PIN, OUTPUT);
    digitalWrite(LED_PIN, LOW);

    // BLE 初期化
    BLEDevice::init("ESP32 IR Button");
    pServer = BLEDevice::createServer();
    pServer->setCallbacks(new BLECallbacks());

    BLEService* pService = pServer->createService(SERVICE_UUID);
    pCharacteristic = pService->createCharacteristic(
        CHARACTERISTIC_UUID,
        BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
    );
    pService->start();
    pServer->getAdvertising()->start();

    Serial.println("🚀 Waiting for client connection...");

    // 赤外線初期化
    irrecv.enableIRIn();
    Serial.println("📡 IR Receiver initialized");
}

void loop() {
    if (deviceConnected && irrecv.decode(&results)) {
        // 受信内容確認（必要なら特定のコードだけ通知可能）
        Serial.print("📥 IR Received: ");
        Serial.println(results.value);

        // BLE 通知
        pCharacteristic->setValue("button");
        pCharacteristic->notify();

        // LED 点灯
        digitalWrite(LED_PIN, HIGH);
        delay(200);
        digitalWrite(LED_PIN, LOW);

        // IR受信状態リセット
        irrecv.resume();
    }

    delay(10);
}
