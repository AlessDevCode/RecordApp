// android/app/sync_audio_raw.gradle.kts
//
// Copia automáticamente los audios de <proyecto>/assets/audio a
// android/app/src/main/res/raw antes de cada compilación, para que las
// notificaciones nativas puedan reproducirlos con la app cerrada.
//
// Los nombres se normalizan igual que AlertSound.rawResourceName (Dart):
//   alerta Neón.mp3  ->  alerta_ne_n_mp3.mp3
// Si cambias esta regla, cámbiala también en alert_sound.dart.
import java.io.File

val audioExtensions = setOf("mp3", "wav", "ogg", "m4a", "aac")

fun rawName(file: File): String {
    val base = file.nameWithoutExtension.lowercase().replace(Regex("[^a-z0-9_]"), "_")
    val safe = if (base.isNotEmpty() && base[0] in 'a'..'z') base else "s_$base"
    return "${safe}_${file.extension.lowercase()}"
}

val syncAudioRaw = tasks.register("syncAudioRaw") {
    group = "recordapp"
    description = "Sincroniza assets/audio con res/raw"

    // android/ es rootProject.projectDir; assets/ está un nivel arriba.
    val sourceDir = rootProject.projectDir.parentFile.resolve("assets/audio")
    val targetDir = projectDir.resolve("src/main/res/raw")

    doLast {
        targetDir.mkdirs()

        val sources = sourceDir
            .listFiles { f -> f.isFile && f.extension.lowercase() in audioExtensions }
            ?.toList() ?: emptyList()
        val expected = sources.associateBy { "${rawName(it)}.${it.extension.lowercase()}" }

        // Elimina audios huérfanos (no toca keep.xml ni otros recursos).
        targetDir.listFiles()
            ?.filter { it.isFile && it.extension.lowercase() in audioExtensions && it.name !in expected }
            ?.forEach { it.delete() }

        expected.forEach { (name, src) ->
            val dst = File(targetDir, name)
            if (!dst.exists() || dst.length() != src.length() || dst.lastModified() < src.lastModified()) {
                src.copyTo(dst, overwrite = true)
            }
        }
        logger.lifecycle("syncAudioRaw: ${expected.size} audio(s) en res/raw")
    }
}

tasks.matching { it.name == "preBuild" }.configureEach {
    dependsOn(syncAudioRaw)
}
