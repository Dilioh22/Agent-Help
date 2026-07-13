package com.dilio.noelito

import android.content.Intent
import android.net.Uri
import android.provider.AlarmClock
import android.provider.CalendarContract
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "noelito/actions"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "set_alarm" -> {
                            val i = Intent(AlarmClock.ACTION_SET_ALARM).apply {
                                putExtra(AlarmClock.EXTRA_HOUR, call.argument<Int>("hour")!!)
                                putExtra(AlarmClock.EXTRA_MINUTES, call.argument<Int>("minute") ?: 0)
                                putExtra(AlarmClock.EXTRA_MESSAGE, call.argument<String>("label") ?: "Noelito")
                                putExtra(AlarmClock.EXTRA_SKIP_UI, true)
                            }
                            startActivity(i)
                            result.success(true)
                        }

                        "set_timer" -> {
                            val i = Intent(AlarmClock.ACTION_SET_TIMER).apply {
                                putExtra(AlarmClock.EXTRA_LENGTH, call.argument<Int>("seconds")!!)
                                putExtra(AlarmClock.EXTRA_MESSAGE, call.argument<String>("label") ?: "Noelito")
                                putExtra(AlarmClock.EXTRA_SKIP_UI, true)
                            }
                            startActivity(i)
                            result.success(true)
                        }

                        "open_app" -> {
                            val name = call.argument<String>("name")!!.lowercase().trim()
                            val pkg = resolvePackage(name)
                            if (pkg != null) {
                                val launch = packageManager.getLaunchIntentForPackage(pkg)
                                if (launch != null) {
                                    startActivity(launch)
                                    result.success(true)
                                } else result.success(false)
                            } else result.success(false)
                        }

                        "dial" -> {
                            val number = call.argument<String>("number")!!
                            startActivity(Intent(Intent.ACTION_DIAL, Uri.parse("tel:$number")))
                            result.success(true)
                        }

                        "send_whatsapp" -> {
                            val number = call.argument<String>("number")!!
                                .replace(Regex("[^0-9+]"), "").removePrefix("+")
                            val text = Uri.encode(call.argument<String>("text") ?: "")
                            val i = Intent(Intent.ACTION_VIEW,
                                Uri.parse("https://wa.me/$number?text=$text"))
                            startActivity(i)
                            result.success(true)
                        }

                        "open_settings_panel" -> {
                            val panel = call.argument<String>("panel") ?: "wifi"
                            val action = when (panel) {
                                "wifi" -> Settings.Panel.ACTION_WIFI
                                "internet" -> Settings.Panel.ACTION_INTERNET_CONNECTIVITY
                                "volume" -> Settings.Panel.ACTION_VOLUME
                                "bluetooth" -> Settings.ACTION_BLUETOOTH_SETTINGS
                                else -> Settings.ACTION_SETTINGS
                            }
                            startActivity(Intent(action))
                            result.success(true)
                        }

                        "create_calendar_event" -> {
                            val i = Intent(Intent.ACTION_INSERT).apply {
                                data = CalendarContract.Events.CONTENT_URI
                                putExtra(CalendarContract.Events.TITLE,
                                    call.argument<String>("title") ?: "Evento")
                                call.argument<Long>("begin_millis")?.let {
                                    putExtra(CalendarContract.EXTRA_EVENT_BEGIN_TIME, it)
                                }
                                call.argument<Long>("end_millis")?.let {
                                    putExtra(CalendarContract.EXTRA_EVENT_END_TIME, it)
                                }
                                call.argument<String>("location")?.let {
                                    putExtra(CalendarContract.Events.EVENT_LOCATION, it)
                                }
                            }
                            startActivity(i)
                            result.success(true)
                        }

                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("ACTION_ERROR", e.message, null)
                }
            }
    }

    /** Resuelve nombre hablado → package. Mapa de apps comunes + búsqueda por label. */
    private fun resolvePackage(name: String): String? {
        val known = mapOf(
            "whatsapp" to "com.whatsapp",
            "spotify" to "com.spotify.music",
            "youtube" to "com.google.android.youtube",
            "instagram" to "com.instagram.android",
            "facebook" to "com.facebook.katana",
            "chrome" to "com.android.chrome",
            "gmail" to "com.google.android.gm",
            "maps" to "com.google.android.apps.maps",
            "mapas" to "com.google.android.apps.maps",
            "calculadora" to "com.google.android.calculator",
            "camara" to "com.android.camera",
            "cámara" to "com.android.camera",
            "telegram" to "org.telegram.messenger",
            "netflix" to "com.netflix.mediaclient",
            "tiktok" to "com.zhiliaoapp.musically"
        )
        known[name]?.let { return it }

        // Búsqueda por label entre las apps instaladas
        val apps = packageManager.getInstalledApplications(0)
        return apps.firstOrNull {
            packageManager.getApplicationLabel(it).toString()
                .lowercase().contains(name)
        }?.packageName
    }
}
