allprojects {
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("https://maven.columbus.heytapmobi.com/repository/heytap-health-releases/")
            isAllowInsecureProtocol = true
            credentials {
                username = "healthUser"
                password = "8174a9eac1264495b593a9d5ab221491"
            }
        }
        maven {
            url = uri("https://maven.columbus.heytapmobi.com/repository/heytap-health-snapshots/")
            isAllowInsecureProtocol = true
            credentials {
                username = "healthUser"
                password = "8174a9eac1264495b593a9d5ab221491"
            }
        }
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
