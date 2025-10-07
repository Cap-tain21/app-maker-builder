#!/data/data/com.termux/files/usr/bin/bash
echo "📥 Setting up APK Builder in Termux..."
pkg update && pkg upgrade -y
pkg install -y openjdk-17 gradle zip unzip wget
chmod +x build_apk.sh
echo "✅ Setup complete!"
echo "Usage: ./build_apk.sh"
