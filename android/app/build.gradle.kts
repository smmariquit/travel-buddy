val kotlin_version = "1.9.0"

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.travel.buddy"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"  // Set JVM target to 1.8 for better compatibility with Kotlin
    }

    defaultConfig {
        applicationId = "com.travel.buddy"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    dependencies {

        coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")

        implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk7:$kotlin_version")
        implementation("com.google.android.gms:play-services-base:18.2.0")
        implementation("com.google.android.gms:play-services-maps:18.1.0")

    }

}

flutter {
    source = "../.."
}
