<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// تنظیمات
$csv_file = 'real_grades.csv';
$backup_dir = 'backups/';
$log_file = 'grade_api.log';

// ایجاد پوشه‌های مورد نیاز
if (!file_exists($backup_dir)) {
    mkdir($backup_dir, 0755, true);
}

// کلید API
$valid_api_key = 'pmsech_grade_api_2024';

// تابع لاگ
function writeLog($message) {
    global $log_file;
    $timestamp = date('Y-m-d H:i:s');
    $log_entry = "[$timestamp] $message\n";
    file_put_contents($log_file, $log_entry, FILE_APPEND | LOCK_EX);
}

// تابع احراز هویت
function authenticate() {
    global $valid_api_key;
    
    $headers = getallheaders();
    $api_key = isset($headers['Authorization']) ? 
        str_replace('Bearer ', '', $headers['Authorization']) : 
        (isset($_GET['api_key']) ? $_GET['api_key'] : '');
    
    if ($api_key !== $valid_api_key) {
        http_response_code(401);
        echo json_encode([
            'success' => false,
            'error' => 'احراز هویت ناموفق',
            'message' => 'کلید API نامعتبر است'
        ]);
        writeLog("احراز هویت ناموفق - API Key: $api_key");
        exit;
    }
    
    writeLog("احراز هویت موفق");
    return true;
}

// تابع اعتبارسنجی داده‌های عیار
function validateGradeData($data) {
    $required_fields = ['date', 'grade_type', 'grade_value'];
    foreach ($required_fields as $field) {
        if (!isset($data[$field]) || $data[$field] === '') {
            return "فیلد $field الزامی است";
        }
    }
    if (!preg_match('/^\d{4}\/\d{1,2}\/\d{1,2}$/', $data['date'])) {
        return "فرمت تاریخ نامعتبر است (YYYY/MM/DD)";
    }
    if (!in_array($data['grade_type'], ['خوراک', 'محصول', 'باطله'])) {
        return "نوع عیار نامعتبر است";
    }
    if (!is_numeric($data['grade_value']) || $data['grade_value'] < 0 || $data['grade_value'] > 100) {
        return "مقدار عیار باید بین 0 تا 100 باشد";
    }
    // گروه کاری حذف شد - CSV شش‌ستونه است
    return true;
}

// تابع ایجاد فایل CSV اگر وجود نداشته باشد
function createCsvIfNotExists() {
    global $csv_file;
    
    if (!file_exists($csv_file)) {
        $headers = "روز,ماه,سال,میانگین عیار خوراک,میانگین عیار محصول,میانگین عیار باطله\n";
        file_put_contents($csv_file, $headers, LOCK_EX);
        // تلاش برای تنظیم مجوز مناسب نوشتن توسط وب‌سرور
        @chmod($csv_file, 0666);
        writeLog("فایل CSV جدید ایجاد شد: $csv_file");
    }
}

// تابع دانلود فایل CSV
function downloadCsv() {
    global $csv_file;
    if (!file_exists($csv_file)) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'error' => 'فایل یافت نشد',
            'message' => 'فایل CSV وجود ندارد'
        ]);
        return;
    }
    $csv_content = file_get_contents($csv_file);
    $lines = explode("\n", trim($csv_content));
    $data = [];
    array_shift($lines); // حذف هدر
    foreach ($lines as $line) {
        if (!empty(trim($line))) {
            $fields = str_getcsv($line);
            if (count($fields) >= 6) {
                $day = trim($fields[0]);
                $month = trim($fields[1]);
                $year = trim($fields[2]);
                $feed = trim($fields[3]);
                $product = trim($fields[4]);
                $tailing = trim($fields[5]);
                $date = "$year/$month/$day";
                
                // فقط عیارهای غیرخالی را اضافه کن
                if ($feed !== '' && is_numeric($feed) && floatval($feed) > 0) {
                    $data[] = [
                        'date' => $date,
                        'grade_type' => 'خوراک',
                        'grade_value' => floatval($feed),
                    ];
                }
                if ($product !== '' && is_numeric($product) && floatval($product) > 0) {
                    $data[] = [
                        'date' => $date,
                        'grade_type' => 'محصول',
                        'grade_value' => floatval($product),
                    ];
                }
                if ($tailing !== '' && is_numeric($tailing) && floatval($tailing) > 0) {
                    $data[] = [
                        'date' => $date,
                        'grade_type' => 'باطله',
                        'grade_value' => floatval($tailing),
                    ];
                }
            }
        }
    }
    echo json_encode([
        'success' => true,
        'data' => $data,
        'count' => count($data),
    ]);
}

