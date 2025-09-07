@echo off
echo === حل مشکل ADB ===

echo 1. متوقف کردن ADB server...
adb kill-server

echo 2. شروع مجدد ADB server...
adb start-server

echo 3. لیست دستگاه‌های متصل:
adb devices

echo 4. پاک کردن کش Flutter...
flutter clean

echo 5. دریافت dependencies:
flutter pub get

echo === پایان ===
pause
