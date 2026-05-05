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
    val fixNamespace = {
        if (project.hasProperty("android")) {
            val android = project.extensions.findByName("android") as? com.android.build.gradle.BaseExtension
            android?.let {
                if (it.namespace == null) {
                    when (project.name) {
                        "blue_thermal_printer" -> it.namespace = "id.kakzaki.blue_thermal_printer"
                        "isar_flutter_libs" -> it.namespace = "dev.isar.isar_flutter_libs"
                        else -> it.namespace = "com.${project.name.replace("-", "_")}"
                    }
                }
            }
        }
    }

    if (project.state.executed) {
        fixNamespace()
    } else {
        project.afterEvaluate { fixNamespace() }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
