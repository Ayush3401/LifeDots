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
        // CI passes these per release (-PversionName=1.2 -PversionCode=<run number>);
        // versionCode must keep increasing or phones refuse the update.
        versionCode = providers.gradleProperty("versionCode").map(String::toInt).getOrElse(1)
        versionName = providers.gradleProperty("versionName").getOrElse("1.0")
    }

    // The release key comes from environment variables (GitHub secrets in CI).
    // Without them, release builds fall back to the local debug key, which is
    // fine for trying things out but can't update an installed release build.
    val keystorePath = System.getenv("ANDROID_KEYSTORE_PATH")
    val releaseSigning = if (keystorePath != null && file(keystorePath).exists()) {
        signingConfigs.create("release") {
            storeFile = file(keystorePath)
            storeType = "pkcs12"
            storePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")
            keyAlias = System.getenv("ANDROID_KEY_ALIAS")
            keyPassword = System.getenv("ANDROID_KEY_PASSWORD")
        }
    } else {
        signingConfigs.getByName("debug")
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"))
            signingConfig = releaseSigning
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}
