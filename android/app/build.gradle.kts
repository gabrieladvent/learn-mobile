plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.learn_mobile"
    // flutter_secure_storage butuh SDK 37. Google merilis API 37 hanya sebagai
    // "minor version" (android-37.0, 37.1, ...), tidak ada paket android-37 polos.
    // Tanpa compileSdkMinor, AGP mencari android-37 dan build gagal.
    compileSdk = 37
    compileSdkMinor = 0
    ndkVersion = flutter.ndkVersion

    buildFeatures {
        // Sejak AGP 9, `resValue` di productFlavors harus dinyalakan eksplisit.
        // Tanpa baris ini build gagal dengan "contains custom resource values,
        // but the feature is disabled" — dan pesannya tidak menyebut di mana
        // harus dinyalakan.
        resValues = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Identitas aplikasi di Play Store. TIDAK BISA DIUBAH setelah aplikasi
        // terbit — Play memakainya sebagai kunci utama, dan mengubahnya berarti
        // aplikasi baru yang kehilangan seluruh pemasangan dan ulasannya.
        applicationId = "lms.student"
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

    // Tiga lingkungan, dengan applicationId yang berbeda-beda.
    //
    // Kenapa bukan cuma `--dart-define`: dart-define hanya mengubah nilai DI
    // DALAM aplikasi. Selama applicationId-nya sama, Android menganggap semua
    // build itu aplikasi yang sama — memasang build dev akan MENIMPA aplikasi
    // prod milik siswa, dan keduanya tidak bisa hidup berdampingan di satu HP.
    // Padahal itu persis yang dibutuhkan saat uji lapangan di sekolah nanti.
    //
    // Nama aplikasinya juga dibedakan supaya di layar HP tidak ada yang salah
    // buka: "Learn Dev" jelas bukan aplikasi yang dipakai siswa sungguhan.
    flavorDimensions += "env"

    productFlavors {
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            resValue("string", "app_name", "Learn Dev")
        }

        create("staging") {
            dimension = "env"
            applicationIdSuffix = ".staging"
            versionNameSuffix = "-staging"
            resValue("string", "app_name", "Learn Staging")
        }

        // Tanpa akhiran: inilah yang terbit ke Play Store.
        create("prod") {
            dimension = "env"
            resValue("string", "app_name", "Learn")
        }
    }

    buildTypes {
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
