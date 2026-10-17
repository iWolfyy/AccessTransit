import java.util.Base64

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services") apply false
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val dartDefines = providers.gradleProperty("dart-defines").orNull
    ?.split(",")?.map { String(Base64.getDecoder().decode(it)) } ?: emptyList()
val localValidation = dartDefines.contains("LOCAL_VALIDATION=true")
val localApi = dartDefines.contains("LOCAL_API=true")

// Native builds target the main app only. Keep emulator checks in automated
// tests, and never let an old walkthrough command replace the normal app.
if (localValidation) {
    error("The separate Local Test APK is retired. Use automated emulator tests; build the main app at final delivery.")
}
apply(plugin = "com.google.gms.google-services")

if (localApi && gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true) || it.contains("profile", ignoreCase = true)
}) {
    error("LOCAL_API is debug-only. Release/profile builds require an HTTPS backend.")
}

android {
    namespace = "com.accesstransit.access_transit"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.accesstransit.access_transit"
        manifestPlaceholders["appLabel"] = "Access Transit"
        manifestPlaceholders["localHttp"] = "false"
        manifestPlaceholders["networkSecurity"] = "@xml/network_security_config"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        debug {
            if (localApi) {
                manifestPlaceholders["networkSecurity"] = "@xml/debug_localhost_network_security"
            }
        }
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
