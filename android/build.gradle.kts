plugins {
    id("com.android.library")
    kotlin("android")
}

android {
    namespace = "com.plugin.multipay"
    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        minSdk = 21
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

dependencies {
    implementation("com.alipay.sdk:alipaysdk-android:+@aar")
    implementation("com.tencent.mm.opensdk:wechat-sdk-android:+")
    implementation(files("src/main/libs/UPPayAssistEx.jar"))

    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
    implementation("androidx.core:core-ktx:1.12.0")
}
