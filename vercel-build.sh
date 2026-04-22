#!/bin/bash
set -e

FLUTTER_DIR="$HOME/flutter"

echo ">>> Installing Flutter SDK to $FLUTTER_DIR..."
mkdir -p "$FLUTTER_DIR"
curl -fsSL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.41.2-stable.tar.xz \
  | tar xJ -C "$HOME"

export PATH="$PATH:$FLUTTER_DIR/bin"

echo ">>> Fixing git safe directory (Vercel runs as root)..."
git config --global --add safe.directory "$FLUTTER_DIR"
git config --global --add safe.directory "$FLUTTER_DIR/.pub-cache"

echo ">>> Flutter version:"
flutter --version

echo ">>> Disabling analytics..."
flutter config --no-analytics

echo ">>> Creating .env from environment variables..."
echo "SUPABASE_URL=$SUPABASE_URL" > .env
echo "SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY" >> .env
echo "POSTHOG_API_KEY=$POSTHOG_API_KEY" >> .env

echo ">>> Installing dependencies..."
flutter pub get

echo ">>> Building for web..."
flutter build web --release

echo ">>> Build complete. Output is in build/web"
