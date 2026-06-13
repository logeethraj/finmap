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
    project.evaluationDependsOn(":app")
    plugins.withId("com.android.library") {
        extensions.findByType<com.android.build.gradle.LibraryExtension>()?.apply {
            compileSdk = 36
        }
    }
    plugins.withId("com.android.application") {
        extensions.findByType<com.android.build.gradle.AppExtension>()?.apply {
            compileSdkVersion(36)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}