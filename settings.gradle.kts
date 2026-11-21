plugins {
    // Lets Gradle download JDK 21 when it is not installed locally.
    id("org.gradle.toolchains.foojay-resolver-convention") version "1.0.0"
}

rootProject.name = "qti-copilot"

include("engine", "api")
