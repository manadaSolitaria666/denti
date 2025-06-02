// Importar la clase Properties de Java
import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Define la variable flutter aquí para que sea accesible
val localProperties = Properties() // Ahora Properties() es reconocido
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.reader().use { reader ->
        localProperties.load(reader)
    }
}

val flutterVersionCode = localProperties.getProperty("flutter.versionCode")?.toIntOrNull() ?: 1
val flutterVersionName = localProperties.getProperty("flutter.versionName") ?: "1.0"

android {
    namespace = "com.example.dental_ai_app"
    // Intenta obtener compileSdk desde el plugin de Flutter, o usa un valor fijo si falla.
    // La configuración de Flutter debería definir flutter.compileSdkVersion.
    // CORRECCIÓN: Actualizar a SDK 35 como lo requieren las dependencias
    compileSdk = if (rootProject.ext.has("flutterCompileSdkVersion")) {
                     // Si flutter.compileSdkVersion es menor que 35, usa 35.
                     // De lo contrario, usa el valor de flutter.compileSdkVersion.
                     // Esto asume que el plugin de Flutter puede no estar actualizado a 35 aún.
                     // La forma más directa es simplemente poner 35.
                     // (rootProject.ext.get("flutterCompileSdkVersion") as Int).coerceAtLeast(35)
                     35 // Actualizado a 35
                 } else {
                     35 // Valor por defecto si no se encuentra, actualizado a 35
                 }

    ndkVersion = "27.0.12077973" // Asegúrate de que esta versión de NDK esté instalada

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.example.dental_ai_app"
        // Intenta obtener minSdk y targetSdk desde el plugin de Flutter, o usa valores fijos.
        minSdk = if (rootProject.ext.has("flutterMinSdkVersion")) {
                     rootProject.ext.get("flutterMinSdkVersion") as Int
                 } else {
                     23 // Valor por defecto mínimo
                 }
        // CORRECCIÓN: Actualizar targetSdk también por consistencia y buenas prácticas
        targetSdk = if (rootProject.ext.has("flutterTargetSdkVersion")) {
                        // (rootProject.ext.get("flutterTargetSdkVersion") as Int).coerceAtLeast(35)
                        35 // Actualizado a 35
                    } else {
                        35 // Valor por defecto, actualizado a 35
                    }
        versionCode = flutterVersionCode
        versionName = flutterVersionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
     // Necesario para que signingConfigs.getByName("debug") funcione sin más configuración
    signingConfigs {
        maybeCreate("debug")
    }
}

// El bloque flutter ya lo tenías y debería estar bien si el plugin lo configura
// flutter {
//     source = "../.."
// }

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.1.1")) // O la última versión del BOM
    implementation("com.google.firebase:firebase-analytics-ktx") // Usar -ktx para Kotlin
    // Añade aquí otros SDKs de Firebase que estés utilizando, preferiblemente las versiones -ktx
    implementation("com.google.firebase:firebase-auth-ktx")
    implementation("com.google.firebase:firebase-firestore-ktx")
    implementation("com.google.firebase:firebase-storage-ktx")
    // ... otras dependencias ...

    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4") // O la última versión estable
}

