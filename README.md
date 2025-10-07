# App Maker Builder

A WebView-based Android APK builder you can run locally on Termux or via GitHub Actions. Users can generate APKs from HTML/CSS/JS content.

## Features

- Prebuilt WebView APK template.
- Build APK directly in Termux using `build_apk.sh`.
- GitHub Actions workflow to:
  - Build APK automatically.
  - Deploy HTML/CSS/JS preview to GitHub Pages.

## Setup (Termux)

```bash
# Clone repository
git clone https://github.com/Cap-tain21/app-maker-builder.git
cd app-maker-builder

# Run setup
bash setup_builder.sh

# Place your app content
mkdir myapp
nano myapp/index.html
nano myapp/style.css
nano myapp/script.js

# Zip your content
zip -r app_content.zip myapp/

# Configure app
nano app_config.txt
# Example:
# APP_NAME="My Cool App"
# PACKAGE_NAME="com.cap21.mycoolapp"
# VERSION_CODE="1"
# VERSION_NAME="1.0.0"

# Build APK
bash build_apk.sh

# APK output:
# output/MyCoolApp.apk
