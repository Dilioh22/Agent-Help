package com.dilio.noelito

import android.content.Context
import android.content.res.AssetManager
import android.os.Handler
import android.os.Looper
import org.vosk.Model
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.util.concurrent.Executors

/**
 * Copia el modelo de Vosk desde assets/ (donde vive comprimido dentro del APK)
 * al almacenamiento interno de la app, donde el decodificador nativo puede
 * abrirlo por ruta de archivo real. Se hace una sola vez (marcador ".copied").
 */
object ModelUnpacker {
    fun unpack(
        context: Context,
        assetDir: String,
        onSuccess: (Model) -> Unit,
        onError: (Exception) -> Unit,
    ) {
        val handler = Handler(Looper.getMainLooper())
        Executors.newSingleThreadExecutor().execute {
            try {
                val targetDir = File(context.filesDir, assetDir)
                val doneMarker = File(targetDir, ".copied")
                if (!doneMarker.exists()) {
                    targetDir.deleteRecursively()
                    targetDir.mkdirs()
                    copyAssetDir(context.assets, assetDir, targetDir)
                    doneMarker.createNewFile()
                }
                val model = Model(targetDir.absolutePath)
                handler.post { onSuccess(model) }
            } catch (e: IOException) {
                handler.post { onError(e) }
            }
        }
    }

    private fun copyAssetDir(assets: AssetManager, assetPath: String, outDir: File) {
        val children = assets.list(assetPath)
        if (children.isNullOrEmpty()) {
            outDir.parentFile?.mkdirs()
            assets.open(assetPath).use { input ->
                FileOutputStream(outDir).use { output -> input.copyTo(output) }
            }
        } else {
            outDir.mkdirs()
            for (child in children) {
                copyAssetDir(assets, "$assetPath/$child", File(outDir, child))
            }
        }
    }
}
