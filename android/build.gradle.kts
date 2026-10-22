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

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
// camera_android_camerax's Java compile fails ("class file for
// androidx.concurrent.futures.CallbackToFutureAdapter not found") because
// camera-core 1.5.x does not expose concurrent-futures on the compile classpath.
subprojects {
    if (name == "camera_android_camerax") {
        plugins.withId("com.android.library") {
            dependencies {
                add("implementation", "androidx.concurrent:concurrent-futures:1.2.0")
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
