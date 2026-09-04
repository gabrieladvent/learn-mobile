allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

// Plugin pihak ketiga (mis. flutter_secure_storage) menulis `compileSdk = 37`
// di build.gradle-nya sendiri. Google tidak pernah merilis paket "android-37";
// yang ada hanya android-37.0 / 37.1 / 37.2 (skema minor version sejak API 36).
// Blok ini melengkapi deklarasi mereka dengan minor version 0 supaya AGP
// menemukan platform yang benar-benar terpasang.
//
// Harus berada SEBELUM blok evaluationDependsOn(":app") di bawah: blok itu
// memaksa :app dievaluasi lebih awal, dan afterEvaluate menolak project yang
// sudah selesai dievaluasi.
subprojects {
    afterEvaluate {
        extensions.findByName("android")?.withGroovyBuilder {
            if (getProperty("compileSdk") == 37 && getProperty("compileSdkMinor") == null) {
                setProperty("compileSdkMinor", 0)
            }
        }
    }
}

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
