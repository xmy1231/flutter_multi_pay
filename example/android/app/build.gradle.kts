plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
    kotlin("android") version "2.3.20"
}

android {
    namespace = "com.example.multi_pay_example"
    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.example.multi_pay_example"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["ALIPAY_APPID"] = "2021001234567890"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

dependencies {
    implementation("com.alipay.sdk:alipaysdk-android:15.8.40")
    implementation("com.tencent.mm.opensdk:wechat-sdk-android:6.8.34")
}
