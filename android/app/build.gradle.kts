import groovy.json.JsonSlurper
import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val firebaseConfigFile = rootProject.file("../config/firebase.local.json")
val firebaseConfig = if (firebaseConfigFile.exists()) {
    @Suppress("UNCHECKED_CAST")
    (JsonSlurper().parse(firebaseConfigFile) as Map<String, Any?>)
        .mapValues { (_, value) -> value?.toString().orEmpty() }
} else {
    emptyMap()
}
val releaseBuildRequested = gradle.startParameter.taskNames.any {
    it.contains("Release", ignoreCase = true)
}

if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use(keystoreProperties::load)
} else if (releaseBuildRequested) {
    throw GradleException(
        "Release signing is not configured. Create android/key.properties before building a release."
    )
}

android {
    namespace = "com.puzzlejourney.puzzle_journey"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.puzzlejourney.puzzle_journey"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        resValue("string", "game_services_project_id", providers.gradleProperty("PLAY_GAMES_PROJECT_ID").getOrElse("0"))
        resValue("string", "firebase_project_id", firebaseConfig["FIREBASE_PROJECT_ID"].orEmpty())
        resValue("string", "firebase_api_key", firebaseConfig["FIREBASE_API_KEY"].orEmpty())
        resValue("string", "firebase_app_id", firebaseConfig["FIREBASE_APP_ID"].orEmpty())
        resValue("string", "firebase_sender_id", firebaseConfig["FIREBASE_SENDER_ID"].orEmpty())
        resValue("string", "play_games_web_client_id", firebaseConfig["PLAY_GAMES_WEB_CLIENT_ID"].orEmpty())
        resValue("string", "admob_android_rewarded_id", firebaseConfig["ADMOB_ANDROID_REWARDED_ID"].orEmpty())
        resValue("string", "admob_android_interstitial_id", firebaseConfig["ADMOB_ANDROID_INTERSTITIAL_ID"].orEmpty())
        resValue("string", "admob_android_banner_id", firebaseConfig["ADMOB_ANDROID_BANNER_ID"].orEmpty())
        manifestPlaceholders["admobAppId"] = providers.gradleProperty("ADMOB_APP_ID").getOrElse("ca-app-pub-3940256099942544~3347511713")
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
    }
}

dependencies {
    implementation("com.google.android.gms:play-services-games-v2:21.0.0")
}