// تابع آپلود عیار جدید
function uploadGrade($data) {
    global $csv_file;
    createCsvIfNotExists();
    $validation = validateGradeData($data);
    if ($validation !== true) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'error' => 'داده‌های نامعتبر',
            'message' => $validation
        ]);
        return;
    }
    // استخراج تاریخ
    $date_parts = explode('/', $data['date']);
    if (count($date_parts) !== 3) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'error' => 'فرمت تاریخ نامعتبر',
            'message' => 'فرمت تاریخ باید YYYY/MM/DD باشد'
        ]);
        return;
    }
    $year = $date_parts[0];
    $month = $date_parts[1];
    $day = $date_parts[2];
    $grade_type = $data['grade_type'];
    $grade_value = $data['grade_value'];
    $equipment_id = isset($data['equipment_id']) ? $data['equipment_id'] : '';
    // گروه کاری حذف شد

    // خواندن کل فایل
    $csv_content = file_get_contents($csv_file);
    $lines = explode("\n", trim($csv_content));
    $header = array_shift($lines);
    $found = false;
    for ($i = 0; $i < count($lines); $i++) {
        $fields = str_getcsv($lines[$i]);
        if (count($fields) >= 6 &&
            trim($fields[0]) == $day &&
            trim($fields[1]) == $month &&
            trim($fields[2]) == $year) {
            // ردیف پیدا شد
            if ($grade_type == 'خوراک') $fields[3] = $grade_value;
            if ($grade_type == 'محصول') $fields[4] = $grade_value;
            if ($grade_type == 'باطله') $fields[5] = $grade_value;
            $lines[$i] = implode(',', $fields);
            $found = true;
            break;
        }
    }
    if (!$found) {
        // ردیف جدید اضافه شود
        $new_row = [$day, $month, $year, '', '', ''];
        if ($grade_type == 'خوراک') $new_row[3] = $grade_value;
        if ($grade_type == 'محصول') $new_row[4] = $grade_value;
        if ($grade_type == 'باطله') $new_row[5] = $grade_value;
        $lines[] = implode(',', $new_row);
    }
    // پیش از نوشتن، بررسی قابلیت نوشتن فایل
    if (!is_writable($csv_file)) {
        $perms = substr(sprintf('%o', fileperms($csv_file)), -4);
        $real = realpath($csv_file);
        $err  = error_get_last();
        writeLog("عدم دسترسی نوشتن روی CSV - مسیر: $real, مجوز: $perms");
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'error' => 'خطای سرور',
            'message' => 'فایل CSV قابل نوشتن نیست',
            'details' => [
                'path' => $real,
                'perms' => $perms,
            ]
        ]);
        return;
    }

    // بازنویسی فایل
    $new_content = $header . "\n" . implode("\n", $lines) . "\n";
    $result = @file_put_contents($csv_file, $new_content, LOCK_EX);
    if ($result === false) {
        $perms = substr(sprintf('%o', fileperms($csv_file)), -4);
        $real = realpath($csv_file);
        $err  = error_get_last();
        writeLog("خطا در ذخیره CSV - مسیر: $real, مجوز: $perms, خطا: " . json_encode($err));
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'error' => 'خطای سرور',
            'message' => 'خطا در ذخیره داده',
            'details' => [
                'path' => $real,
                'perms' => $perms,
                'php_error' => $err,
            ]
        ]);
        return;
    }
    echo json_encode([
        'success' => true,
        'message' => 'عیار با موفقیت ثبت شد',
    ]);
}

