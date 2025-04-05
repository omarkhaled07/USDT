plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.usdt_express"
    compileSdk = flutter.compileSdkVersion.toInt()
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.usdt_express"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion.toInt()
        versionCode = flutter.versionCode.toInt()
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            storeFile = file("D:\\Omar\\Khamsat Projects\\usdt_express\\keystore\\key.jks")
            storePassword = "USDT123"           // استبدل بباسورد الـ keystore
            keyAlias = "key"                    // استبدل بـ alias الـ key
            keyPassword = "USDT123"            // استبدل بباسورد الـ key
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release") // استخدم إعدادات التوقيع اللي أضفتها
        }
    }
}

flutter {
    source = "../.."
}