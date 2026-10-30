plugins { id("com.android.application"); id("org.jetbrains.kotlin.android") }
android {
    namespace = "com.widgettodo"
    compileSdk = 35
    defaultConfig {
        applicationId = "com.widgettodo"
        minSdk = 26
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"
        buildConfigField("String", "REVENUECAT_API_KEY", "\"${providers.gradleProperty("revenueCatApiKey").orElse("").get()}\"")
    }
    buildFeatures { buildConfig = true }
    compileOptions { sourceCompatibility = JavaVersion.VERSION_17; targetCompatibility = JavaVersion.VERSION_17 }
    kotlinOptions { jvmTarget = "17" }
}
dependencies {
    implementation("com.revenuecat.purchases:purchases:8.15.1")
    testImplementation("junit:junit:4.13.2")
}