// تابع آپدیت عیار موجود
function updateGrade($data) {
    global $csv_file;
    
    if (!file_exists($csv_file)) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'error' => 'فایل یافت نشد',
            'message' => 'فایل CSV وجود ندارد'
        ]);
        return;
    }
    
    $validation = validateGradeData($data);
    if ($validation !== true) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'error' => 'داده‌های نامعتبر',
            'message' => $validation
        ]);
        return;
    }
    
    // استخراج تاریخ
    $date_parts = explode('/', $data['date']);
    if (count($date_parts) !== 3) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'error' => 'فرمت تاریخ نامعتبر',
            'message' => 'فرمت تاریخ باید YYYY/MM/DD باشد'
        ]);
        return;
    }
    
    $year = $date_parts[0];
    $month = $date_parts[1];
    $day = $date_parts[2];
    $grade_type = $data['grade_type'];
    $grade_value = $data['grade_value'];
    $equipment_id = isset($data['equipment_id']) ? $data['equipment_id'] : '';
    
    // خواندن کل فایل
    $csv_content = file_get_contents($csv_file);
    $lines = explode("\n", trim($csv_content));
    $header = array_shift($lines);
    $found = false;
    
    for ($i = 0; $i < count($lines); $i++) {
        $fields = str_getcsv($lines[$i]);
        if (count($fields) >= 6 &&
            trim($fields[0]) == $day &&
            trim($fields[1]) == $month &&
            trim($fields[2]) == $year) {
            // ردیف پیدا شد - آپدیت عیار
            if ($grade_type == 'خوراک') $fields[3] = $grade_value;
            if ($grade_type == 'محصول') $fields[4] = $grade_value;
            if ($grade_type == 'باطله') $fields[5] = $grade_value;
            $lines[$i] = implode(',', $fields);
            $found = true;
            break;
        }
    }
    
    if (!$found) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'error' => 'رکورد یافت نشد',
            'message' => 'عیار برای این تاریخ یافت نشد'
        ]);
        return;
    }
    
    // بررسی قابلیت نوشتن فایل
    if (!is_writable($csv_file)) {
        $perms = substr(sprintf('%o', fileperms($csv_file)), -4);
        $real = realpath($csv_file);
        writeLog("عدم دسترسی نوشتن روی CSV - مسیر: $real, مجوز: $perms");
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'error' => 'خطای سرور',
            'message' => 'فایل CSV قابل نوشتن نیست',
            'details' => [
                'path' => $real,
                'perms' => $perms,
            ]
        ]);
        return;
    }
    
    // بازنویسی فایل
    $new_content = $header . "\n" . implode("\n", $lines) . "\n";
    $result = @file_put_contents($csv_file, $new_content, LOCK_EX);
    if ($result === false) {
        $perms = substr(sprintf('%o', fileperms($csv_file)), -4);
        $real = realpath($csv_file);
        $err = error_get_last();
        writeLog("خطا در آپدیت CSV - مسیر: $real, مجوز: $perms, خطا: " . json_encode($err));
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'error' => 'خطای سرور',
            'message' => 'خطا در آپدیت داده',
            'details' => [
                'path' => $real,
                'perms' => $perms,
                'php_error' => $err,
            ]
        ]);
        return;
    }
    
    writeLog("عیار آپدیت شد: $data[date] - $data[grade_type] = $data[grade_value]");
    echo json_encode([
        'success' => true,
        'message' => 'عیار با موفقیت آپدیت شد',
    ]);
}

