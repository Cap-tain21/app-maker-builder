#!/usr/bin/env bash
set -euo pipefail
# build_repack_auto.sh - inject app_content.zip into template_signed.apk and sign
# Usage: cd ~/app-maker-builder && scripts/build_repack_auto.sh
# Set env overrides before running if needed:
#   TEMPLATE_APK, USER_ZIP, KEYSTORE, KEY_ALIAS, KS_PASS, KEY_PASS, UAS_JAR, OUT_DIR

REPO_DIR="$(pwd)"
TEMPLATE_APK="${TEMPLATE_APK:-$REPO_DIR/template/template_signed.apk}"
USER_ZIP="${USER_ZIP:-$REPO_DIR/app_content.zip}"
KEYSTORE="${KEYSTORE:-$REPO_DIR/keystore/mykeystore.jks}"
KEY_ALIAS="${KEY_ALIAS:-mykey}"
KS_PASS="${KS_PASS:-android}"
KEY_PASS="${KEY_PASS:-android}"
UAS_JAR="${UAS_JAR:-$HOME/uber-apk-signer-1.1.0.jar}"
OUT_DIR="${OUT_DIR:-$REPO_DIR/output}"

echo "Working dir: $REPO_DIR"
echo "Template APK: $TEMPLATE_APK"
echo "User ZIP:     $USER_ZIP"
echo "Keystore:     $KEYSTORE"
echo "Output dir:   $OUT_DIR"

# Basic checks
if [ ! -f "$TEMPLATE_APK" ]; then
  echo "ERROR: template_signed.apk not found at $TEMPLATE_APK"
  echo "Place your prebuilt template_signed.apk at that path and try again."
  exit 1
fi
if [ ! -f "$USER_ZIP" ]; then
  echo "ERROR: app_content.zip not found at $USER_ZIP"
  echo "Export your project ZIP from the web UI and put it there."
  exit 1
fi
mkdir -p "$OUT_DIR"
WORKDIR="$(mktemp -d)"
cleanup(){ rm -rf "$WORKDIR"; }
trap cleanup EXIT

echo "Using temp workdir: $WORKDIR"

# 1) unzip template APK
echo "Unzipping template APK..."
unzip -q "$TEMPLATE_APK" -d "$WORKDIR/template_unzip"

# 2) replace assets/www
echo "Replacing assets/www with user content..."
rm -rf "$WORKDIR/template_unzip/assets/www"
mkdir -p "$WORKDIR/template_unzip/assets/www"
unzip -q "$USER_ZIP" -d "$WORKDIR/user_project"
# copy user's files into assets/www
cp -r "$WORKDIR/user_project/"* "$WORKDIR/template_unzip/assets/www/" || true

# 3) repackage unsigned apk
UNSIGNED_APK="$WORKDIR/unsigned.apk"
echo "Repacking unsigned APK -> $UNSIGNED_APK"
pushd "$WORKDIR/template_unzip" > /dev/null
# use -0 no compression for speed; use -r9 for compressed if desired
zip -r -0 "$UNSIGNED_APK" . 
popd > /dev/null

# 4) zipalign if available
ZIPALIGNED="$WORKDIR/aligned.apk"
if command -v zipalign >/dev/null 2>&1; then
  echo "Running zipalign..."
  zipalign -f -p 4 "$UNSIGNED_APK" "$ZIPALIGNED"
  APK_TO_SIGN="$ZIPALIGNED"
else
  echo "zipalign not found — signing unsigned APK directly"
  APK_TO_SIGN="$UNSIGNED_APK"
fi

# 5) signing
FINAL_APK="$OUT_DIR/$(date +%Y%m%d%H%M%S)-userapp.apk"

# Prefer apksigner (Android SDK). If available, use it with explicit keystore.
if command -v apksigner >/dev/null 2>&1 && [ -f "$KEYSTORE" ]; then
  echo "Signing with apksigner using keystore $KEYSTORE ..."
  # apksigner requires java keystore; use --out to write signed apk
  if command -v zipalign >/dev/null 2>&1; then
    # if zipalign was used, APK_TO_SIGN already aligned
    :
  fi
  apksigner sign --ks "$KEYSTORE" --ks-key-alias "$KEY_ALIAS" --ks-pass "pass:$KS_PASS" --key-pass "pass:$KEY_PASS" --out "$FINAL_APK" "$APK_TO_SIGN" 2>/dev/null || {
    # older apksigner may not support --out; fallback to copy then sign
    cp "$APK_TO_SIGN" "$FINAL_APK"
    apksigner sign --ks "$KEYSTORE" --ks-key-alias "$KEY_ALIAS" --ks-pass "pass:$KS_PASS" --key-pass "pass:$KEY_PASS" "$FINAL_APK"
  }
  echo "Signed APK: $FINAL_APK"
  exit 0
fi

# Fallback: use uber-apk-signer if available
if [ -f "$UAS_JAR" ] || compgen -G "$HOME/uber-apk-signer-*.jar" >/dev/null 2>&1; then
  # find jar
  if [ ! -f "$UAS_JAR" ]; then
    UAS_JAR="$(ls -1 $HOME/uber-apk-signer-*.jar 2>/dev/null | head -n1 || true)"
  fi
  if [ -z "$UAS_JAR" ]; then
    echo "uber-apk-signer jar not found. Please download it to $HOME or install apksigner."
    exit 1
  fi
  echo "Signing with uber-apk-signer (jar: $UAS_JAR)..."
  # uber-apk-signer auto-detects keystores inside current dir; copy keystore there
  TMPKS="$WORKDIR/keystore"
  mkdir -p "$TMPKS"
  if [ -f "$KEYSTORE" ]; then
    cp "$KEYSTORE" "$TMPKS/"
  fi
  pushd "$TMPKS" > /dev/null
  # run signer; allow resign; do not use apktool (faster)
  java -jar "$UAS_JAR" -a "$APK_TO_SIGN" --allowResign --useApktool 0
  popd > /dev/null

  # uber-apk-signer writes signed apk next to the input; find newest .apk
  SIGNED="$(find "$PWD" -maxdepth 2 -type f -name '*.apk' -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -n1 | cut -d' ' -f2- || true)"
  # also check workdir for produced apks
  if [ -z "$SIGNED" ]; then
    SIGNED="$(find "$WORKDIR" -type f -name '*.apk' -printf '%T@ %p\n' | sort -n | tail -n1 | cut -d' ' -f2- || true)"
  fi
  if [ -z "$SIGNED" ]; then
    echo "ERROR: uber-apk-signer did not produce a signed APK automatically. Check the jar output."
    exit 1
  fi
  cp "$SIGNED" "$FINAL_APK"
  echo "Signed APK: $FINAL_APK"
  exit 0
fi

echo "ERROR: No signing tool found (apksigner or uber-apk-signer)."
echo "Install Android build-tools (apksigner) or place uber-apk-signer jar at $HOME/"
exit 1
