import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val wardrobePreview = providers.environmentVariable("MY_POODLE_WARDROBE_PREVIEW").orNull == "1"

val releaseSigningFile = rootProject.file("key.properties")
val releaseSigning = Properties().apply {
    if (releaseSigningFile.exists()) releaseSigningFile.inputStream().use { load(it) }
}

android {
    namespace = "com.betitoglez.mypoodle"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = if (wardrobePreview) {
            "com.betitoglez.mypoodle.wardrobepreview"
        } else {
            "com.betitoglez.mypoodle"
        }
        manifestPlaceholders["mypoodleAppLabel"] =
            if (wardrobePreview) "Vestuario 3D" else "@string/app_name"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24 // Flutter 3.50 e in_app_purchase 3.3.1
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (releaseSigningFile.exists()) {
                keyAlias = releaseSigning.getProperty("keyAlias")
                keyPassword = releaseSigning.getProperty("keyPassword")
                // Rutas relativas a android/, donde vive key.properties.
                storeFile = releaseSigning.getProperty("storeFile")?.let { rootProject.file(it) }
                storePassword = releaseSigning.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // Falla la validación de firma si falta key.properties; nunca usar debug para Release.
            signingConfig = signingConfigs.getByName("release")
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