// تابع حذف عیار
function deleteGrade($data) {
    global $csv_file;
    
    if (!file_exists($csv_file)) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'error' => 'فایل یافت نشد',
            'message' => 'فایل CSV وجود ندارد'
        ]);
        return;
    }
    
    // بررسی فیلدهای الزامی
    $required_fields = ['date', 'grade_type', 'recorded_by'];
    foreach ($required_fields as $field) {
        if (!isset($data[$field]) || $data[$field] === '') {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'error' => 'فیلد الزامی',
                'message' => "فیلد $field الزامی است"
            ]);
            return;
        }
    }
    
    // استخراج تاریخ
    $date_parts = explode('/', $data['date']);
    if (count($date_parts) !== 3) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'error' => 'فرمت تاریخ نامعتبر',
            'message' => 'فرمت تاریخ باید YYYY/MM/DD باشد'
        ]);
        return;
    }
    
    $year = $date_parts[0];
    $month = $date_parts[1];
    $day = $date_parts[2];
    $grade_type = $data['grade_type'];
    $shift = isset($data['shift']) ? $data['shift'] : 1;
    
    // خواندن کل فایل
    $csv_content = file_get_contents($csv_file);
    $lines = explode("\n", trim($csv_content));
    $header = array_shift($lines);
    $found = false;
    
    for ($i = 0; $i < count($lines); $i++) {
        $fields = str_getcsv($lines[$i]);
        if (count($fields) >= 6 &&
            trim($fields[0]) == $day &&
            trim($fields[1]) == $month &&
            trim($fields[2]) == $year) {
            // ردیف پیدا شد - حذف عیار (تنظیم به خالی)
            if ($grade_type == 'خوراک') $fields[3] = '';
            if ($grade_type == 'محصول') $fields[4] = '';
            if ($grade_type == 'باطله') $fields[5] = '';
            $lines[$i] = implode(',', $fields);
            $found = true;
            
            // بررسی اینکه آیا تمام عیارهای این ردیف خالی شده‌اند
            $allEmpty = true;
            if (trim($fields[3]) !== '') $allEmpty = false; // خوراک
            if (trim($fields[4]) !== '') $allEmpty = false; // محصول  
            if (trim($fields[5]) !== '') $allEmpty = false; // باطله
            
            // اگر تمام عیارها خالی شدند، کل ردیف را حذف کن
            if ($allEmpty) {
                unset($lines[$i]);
                $lines = array_values($lines); // بازسازی آرایه
            }
            break;
        }
    }
    
    if (!$found) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'error' => 'رکورد یافت نشد',
            'message' => 'عیار برای این تاریخ یافت نشد'
        ]);
        return;
    }
    
    // بررسی قابلیت نوشتن فایل
    if (!is_writable($csv_file)) {
        $perms = substr(sprintf('%o', fileperms($csv_file)), -4);
        $real = realpath($csv_file);
        writeLog("عدم دسترسی نوشتن روی CSV - مسیر: $real, مجوز: $perms");
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'error' => 'خطای سرور',
            'message' => 'فایل CSV قابل نوشتن نیست',
            'details' => [
                'path' => $real,
                'perms' => $perms,
            ]
        ]);
        return;
    }
    
    // بازنویسی فایل
    $new_content = $header . "\n" . implode("\n", $lines) . "\n";
    $result = @file_put_contents($csv_file, $new_content, LOCK_EX);
    if ($result === false) {
        $perms = substr(sprintf('%o', fileperms($csv_file)), -4);
        $real = realpath($csv_file);
        $err = error_get_last();
        writeLog("خطا در حذف CSV - مسیر: $real, مجوز: $perms, خطا: " . json_encode($err));
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'error' => 'خطای سرور',
            'message' => 'خطا در حذف داده',
            'details' => [
                'path' => $real,
                'perms' => $perms,
                'php_error' => $err,
            ]
        ]);
        return;
    }
    
    writeLog("عیار حذف شد: $data[date] - $data[grade_type]");
    echo json_encode([
        'success' => true,
        'message' => 'عیار با موفقیت حذف شد',
    ]);
}

