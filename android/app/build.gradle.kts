import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.minshawi.recitations"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.minshawi.recitations"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val keyAliasVal = keystoreProperties.getProperty("keyAlias")
            val keyPasswordVal = keystoreProperties.getProperty("keyPassword")
            val storeFileVal = keystoreProperties.getProperty("storeFile")
            val storePasswordVal = keystoreProperties.getProperty("storePassword")

            if (storeFileVal != null && file(storeFileVal).exists()) {
                keyAlias = keyAliasVal
                keyPassword = keyPasswordVal
                storeFile = file(storeFileVal)
                storePassword = storePasswordVal
            } else if (file("upload-keystore.jks").exists()) {
                keyAlias = keyAliasVal ?: "upload"
                keyPassword = keyPasswordVal ?: "minshawi123"
                storeFile = file("upload-keystore.jks")
                storePassword = storePasswordVal ?: "minshawi123"
            }
        }
    }

    buildTypes {
        release {
            val hasReleaseSigning = keystorePropertiesFile.exists() || file("upload-keystore.jks").exists()
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }

            // ── Size & security optimisation ──────────────────────────────────
            // R8 dead-code elimination: strips unused Dart JIT code paths,
            // unused Java/Kotlin classes, and minifies class/method names.
            isMinifyEnabled = true

            // Strips resources (drawables, layouts, strings) that are never
            // referenced after code shrinking. Requires isMinifyEnabled = true.
            isShrinkResources = true

            // ProGuard / R8 rule files.
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
