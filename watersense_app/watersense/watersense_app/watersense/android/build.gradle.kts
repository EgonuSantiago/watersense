allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// 🔧 Corrige o diretório de build para projetos Flutter
val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// 🔄 Garante que o módulo app seja avaliado antes dos outros
subprojects {
    project.evaluationDependsOn(":app")
}

// 🧹 Task para limpar o build
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// ✅ Força todos os módulos Android a usar SDK 33 (corrige o erro do lStar)
gradle.projectsEvaluated {
    subprojects {
        if (this.hasProperty("android")) {
            try {
                val androidExtension =
                    this.property("android") as com.android.build.gradle.BaseExtension
                androidExtension.compileSdkVersion(34)
                androidExtension.defaultConfig {
                    targetSdkVersion(34)
                }
                println("✅ SDK aplicado com sucesso em ${this.name}")
            } catch (e: Exception) {
                println("⚠️ Falha ao aplicar SDK override em ${this.name}: ${e.message}")
            }
        }
    }
}
