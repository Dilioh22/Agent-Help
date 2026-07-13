package com.dilio.noelito

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import org.json.JSONObject
import org.vosk.Model
import org.vosk.Recognizer
import org.vosk.android.RecognitionListener
import org.vosk.android.SpeechService

/**
 * Foreground service que escucha continuamente la palabra clave "Noelito"
 * usando Vosk (reconocimiento de voz offline, sin cuenta ni API key), incluso
 * con la app cerrada. Al detectarla, abre MainActivity, que le avisa a
 * Flutter para que arranque a escuchar el comando.
 *
 * Requiere el modelo de español en:
 *   android/app/src/main/assets/model-es-small/ (carpeta descargada de
 *   https://alphacephei.com/vosk/models, ej. vosk-model-small-es-0.42)
 */
class WakeWordService : Service() {
    companion object {
        private const val TAG = "WakeWordService"
        private const val CHANNEL_ID = "noelito_wake_word"
        private const val NOTIFICATION_ID = 42
        private const val MODEL_ASSET_DIR = "model-es-small"
        private const val KEYWORD = "noelito"
        private const val TRIGGER_COOLDOWN_MS = 4000L

        var isRunning: Boolean = false
            private set

        private var instance: WakeWordService? = null

        /** Pausa el micrófono de Vosk (ej. mientras la app está en primer plano usando el suyo). */
        fun pauseListening() {
            instance?.speechService?.setPause(true)
        }

        /** Reanuda la escucha de la palabra clave (ej. al mandar la app a segundo plano). */
        fun resumeListening() {
            instance?.speechService?.setPause(false)
        }
    }

    private var model: Model? = null
    private var speechService: SpeechService? = null
    private var lastTrigger = 0L

    private val listener = object : RecognitionListener {
        override fun onPartialResult(hypothesis: String?) = checkForKeyword(hypothesis)
        override fun onResult(hypothesis: String?) = checkForKeyword(hypothesis)
        override fun onFinalResult(hypothesis: String?) = checkForKeyword(hypothesis)
        override fun onError(exception: Exception?) {
            Log.e(TAG, "Error de Vosk: ${exception?.message}")
        }
        override fun onTimeout() {}
    }

    private fun checkForKeyword(hypothesisJson: String?) {
        val raw = hypothesisJson ?: return
        val text = try {
            val json = JSONObject(raw)
            json.optString("partial", "") + " " + json.optString("text", "")
        } catch (e: Exception) {
            raw
        }.lowercase()

        if (!text.contains(KEYWORD)) return

        val now = System.currentTimeMillis()
        if (now - lastTrigger < TRIGGER_COOLDOWN_MS) return
        lastTrigger = now

        val i = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra("wake_word_triggered", true)
        }
        startActivity(i)
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForeground(NOTIFICATION_ID, buildNotification("Esperando: “Noelito”…"))
        if (model == null) loadModelAndStart()
        return START_STICKY
    }

    private fun loadModelAndStart() {
        ModelUnpacker.unpack(
            applicationContext,
            MODEL_ASSET_DIR,
            onSuccess = { m ->
                model = m
                startRecognition(m)
            },
            onError = { e ->
                Log.e(TAG, "No se pudo cargar el modelo Vosk: ${e.message}")
                isRunning = false
                stopSelf()
            },
        )
    }

    private fun startRecognition(m: Model) {
        try {
            val rec = Recognizer(m, 16000.0f)
            speechService = SpeechService(rec, 16000.0f)
            speechService?.startListening(listener)
            isRunning = true
            WakePrefs.setEnabled(this, true)
        } catch (e: Exception) {
            Log.e(TAG, "No se pudo iniciar el reconocimiento: ${e.message}")
            isRunning = false
            stopSelf()
        }
    }

    private fun buildNotification(text: String): Notification {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID, "Noelito - Palabra de activación", NotificationManager.IMPORTANCE_LOW
            )
            (getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
                .createNotificationChannel(channel)
        }
        val piFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
            PendingIntent.FLAG_IMMUTABLE else 0
        val openApp = PendingIntent.getActivity(
            this, 0, Intent(this, MainActivity::class.java), piFlags
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Noelito")
            .setContentText(text)
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setContentIntent(openApp)
            .setOngoing(true)
            .build()
    }

    override fun onDestroy() {
        if (instance == this) instance = null
        speechService?.stop()
        speechService?.shutdown()
        speechService = null
        model?.close()
        model = null
        isRunning = false
        WakePrefs.setEnabled(this, false)
        super.onDestroy()
    }
}
