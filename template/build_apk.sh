#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
# This script assumes gradle wrapper exists in repo root (./gradlew)
if [ ! -f ./gradlew ]; then
  echo "gradlew not found in template/ — you can run 'gradle wrapper --gradle-version 7.5' on host to generate it."
  exit 1
fi
chmod +x ./gradlew
./gradlew :app:assembleDebug
