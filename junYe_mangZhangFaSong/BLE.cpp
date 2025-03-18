#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// 定义服务和特征的 UUID
#define SERVICE_UUID "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

BLECharacteristic *pCharacteristic;
bool deviceConnected = false;
const int buttonPin = D10;

unsigned long lastDebounceTime = 0;
unsigned int debounceDelay = 50; // 消抖延时50ms
int lastButtonState = LOW;
int buttonState = LOW; // 消抖后的稳定状态

// 自定义服务器回调函数，用于检测设备连接状态
class MyServerCallbacks : public BLEServerCallbacks
{
  void onConnect(BLEServer *pServer) override
  {
    deviceConnected = true;
    Serial.println("设备已连接");
  }
  void onDisconnect(BLEServer *pServer) override
  {
    deviceConnected = false;
    Serial.println("设备断开连接");
  }
};

void setup()
{
  pinMode(buttonPin, INPUT);
  Serial.begin(115200);
  Serial.println("启动 BLE 服务端...");

  // 初始化 BLE 设备并设置设备名称
  BLEDevice::init("TingJian BLE");

  // 创建 BLE 服务器，并注册回调函数
  BLEServer *pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  // 创建服务
  BLEService *pService = pServer->createService(SERVICE_UUID);

  // 创建一个支持通知和读取的特征
  // 这里设置了 PROPERTY_NOTIFY，表示该特征可以发送通知到客户端（手机）
  pCharacteristic = pService->createCharacteristic(
      CHARACTERISTIC_UUID,
      BLECharacteristic::PROPERTY_NOTIFY |
          BLECharacteristic::PROPERTY_READ);
  // 添加描述符，用于开启客户端的通知订阅
  // BLE2902 描述符允许客户端订阅特征的通知
  pCharacteristic->addDescriptor(new BLE2902());

  // 设置初始特征值
  pCharacteristic->setValue("Hello World!");

  // 启动服务
  pService->start();

  // 配置广播
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  // 下面两行设置可选参数，有助于部分手机设备更好地连接
  // 注意：setMinPreferred 重复调用，仅最后一次有效
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();

  Serial.println("BLE 广播已启动，等待连接...");
}

void loop()
{
  int currentState = digitalRead(buttonPin);
  if (currentState != lastButtonState)
  {
    lastDebounceTime = millis();
  }

  if ((millis() - lastDebounceTime) > debounceDelay)
  {
    if (currentState != buttonState)
    {
      buttonState = currentState; // 更新稳定状态

      if (buttonState == HIGH)
      { // 仅在按下上升沿触发
        String data = "Black Button pressed!";
        pCharacteristic->setValue(data.c_str());
        pCharacteristic->notify();
        Serial.println("发送通知: " + data);
      }
    }
  }
  lastButtonState = currentState; // 更新原始状态记录
}
