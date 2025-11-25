#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// --- Pinos do sensor JSN-SR04T ---
const int trigPin = 5;
const int echoPin = 18;

// --- Buffer offline ---
#define MAX_BUFFER 100
float bufferLeituras[MAX_BUFFER];
int bufferCount = 0;

// --- Intervalo ---
unsigned long ultimaLeitura = 0;
const unsigned long intervalo = 2000;

// Última leitura estável
float ultimaEstavel = -1;

// --- BLE ---
BLEServer* pServer = nullptr;
BLECharacteristic* pCharacteristic = nullptr;
bool deviceConnected = false;

// UUIDs
#define SERVICE_UUID        "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
#define CHARACTERISTIC_UUID "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"  // notify

// --- Callbacks ---
class ServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) {
    deviceConnected = true;
    Serial.println("🔗 Dispositivo conectado via BLE!");
  }

  void onDisconnect(BLEServer* pServer) {
    deviceConnected = false;
    Serial.println("❌ Dispositivo desconectado.");
    pServer->startAdvertising();
  }
};

// --- Função simples de disparo do JSN ---
float medirBruto() {
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);

  long duracao = pulseIn(echoPin, HIGH, 30000);
  if (duracao == 0) return -1;

  return (duracao * 0.0343) / 2.0;
}

// --- Média de 5 medições ---
float leituraMedia() {
  float soma = 0;
  int validas = 0;

  for (int i = 0; i < 5; i++) {
    float d = medirBruto();
    if (d > 0) {
      soma += d;
      validas++;
    }
    delay(60);
  }

  if (validas == 0) return -1;
  return soma / validas;
}

// --- Filtro anti-ruído ---
float filtrarLeitura(float nova) {
  if (ultimaEstavel < 0) {
    ultimaEstavel = nova;
    return nova;
  }

  if (abs(nova - ultimaEstavel) > 10) {
    // Ruído detectado → ignora
    return ultimaEstavel;
  }

  ultimaEstavel = nova;
  return nova;
}

// --- Enviar buffer acumulado ---
void enviarBuffer() {
  if (!deviceConnected || bufferCount == 0) return;

  Serial.println("🔁 Enviando buffer offline...");

  for (int i = 0; i < bufferCount; i++) {
    String msg = String(bufferLeituras[i]);
    pCharacteristic->setValue(msg.c_str());
    pCharacteristic->notify();
    Serial.print("Enviado do buffer: ");
    Serial.println(msg);
    delay(30);
  }

  bufferCount = 0;
}

void setup() {
  Serial.begin(115200);
  pinMode(trigPin, OUTPUT);
  pinMode(echoPin, INPUT);

  // --- BLE Inicialização ---
  BLEDevice::init("WaterSenseESP32");
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new ServerCallbacks());

  BLEService *service = pServer->createService(SERVICE_UUID);

  pCharacteristic = service->createCharacteristic(
    CHARACTERISTIC_UUID,
    BLECharacteristic::PROPERTY_NOTIFY
  );

  pCharacteristic->addDescriptor(new BLE2902());

  service->start();
  pServer->getAdvertising()->start();

  Serial.println("📡 BLE iniciado. À espera de conexão...");
}

void loop() {
  if (millis() - ultimaLeitura >= intervalo) {
    ultimaLeitura = millis();

    float media = leituraMedia();
    if (media < 0) {
      Serial.println("❌ Falha ao ler o sensor");
      media = -1;
    }

    float distancia = filtrarLeitura(media);

    if (deviceConnected) {
      // Envia leitura atual
      String msg = String(distancia);
      pCharacteristic->setValue(msg.c_str());
      pCharacteristic->notify();
      Serial.print("📡 Enviado via BLE: ");
      Serial.println(msg);

      // Envia buffer
      enviarBuffer();

    } else {
      // Guarda offline
      if (bufferCount < MAX_BUFFER) {
        bufferLeituras[bufferCount++] = distancia;
        Serial.print("💾 Armazenado offline: ");
        Serial.println(bufferCount);
      } else {
        Serial.println("⚠️ Buffer cheio! Dados descartados.");
      }
    }
  }
}
