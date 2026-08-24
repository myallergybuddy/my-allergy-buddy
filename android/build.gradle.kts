buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.2")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// Register before evaluationDependsOn so already-evaluated projects don't break.
subprojects {
    afterEvaluate {
        extensions.findByName("android")?.let { androidExt ->
            try {
                val setCompileSdk = androidExt.javaClass.methods.find {
                    it.name == "setCompileSdk" && it.parameterTypes.size == 1
                }
                if (setCompileSdk != null) {
                    setCompileSdk.invoke(androidExt, 36)
                } else {
                    androidExt.javaClass
                        .getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType)
                        .invoke(androidExt, 36)
                }
            } catch (_: Exception) {
                // Non-Android subprojects
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
