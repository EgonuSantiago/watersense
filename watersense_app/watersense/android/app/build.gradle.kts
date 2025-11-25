plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.watersense"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.example.watersense"
        minSdk = flutter.minSdkVersion // minSdk mínimo para permissões em runtime
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"

        // Configurações para evitar problemas de multidex se precisar
        multiDexEnabled = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

   signingConfigs {
    create("release") {
        keyAlias = "watersense_key"
        keyPassword = "378203"
        storeFile = file("release-key.jks")
        storePassword = "378203"
    }
}

buildTypes {
    getByName("release") {
        signingConfig = signingConfigs.getByName("release")
        isMinifyEnabled = false
        isShrinkResources = false
    }
}

    lint {
        disable.add("InvalidPackage")
        disable.add("ObsoleteLintCustomCheck")
    }
}

flutter {
    source = "../.."
}
