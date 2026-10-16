package com.alessandro.recordapp

import android.app.Activity
import android.content.ContentUris
import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Además de la actividad de Flutter, expone un canal para que el usuario elija
 * un audio propio.
 *
 * El sonido de una notificación lo reproduce el SISTEMA, no la app, así que el
 * archivo debe estar en un sitio que Android pueda leer. Por eso el audio
 * elegido se copia a MediaStore (carpeta Alarms/RecordApp) y se devuelve su
 * URI `content://`, que sí es legible por el sistema. No requiere permisos de
 * almacenamiento: el selector usa el Storage Access Framework y MediaStore
 * deja escribir sin permiso los archivos propios (Android 10+).
 */
class MainActivity : FlutterActivity() {

    private var resultadoPendiente: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CANAL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "elegirSonido" -> elegirSonido(result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun elegirSonido(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            result.error(
                "no_soportado",
                "Elegir un audio propio requiere Android 10 o superior.",
                null,
            )
            return
        }
        if (resultadoPendiente != null) {
            result.error("ocupado", "Ya hay una selección en curso.", null)
            return
        }
        resultadoPendiente = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "audio/*"
        }
        startActivityForResult(intent, CODIGO_SELECCION)
    }

    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != CODIGO_SELECCION) {
            super.onActivityResult(requestCode, resultCode, data)
            return
        }
        val resultado = resultadoPendiente ?: return
        resultadoPendiente = null

        val origen = data?.data
        if (resultCode != Activity.RESULT_OK || origen == null) {
            resultado.success(null) // El usuario canceló.
            return
        }

        // La copia puede tardar con archivos grandes: fuera del hilo de UI.
        Thread {
            try {
                val nombre = nombreDe(origen)
                val uri = importarAMediaStore(origen, nombre)
                runOnUiThread {
                    resultado.success(mapOf("uri" to uri.toString(), "nombre" to nombre))
                }
            } catch (e: Exception) {
                runOnUiThread {
                    resultado.error("importacion_fallida", e.message ?: "Error desconocido", null)
                }
            }
        }.start()
    }

    private fun nombreDe(uri: Uri): String {
        contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
            ?.use { c ->
                if (c.moveToFirst()) {
                    val n = c.getString(0)
                    if (!n.isNullOrBlank()) return n
                }
            }
        return "audio_${System.currentTimeMillis()}.mp3"
    }

    private fun tamanoDe(uri: Uri): Long {
        contentResolver.query(uri, arrayOf(OpenableColumns.SIZE), null, null, null)
            ?.use { c ->
                if (c.moveToFirst() && !c.isNull(0)) return c.getLong(0)
            }
        return -1L
    }

    /** Copia el audio a Alarms/RecordApp y devuelve su URI de MediaStore. */
    private fun importarAMediaStore(origen: Uri, nombre: String): Uri {
        val coleccion = MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        val rutaRelativa = Environment.DIRECTORY_ALARMS + "/RecordApp/"
        val tamano = tamanoDe(origen)

        // Si ya se importó este mismo archivo (mismo nombre y tamaño), se reutiliza.
        if (tamano >= 0) {
            contentResolver.query(
                coleccion,
                arrayOf(MediaStore.Audio.Media._ID),
                "${MediaStore.Audio.Media.DISPLAY_NAME}=? AND " +
                    "${MediaStore.Audio.Media.RELATIVE_PATH}=? AND " +
                    "${MediaStore.Audio.Media.SIZE}=?",
                arrayOf(nombre, rutaRelativa, tamano.toString()),
                null,
            )?.use { c ->
                if (c.moveToFirst()) {
                    return ContentUris.withAppendedId(coleccion, c.getLong(0))
                }
            }
        }

        val valores = ContentValues().apply {
            put(MediaStore.Audio.Media.DISPLAY_NAME, nombre)
            put(MediaStore.Audio.Media.MIME_TYPE, contentResolver.getType(origen) ?: "audio/mpeg")
            put(MediaStore.Audio.Media.RELATIVE_PATH, rutaRelativa)
            put(MediaStore.Audio.Media.IS_ALARM, 1)
            put(MediaStore.Audio.Media.IS_PENDING, 1)
        }
        val destino = contentResolver.insert(coleccion, valores)
            ?: throw IllegalStateException("MediaStore no pudo crear el archivo.")

        try {
            val entrada = contentResolver.openInputStream(origen)
                ?: throw IllegalStateException("No se pudo leer el audio elegido.")
            val salida = contentResolver.openOutputStream(destino)
                ?: throw IllegalStateException("No se pudo escribir el audio.")
            entrada.use { i -> salida.use { o -> i.copyTo(o) } }

            valores.clear()
            valores.put(MediaStore.Audio.Media.IS_PENDING, 0)
            contentResolver.update(destino, valores, null, null)
        } catch (e: Exception) {
            contentResolver.delete(destino, null, null)
            throw e
        }
        return destino
    }

    companion object {
        private const val CANAL = "com.alessandro.recordapp/sonidos"
        private const val CODIGO_SELECCION = 4711
    }
}