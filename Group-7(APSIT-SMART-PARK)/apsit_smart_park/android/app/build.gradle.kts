plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Firebase requires google-services plugin
    id("com.google.gms.google-services")
}

android {
    namespace = "com.apsit.apsit_smart_park"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Needed by flutter_local_notifications
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.apsit.smartpark"
        // Firebase Auth & Firestore require minSdk 23+
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = 1
        versionName = "1.0.0"
        // Required when dependency count exceeds 64K methods
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // Using debug signing for now so `flutter run --release` works.
            // Replace with a proper keystore before publishing to Play Store.
            signingConfig = signingConfigs.getByName("debug")
            // Enable shrinking for smaller APK
            isMinifyEnabled = false
            isShrinkResources = false
        }
        debug {
            applicationIdSuffix = ".debug"
            isDebuggable = true
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Required for flutter_local_notifications on Android < 26
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
