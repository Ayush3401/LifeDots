plugins {
    id("com.android.application")
}

android {
    namespace = "io.github.ayush3401.lifedots"
    compileSdk = 36

    defaultConfig {
        applicationId = "io.github.ayush3401.lifedots"
        minSdk = 27          // Android 8.1: needed for WallpaperColors
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"))
            // Signed with the local debug key so a release APK can be shared and
            // sideloaded without extra setup. Use a real keystore before Play Store.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}
