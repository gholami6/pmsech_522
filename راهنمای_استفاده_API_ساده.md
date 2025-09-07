# راهنمای استفاده از API ساده (بدون vendor)

## مزایای این روش:
- **بدون نیاز به Composer**: نیازی به نصب پکیج‌های خارجی نیست
- **حجم کم**: تنها چند فایل کوچک که مصرف رم بسیار کمی دارند
- **سادگی**: آسان‌تر برای راه‌اندازی و نگهداری
- **پایداری**: احتمال کمتری برای بروز خطا

## فایل‌های ضروری:
1. `simple_xlsx_to_json.php` - اسکریپت اصلی API
2. `sample_production_data.csv` - فایل نمونه CSV
3. `test_simple_api.html` - صفحه تست API

## نحوه آماده‌سازی داده‌ها:

### گام 1: تبدیل Excel به CSV
چون این اسکریپت با فایل‌های CSV کار می‌کند، باید فایل اکسل خود را به فرمت CSV تبدیل کنید:

1. فایل Excel خود را در برنامه Excel یا LibreOffice باز کنید
2. از منوی "Save As" یا "ذخیره به نام" استفاده کنید
3. فرمت را CSV (UTF-8) انتخاب کنید
4. فایل را با نام `production_data.csv` ذخیره کنید

### گام 2: ساختار فایل CSV
فایل CSV شما باید ستون‌های زیر را داشته باشد (دقیقاً با همین نام‌ها):

```
تاریخ,تولید,هدف,راندمان,شیفت,خط,نوع_توقف,مدت_توقف,علت_توقف,تجهیز,اپراتور,وضعیت,آخرین_نگهداری
```

**نمونه ردیف‌ها:**
```
1403/01/01,850,1000,85,صبح,خط 1,,,,,,فعال,1403/01/01
1403/01/02,,,,,خط 1,مکانیکی,45,خرابی موتور,کمپرسور,احمد رضایی,خراب,1403/01/01
```

## نحوه آپلود به هاست:

### گام 1: آماده‌سازی فایل‌ها
فایل‌های زیر را در یک پوشه قرار دهید:
- `simple_xlsx_to_json.php`
- `production_data.csv` (فایل CSV شما)
- `test_simple_api.html`

### گام 2: آپلود به لیارا
1. فایل‌ها را در یک فایل ZIP قرار دهید
2. وارد پنل لیارا شوید
3. فایل ZIP را آپلود کنید
4. فایل‌ها را extract کنید

### گام 3: تست API
1. برای تست، آدرس زیر را در مرورگر باز کنید:
   ```
   https://sechah.liara.run/test_simple_api.html
   ```

2. یا مستقیماً API را تست کنید:
   ```
   https://sechah.liara.run/simple_xlsx_to_json.php
   ```

## نحوه استفاده از API:

### 1. دریافت همه داده‌ها:
```
GET: https://sechah.liara.run/simple_xlsx_to_json.php
```

### 2. فقط داده‌های تولید:
```
GET: https://sechah.liara.run/simple_xlsx_to_json.php?type=production
```

### 3. فقط داده‌های توقفات:
```
GET: https://sechah.liara.run/simple_xlsx_to_json.php?type=stops
```

### 4. فقط داده‌های تجهیزات:
```
GET: https://sechah.liara.run/simple_xlsx_to_json.php?type=equipment
```

### 5. استفاده از فایل خاص:
```
GET: https://sechah.liara.run/simple_xlsx_to_json.php?file=custom_data.csv&type=all
```

## نمونه پاسخ API:

```json
{
  "success": true,
  "data": {
    "production": [...],
    "stops": [...],
    "equipment": [...]
  },
  "timestamp": "2024-01-15 10:30:00",
  "count": 25
}
```

## استفاده در اپلیکیشن Flutter:

```dart
// در سرویس DataSyncService
Future<Map<String, dynamic>> fetchDataFromAPI() async {
  try {
    final response = await http.get(
      Uri.parse('https://sechah.liara.run/simple_xlsx_to_json.php'),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('خطا در دریافت داده‌ها: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('خطا در اتصال به سرور: $e');
  }
}
```

## عیب‌یابی مشکلات:

### اگر خطای 404 دریافت کردید:
- مطمئن شوید فایل‌ها در مسیر صحیح آپلود شده‌اند
- آدرس URL را بررسی کنید

### اگر خطای 502 دریافت کردید:
- فایل CSV شما ممکن است خیلی بزرگ باشد، آن را کوچک‌تر کنید
- ساختار فایل CSV را بررسی کنید

### اگر پاسخ خالی دریافت کردید:
- مطمئن شوید فایل CSV شما ساختار صحیح دارد
- نام ستون‌ها را بررسی کنید

### اگر داده‌ها اشتباه نمایش داده می‌شوند:
- انکودینگ فایل CSV را UTF-8 کنید
- اطمینان حاصل کنید که از کاما (,) به عنوان جداکننده استفاده کرده‌اید

## نکات مهم:
1. فایل CSV باید انکودینگ UTF-8 داشته باشد
2. نام ستون‌ها باید دقیقاً مطابق نمونه باشد
3. برای ردیف‌هایی که فقط تولید دارند، ستون‌های توقف را خالی بگذارید
4. برای ردیف‌هایی که فقط توقف دارند، ستون‌های تولید را خالی بگذارید

این روش بسیار ساده‌تر و قابل اعتمادتر از روش قبلی است و احتمال بروز خطا کمتری دارد. 