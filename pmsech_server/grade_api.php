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
    // اعتبارسنجی گروه کاری (اختیاری)
    if (isset($data['work_group']) && (!is_numeric($data['work_group']) || $data['work_group'] < 1 || $data['work_group'] > 4)) {
        return "گروه کاری باید بین 1 تا 4 باشد";
    }
    return true;
}

// تابع ایجاد فایل CSV اگر وجود نداشته باشد
function createCsvIfNotExists() {
    global $csv_file;
    
    if (!file_exists($csv_file)) {
        $headers = "روز,ماه,سال,میانگین عیار خوراک,میانگین عیار محصول,میانگین عیار باطله,گروه کاری\n";
        file_put_contents($csv_file, $headers);
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
                if ($feed !== '') {
                    $data[] = [
                        'date' => $date,
                        'grade_type' => 'خوراک',
                        'grade_value' => floatval($feed),
                    ];
                }
                if ($product !== '') {
                    $data[] = [
                        'date' => $date,
                        'grade_type' => 'محصول',
                        'grade_value' => floatval($product),
                    ];
                }
                if ($tailing !== '') {
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
    $work_group = isset($data['work_group']) ? $data['work_group'] : 1; // پیش‌فرض گروه کاری 1

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
            // اضافه کردن گروه کاری اگر وجود نداشته باشد
            if (count($fields) < 7) {
                $fields[] = $work_group;
            } else {
                $fields[6] = $work_group;
            }
            $lines[$i] = implode(',', $fields);
            $found = true;
            break;
        }
    }
    if (!$found) {
        // ردیف جدید اضافه شود
        $new_row = [$day, $month, $year, '', '', '', $work_group];
        if ($grade_type == 'خوراک') $new_row[3] = $grade_value;
        if ($grade_type == 'محصول') $new_row[4] = $grade_value;
        if ($grade_type == 'باطله') $new_row[5] = $grade_value;
        $lines[] = implode(',', $new_row);
    }
    // بازنویسی فایل
    $new_content = $header . "\n" . implode("\n", $lines) . "\n";
    if (file_put_contents($csv_file, $new_content) === false) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'error' => 'خطای سرور',
            'message' => 'خطا در ذخیره داده'
        ]);
        return;
    }
    echo json_encode([
        'success' => true,
        'message' => 'عیار با موفقیت ثبت شد',
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
        } else {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'error' => 'اکشن نامعتبر',
                'message' => 'اکشن باید upload باشد'
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