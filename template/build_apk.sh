#!/bin/bash

# 🚀 APK Builder for MyApp (WebView)

# Go to template folder
cd template || exit 1

# Make sure root Gradle wrapper is executable
chmod +x gradlew

# Ensure app_content.zip exists
if [ ! -f ../app_content.zip ]; then
  echo "❌ No app_content.zip found! Please create it first."
  exit 1
fi

# Unzip web content into app module
mkdir -p app/src/main/assets/www/myapp
unzip -o ../app_content.zip -d app/src/main/assets/www/myapp/

# Run Gradle build
echo "📦 Building: MyApp (com.example.myapp)"
./gradlew assembleDebug
