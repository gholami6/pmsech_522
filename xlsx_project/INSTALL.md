# راهنمای نصب و راه‌اندازی سرور

## پیش‌نیازها

### 1. سرور وب
- Apache یا Nginx
- PHP نسخه 7.4 یا بالاتر
- Composer

### 2. Extension های PHP
```bash
# Ubuntu/Debian
sudo apt-get install php-zip php-xml php-mbstring

# CentOS/RHEL
sudo yum install php-zip php-xml php-mbstring

# Windows (XAMPP/WAMP)
# Extension ها معمولاً فعال هستند
```

## مراحل نصب

### 1. آپلود فایل‌ها
تمام فایل‌های موجود در پوشه `xlsx_project` را در هاست آپلود کنید:

```
xlsx_project/
├── xlsx_to_json.php      # فایل اصلی API
├── composer.json         # تنظیمات Composer
├── composer.lock         # قفل نسخه‌ها
├── .htaccess            # تنظیمات Apache
├── php.ini              # تنظیمات PHP
├── sample_data.json     # داده نمونه
├── test_api.html        # صفحه تست
├── README.md            # راهنما
└── INSTALL.md           # این فایل
```

### 2. نصب Composer Dependencies
در پوشه پروژه در هاست، دستور زیر را اجرا کنید:

```bash
composer install --no-dev --optimize-autoloader
```

### 3. تنظیم مجوزها
```bash
# تنظیم مجوزهای فایل
chmod 644 *.php *.json *.html *.md
chmod 644 .htaccess php.ini

# تنظیم مجوزهای پوشه
chmod 755 .
```

### 4. تست نصب
1. فایل `test_api.html` را در مرورگر باز کنید
2. فایل اکسل نمونه را آپلود کنید
3. نتیجه را بررسی کنید

## تنظیمات سرور

### Apache
اگر از Apache استفاده می‌کنید، فایل `.htaccess` به طور خودکار تنظیمات لازم را اعمال می‌کند.

### Nginx
اگر از Nginx استفاده می‌کنید، تنظیمات زیر را به فایل کانفیگ اضافه کنید:

```nginx
server {
    listen 80;
    server_name your-domain.com;
    root /path/to/xlsx_project;
    index xlsx_to_json.php;

    # CORS headers
    add_header Access-Control-Allow-Origin "*" always;
    add_header Access-Control-Allow-Methods "GET, POST, OPTIONS" always;
    add_header Access-Control-Allow-Headers "Content-Type, Authorization" always;

    # Handle preflight requests
    if ($request_method = 'OPTIONS') {
        add_header Access-Control-Allow-Origin "*";
        add_header Access-Control-Allow-Methods "GET, POST, OPTIONS";
        add_header Access-Control-Allow-Headers "Content-Type, Authorization";
        add_header Content-Length 0;
        add_header Content-Type text/plain;
        return 200;
    }

    # PHP processing
    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
        
        # Increase limits for large files
        fastcgi_read_timeout 300;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
    }

    # File upload limits
    client_max_body_size 50M;
}
```

### تنظیمات PHP
اگر فایل `php.ini` کار نمی‌کند، تنظیمات زیر را در فایل `php.ini` اصلی سرور اضافه کنید:

```ini
memory_limit = 512M
max_execution_time = 300
upload_max_filesize = 50M
post_max_size = 50M
```

## تست API

### 1. تست با cURL
```bash
# آپلود فایل
curl -X POST -F "excel_file=@your_file.xlsx" http://your-domain.com/xlsx_to_json.php

# استفاده از فایل موجود
curl "http://your-domain.com/xlsx_to_json.php?file=production_data.xlsx"
```

### 2. تست با JavaScript
```javascript
// آپلود فایل
const formData = new FormData();
formData.append('excel_file', fileInput.files[0]);

fetch('http://your-domain.com/xlsx_to_json.php', {
    method: 'POST',
    body: formData
})
.then(response => response.json())
.then(data => console.log(data));

// استفاده از فایل موجود
fetch('http://your-domain.com/xlsx_to_json.php?file=production_data.xlsx')
.then(response => response.json())
.then(data => console.log(data));
```

## عیب‌یابی

### خطاهای رایج

1. **خطای حافظه**
   - `memory_limit` را افزایش دهید
   - فایل‌های بزرگ را به قطعات کوچک‌تر تقسیم کنید

2. **خطای آپلود**
   - `upload_max_filesize` و `post_max_size` را بررسی کنید
   - مجوزهای فایل را بررسی کنید

3. **خطای CORS**
   - تنظیمات `.htaccess` را بررسی کنید
   - در Nginx، header های CORS را اضافه کنید

4. **خطای Composer**
   - `composer install` را دوباره اجرا کنید
   - نسخه PHP را بررسی کنید

### لاگ‌ها
خطاهای PHP در فایل `php_errors.log` ذخیره می‌شوند.

## امنیت

### توصیه‌های امنیتی
1. در محیط تولید، `display_errors` را غیرفعال کنید
2. فایل‌های حساس را در پوشه‌های عمومی قرار ندهید
3. از HTTPS استفاده کنید
4. محدودیت‌های آپلود را تنظیم کنید

### فایروال
اگر از فایروال استفاده می‌کنید، پورت 80 و 443 را باز کنید.

## پشتیبانی

در صورت بروز مشکل:
1. لاگ‌های خطا را بررسی کنید
2. تنظیمات سرور را بررسی کنید
3. فایل `test_api.html` را برای تست استفاده کنید 