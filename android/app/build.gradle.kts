plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.schengentrackerapp.schengen"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.schengentrackerapp.schengen"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (System.getenv("CI") == "true") {
                // For CI builds, use environment variables
                storeFile = System.getenv("KEYSTORE_FILE")?.let { file(it) }
                storePassword = System.getenv("KEYSTORE_PASSWORD")
                keyAlias = System.getenv("KEY_ALIAS")
                keyPassword = System.getenv("KEY_PASSWORD")
            } else {
                // For local development, you can set up a local.properties with these values
                val properties = project.rootProject.file("local.properties")
                if (properties.exists()) {
                    val props = java.util.Properties()
                    props.load(java.io.FileInputStream(properties))
                    val keystoreFile = props.getProperty("keystore.file")
                    if (keystoreFile != null) {
                        storeFile = file(keystoreFile)
                        storePassword = props.getProperty("keystore.password")
                        keyAlias = props.getProperty("key.alias")
                        keyPassword = props.getProperty("key.password")
                    } else {
                        println("No signing config found in local.properties")
                    }
                } else {
                    println("No local.properties file found")
                }
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            
            // Use release signing config if available, otherwise fall back to debug
            if ((signingConfigs.findByName("release") as com.android.build.gradle.internal.dsl.SigningConfig?)?.storeFile != null) {
                signingConfig = signingConfigs.getByName("release")
                println("Using release signing config")
            } else {
                signingConfig = signingConfigs.getByName("debug")
                println("Using debug signing config")
            }
        }
        
        debug {
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
        }
    }
}

flutter {
    source = "../.."
}
