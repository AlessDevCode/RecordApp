# --- Gson: flutter_local_notifications lo usa para guardar y leer las
# --- notificaciones programadas. Sin esto R8 rompe zonedSchedule en release.
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepclassmembers,allowobfuscation class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# --- Clases del plugin que Gson serializa (modelos de notificación).
-keep class com.dexterous.flutterlocalnotifications.** { *; }