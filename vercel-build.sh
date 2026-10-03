#!/bin/bash
set -e

echo "🚀 [RoadEdge AI] Vercel Cloud Build Pipeline Initialized"

# Check if flutter is already installed
if ! command -v flutter &> /dev/null; then
  echo "⚡ Flutter not found in system PATH. Bootstrapping Flutter stable branch..."
  if [ ! -d ".flutter_sdk" ]; then
    git clone --depth 1 --branch stable https://github.com/flutter/flutter.git .flutter_sdk
  fi
  export PATH="$PWD/.flutter_sdk/bin:$PATH"
else
  echo "✅ Flutter detected in build environment."
fi

# Print version
flutter --version

# Locate project directory
if [ -d "roadedge_ai" ]; then
  cd roadedge_ai
fi

echo "📦 Resolving Flutter dependencies..."
flutter pub get

echo "⚡ Compiling RoadEdge AI for Web (Release INT8 CanvasKit/Wasm)..."
flutter build web --release --no-wasm-dry-run

echo "✅ Web build complete! Output located at $(pwd)/build/web"
