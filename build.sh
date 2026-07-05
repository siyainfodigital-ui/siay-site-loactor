#!/bin/bash
echo "Downloading Flutter..."
if [ -d "flutter" ]; then
  echo "Flutter already exists"
else
  git clone https://github.com/flutter/flutter.git -b stable
fi
export PATH="$PATH:`pwd`/flutter/bin"
echo "Enabling web..."
flutter config --enable-web
echo "Building Flutter web app..."
flutter build web --release
