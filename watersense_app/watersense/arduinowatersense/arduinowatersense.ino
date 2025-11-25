#include "BluetoothSerial.h"

BluetoothSerial SerialBT;

// --- Pinos do sensor JSN-SR04T ---
const int trigPin = 5;
const int echoPin = 18;

// --- Buffer de armazenamento offline ---
#define MAX_BUFFER 100
float bufferLeituras[MAX_BUFFER];
int bufferCount = 0;

// --- Controle de tempo ---
unsigned long ultimaLeitura = 0;
const unsigned long intervalo = 2000; // 2 segundos

// --- Função para medir distância ---
float medirDistancia() {
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);

  long duracao = pulseIn(echoPin, HIGH, 30000); // timeout 30 ms
  if (duracao == 0) return -1; // falha de leitura
  return (duracao * 0.0343) / 2.0; // cm
}

// --- Enviar leituras acumuladas ---
void enviarBuffer() {
  if (!SerialBT.hasClient() || bufferCount == 0) return;

  Serial.println("🔁 Enviando dados armazenados...");
  for (int i = 0; i < bufferCount; i++) {
    SerialBT.println(bufferLeituras[i]);
    Serial.print("Enviado do buffer: ");
    Serial.println(bufferLeituras[i]);
    delay(100);
  }
  bufferCount = 0; // limpa buffer
}

void setup() {
  Serial.begin(115200);
  SerialBT.begin("WaterSenseESP32");
  pinMode(trigPin, OUTPUT);
  pinMode(echoPin, INPUT);
  Serial.println("✅ Bluetooth iniciado. Aguardando conexão...");
}

void loop() {
  // Faz leitura a cada intervalo
  if (millis() - ultimaLeitura >= intervalo) {
    ultimaLeitura = millis();

    float distancia = medirDistancia();

    if (distancia < 0) {
      Serial.println("❌ Falha na leitura do sensor");
      return;
    }

    Serial.print("Leitura atual: ");
    Serial.print(distancia);
    Serial.println(" cm");

    if (SerialBT.hasClient()) {
      // Se conectado, envia leitura atual
      SerialBT.println(distancia);
      Serial.println("📡 Enviado via Bluetooth");
      // E também envia o que estava guardado antes
      enviarBuffer();
    } else {
      // Se não conectado, armazena no buffer
      if (bufferCount < MAX_BUFFER) {
        bufferLeituras[bufferCount++] = distancia;
        Serial.print("💾 Armazenado offline. Total: ");
        Serial.println(bufferCount);
      } else {
        Serial.println("⚠️ Buffer cheio. Dados antigos serão descartados.");
      }
    }
  }
}
