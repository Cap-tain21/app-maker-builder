#!/data/data/com.termux/files/usr/bin/bash
set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

echo -e "${GREEN}🚀 Starting APK Builder...${NC}"

if [ ! -d "template" ]; then
    echo -e "${RED}❌ Template folder not found!${NC}"
    exit 1
fi

if [ ! -f "app_content.zip" ]; then
    echo -e "${RED}❌ No app content found!${NC}"
    echo "Please provide app_content.zip with your HTML/CSS/JS files"
    exit 1
fi

if [ -f "app_config.txt" ]; then
    source app_config.txt
else
    APP_NAME="MyApp"
    PACKAGE_NAME="com.example.myapp"
    VERSION_CODE="1"
    VERSION_NAME="1.0.0"
fi

echo -e "${YELLOW}📦 Building: $APP_NAME ($PACKAGE_NAME)${NC}"
rm -rf build
mkdir -p build
cp -r template/* build/
find build -name "*.java" -exec sed -i "s/com\\.example\\.appmaker/$PACKAGE_NAME/g" {} +
find build -name "AndroidManifest.xml" -exec sed -i "s/com\\.example\\.appmaker/$PACKAGE_NAME/g" {} +
find build -name "strings.xml" -exec sed -i "s/My App/$APP_NAME/g" {} +
unzip -q app_content.zip -d build/app/src/main/assets/www/

cd build
chmod +x gradlew || true
./gradlew assembleDebug || { echo -e "${RED}Build failed!${NC}"; exit 1; }

APK_FILE="app/build/outputs/apk/debug/app-debug.apk"
if [ -f "$APK_FILE" ]; then
    cp "$APK_FILE" "../${APP_NAME// /_}.apk"
    echo -e "${GREEN}✅ APK saved as: ${APP_NAME// /_}.apk${NC}"
else
    echo -e "${RED}❌ APK file not found${NC}"
fi
