import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}
val hasReleaseSigningConfig = keystorePropertiesFile.exists()

android {
    namespace = "com.example.meter_reader_flutter"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    if (hasReleaseSigningConfig) {
        signingConfigs {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                    ?: throw GradleException("Missing 'keyAlias' in android/key.properties")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                    ?: throw GradleException("Missing 'keyPassword' in android/key.properties")
                storeFile = file(
                    keystoreProperties.getProperty("storeFile")
                        ?: throw GradleException("Missing 'storeFile' in android/key.properties")
                )
                storePassword = keystoreProperties.getProperty("storePassword")
                    ?: throw GradleException("Missing 'storePassword' in android/key.properties")
            }
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "ph.gov.dapcwd.meterreader"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            if (hasReleaseSigningConfig) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

tasks.configureEach {
    if ((name.startsWith("assemble") || name.startsWith("bundle")) &&
        name.endsWith("Release")
    ) {
        doFirst {
            if (!hasReleaseSigningConfig) {
                throw GradleException(
                    "Production release signing is not configured. " +
                        "Create android/key.properties and provide a production keystore."
                )
            }
        }
    }
}

flutter {
    source = "../.."
}
