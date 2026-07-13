# 🤖 Noelito — Asistente personal de voz

Asistente tipo Jarvis en Flutter (Android primero) con cerebro híbrido:
parser local para comandos frecuentes + un modelo de OpenAI vía OpenRouter (tool use) para lenguaje natural.

## Estructura

```
noelito/
├── app/        → código Flutter (copiar sobre un proyecto flutter create)
└── backend/    → proxy Node/TS hacia OpenRouter (modelo OpenAI) (Railway)
```

## 1. Backend (primero — es el cerebro en la nube)

```bash
cd backend
npm install
cp .env.example .env      # pon tu OPENROUTER_API_KEY real
npm run dev               # corre en http://localhost:3000
```

Prueba rápida:
```bash
curl -X POST http://localhost:3000/chat -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"pon una alarma a las 6 y media de la mañana"}]}'
# → {"speak":"...","action":{"name":"set_alarm","args":{"hour":6,"minute":30,...}}}
```

Para producción: sube el repo a GitHub y conéctalo en Railway (igual que NovaliXAPIS).
Variables en Railway: `OPENROUTER_API_KEY`, `NOELITO_MODEL` (opcional, default `openai/gpt-4o-mini`), start command `npm run build && npm start`.

## 2. App Flutter

```bash
flutter create --org com.dilio --project-name noelito noelito_app
cd noelito_app
```

Ahora copia encima los archivos de `app/`:
- `pubspec.yaml` → raíz (reemplaza)
- `lib/` → reemplaza la carpeta lib completa
- `android/app/src/main/AndroidManifest.xml` → reemplaza
- `android/app/src/main/kotlin/com/dilio/noelito/MainActivity.kt` → reemplaza el MainActivity generado

Configura la URL del backend en `lib/services/backend_client.dart`:
- Pruebas locales: `http://<IP-de-tu-PC>:3000` (teléfono y PC en la misma red WiFi)
- Producción: tu URL de Railway

```bash
flutter pub get
flutter run          # con tu teléfono conectado por USB (modo desarrollador)
```

> Nota Android: para probar con backend local por HTTP (no HTTPS), agrega
> `android:usesCleartextTraffic="true"` en la etiqueta `<application>` del manifest.
> Quítalo cuando uses la URL HTTPS de Railway.

## 3. Prueba estos comandos por voz

Resueltos LOCALMENTE (offline, instantáneos):
- "Pon una alarma a las 6 y media de la mañana"
- "Temporizador de 10 minutos"
- "Abre Spotify" / "Abre WhatsApp"
- "Llama a mamá"
- "Manda un WhatsApp a Juan que dice voy en camino"
- "Abre el WiFi" / "¿Qué hora es?"

Resueltos por OpenAI vía OpenRouter (nube, lenguaje natural libre):
- "Recuérdame la cita con el dentista el martes a las 3 de la tarde" → evento de calendario
- "¿Qué es un agujero negro?" → respuesta hablada
- "Despiértame media hora antes de las 7" → alarma 6:30
- "Ábreme la app esa de los videos cortos" → TikTok 😄

## Cómo funciona el router híbrido

```
Voz → STT (es_419) → LocalParser.parse()
        ├── match  → ejecuta acción al instante (0 latencia, offline)
        └── null   → POST /chat → OpenAI vía OpenRouter decide (texto o tool call)
                        → app ejecuta la acción vía MethodChannel (Kotlin)
→ TTS habla la respuesta
```

## Roadmap (según el plan)

- [x] Fase 1: loop voz completo (STT → cerebro → TTS)
- [x] Fase 2: 7 acciones Android + contactos con matching difuso
- [ ] Fase 3: puerto iOS (EventKit, URL schemes, Atajos de Siri)
- [ ] Fase 4: confirmación por voz en llamadas/mensajes, memoria persistente, web search
- [ ] Fase 5: wake word "Oye Noelito" (Porcupine + foreground service)

## Problemas comunes

| Síntoma | Causa probable |
|---|---|
| STT no transcribe | Falta permiso de micrófono o paquete de idioma español en el teléfono |
| "No pude conectarme a mi cerebro" | URL del backend mal puesta o cleartext bloqueado (ver nota HTTP) |
| open_app no encuentra apps | Falta `QUERY_ALL_PACKAGES` en el manifest (ya incluido aquí) |
| Alarma abre la UI del reloj | Algunos fabricantes ignoran EXTRA_SKIP_UI; es normal |
