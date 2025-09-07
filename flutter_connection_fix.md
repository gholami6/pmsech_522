# راهنمای حل مشکل اتصال Flutter

## 🔧 مشکلات شناسایی شده:

### 1. خطای ADB
```
adb.exe: error: more than one device/emulator
```

### 2. خطای WebSocket
```
WebSocketException: Connection was not upgraded to websocket
```

## 🛠️ راه‌حل‌ها:

### مرحله 1: حل مشکل ADB
```bash
# 1. متوقف کردن سرور ADB
adb kill-server

# 2. راه‌اندازی مجدد
adb start-server

# 3. بررسی دستگاه‌ها
adb devices

# 4. انتخاب دستگاه خاص (اگر چندین دستگاه متصل است)
flutter run -d [DEVICE_ID]
```

### مرحله 2: تنظیمات Flutter
```bash
# پاک کردن کش Flutter
flutter clean

# دریافت مجدد dependencies
flutter pub get

# راه‌اندازی مجدد
flutter run
```

### مرحله 3: تنظیمات پروژه
```bash
# بررسی وضعیت Flutter
flutter doctor

# به‌روزرسانی Flutter
flutter upgrade

# بررسی دستگاه‌های متصل
flutter devices
```

## 📱 تنظیمات دستگاه:

### Android:
1. **Developer Options** را فعال کنید
2. **USB Debugging** را فعال کنید
3. **USB Debugging (Security Settings)** را فعال کنید
4. فقط یک دستگاه را متصل کنید

### iOS:
1. **Developer Mode** را فعال کنید
2. **Trust** را برای کامپیوتر انتخاب کنید

## 🔍 عیب‌یابی:

### اگر مشکل ادامه دارد:
1. تمام دستگاه‌های USB را جدا کنید
2. کامپیوتر را restart کنید
3. فقط یک دستگاه را متصل کنید
4. USB Debugging را غیرفعال و مجدداً فعال کنید

### دستورات مفید:
```bash
# بررسی وضعیت کامل
flutter doctor -v

# پاک کردن کامل
flutter clean && flutter pub get

# راه‌اندازی با verbose
flutter run -v

# راه‌اندازی روی دستگاه خاص
flutter run -d [DEVICE_ID]
```

## 📞 پشتیبانی:
اگر مشکل حل نشد، این اطلاعات را ارائه دهید:
- خروجی `flutter doctor -v`
- خروجی `adb devices`
- نسخه Flutter: `flutter --version`
- نوع دستگاه و نسخه Android/iOS
