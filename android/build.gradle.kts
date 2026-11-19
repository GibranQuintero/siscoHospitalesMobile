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
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    val fijarSdk = Action<Project> {
        val android = extensions.findByName("android") ?: return@Action
        android.javaClass.methods
            .firstOrNull { it.name == "setCompileSdk" && it.parameterCount == 1 }
            ?.invoke(android, 36)
    }
    if (state.executed) fijarSdk.execute(this) else afterEvaluate(fijarSdk)
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