// تابع دریافت آمار
function getStats() {
    global $csv_file;
    if (!file_exists($csv_file)) {
        echo json_encode([
            'success' => true,
            'stats' => [
                'total_records' => 0,
                'by_type' => [],
                'by_date' => [],
            ]
        ]);
        return;
    }
    $csv_content = file_get_contents($csv_file);
    $lines = explode("\n", trim($csv_content));
    array_shift($lines);
    $total_records = 0;
    $by_type = ['خوراک' => 0, 'محصول' => 0, 'باطله' => 0];
    $by_date = [];
    foreach ($lines as $line) {
        if (!empty(trim($line))) {
            $fields = str_getcsv($line);
            if (count($fields) >= 6) {
                $day = trim($fields[0]);
                $month = trim($fields[1]);
                $year = trim($fields[2]);
                $date = "$year/$month/$day";
                if (trim($fields[3]) !== '') { $by_type['خوراک']++; $total_records++; }
                if (trim($fields[4]) !== '') { $by_type['محصول']++; $total_records++; }
                if (trim($fields[5]) !== '') { $by_type['باطله']++; $total_records++; }
                if (!isset($by_date[$date])) $by_date[$date] = 0;
                if (trim($fields[3]) !== '') $by_date[$date]++;
                if (trim($fields[4]) !== '') $by_date[$date]++;
                if (trim($fields[5]) !== '') $by_date[$date]++;
            }
        }
    }
    echo json_encode([
        'success' => true,
        'stats' => [
            'total_records' => $total_records,
            'by_type' => $by_type,
            'by_date' => $by_date,
        ]
    ]);
}

// پردازش درخواست
$method = $_SERVER['REQUEST_METHOD'];
$action = $_GET['action'] ?? '';

writeLog("درخواست جدید - متد: $method, اکشن: $action");

// احراز هویت برای تمام درخواست‌ها
authenticate();

switch ($method) {
    case 'GET':
        switch ($action) {
            case 'download':
                downloadCsv();
                break;
            case 'stats':
                getStats();
                break;
            default:
                http_response_code(400);
                echo json_encode([
                    'success' => false,
                    'error' => 'اکشن نامعتبر',
                    'message' => 'اکشن باید download یا stats باشد'
                ]);
        }
        break;
        
    case 'POST':
        if ($action === 'upload') {
            $input = json_decode(file_get_contents('php://input'), true);
            if ($input === null) {
                http_response_code(400);
                echo json_encode([
                    'success' => false,
                    'error' => 'داده‌های نامعتبر',
                    'message' => 'JSON نامعتبر'
                ]);
            } else {
                uploadGrade($input);
            }
        } elseif ($action === 'update') {
            $input = json_decode(file_get_contents('php://input'), true);
            if ($input === null) {
                http_response_code(400);
                echo json_encode([
                    'success' => false,
                    'error' => 'داده‌های نامعتبر',
                    'message' => 'JSON نامعتبر'
                ]);
            } else {
                updateGrade($input);
            }
        } elseif ($action === 'delete') {
            $input = json_decode(file_get_contents('php://input'), true);
            if ($input === null) {
                http_response_code(400);
                echo json_encode([
                    'success' => false,
                    'error' => 'داده‌های نامعتبر',
                    'message' => 'JSON نامعتبر'
                ]);
            } else {
                deleteGrade($input);
            }
        } else {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'error' => 'اکشن نامعتبر',
                'message' => 'اکشن باید upload، update یا delete باشد'
            ]);
        }
        break;
        
    default:
        http_response_code(405);
        echo json_encode([
            'success' => false,
            'error' => 'متد نامعتبر',
            'message' => 'فقط GET و POST پشتیبانی می‌شود'
        ]);
}

writeLog("پاسخ ارسال شد");
?> 