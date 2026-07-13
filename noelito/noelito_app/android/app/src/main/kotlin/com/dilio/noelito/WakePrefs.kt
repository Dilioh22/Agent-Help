package com.dilio.noelito

import android.content.Context

/** Recuerda si el usuario activó la escucha de "Oye Noelito", para restaurarla tras reiniciar el teléfono. */
object WakePrefs {
    private const val PREFS = "noelito_wake_prefs"
    private const val KEY_ENABLED = "wake_enabled"

    fun isEnabled(context: Context): Boolean =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getBoolean(KEY_ENABLED, false)

    fun setEnabled(context: Context, enabled: Boolean) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().putBoolean(KEY_ENABLED, enabled).apply()
    }
}
