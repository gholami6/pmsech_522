<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// تنظیمات
$users_file = 'users.csv';
$log_file = 'user_api.log';

// کلید API
$valid_api_key = 'pmsech_user_api_2024';

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

// تابع ایجاد فایل CSV اگر وجود نداشته باشد
function createUsersFileIfNotExists() {
    global $users_file;
    
    if (!file_exists($users_file)) {
        $header = "id,username,password,email,fullName,mobile,position,created_at,updated_at\n";
        file_put_contents($users_file, $header);
        writeLog("فایل کاربران ایجاد شد: $users_file");
    }
}

// تابع اعتبارسنجی داده‌های کاربر
function validateUserData($data) {
    $required_fields = ['username', 'password', 'email', 'fullName', 'mobile', 'position'];
    
    foreach ($required_fields as $field) {
        if (!isset($data[$field]) || empty(trim($data[$field]))) {
            return "فیلد $field الزامی است";
        }
    }
    
    // اعتبارسنجی نام کاربری
    if (strlen($data['username']) < 3) {
        return "نام کاربری باید حداقل 3 کاراکتر باشد";
    }
    
    // اعتبارسنجی رمز عبور
    if (strlen($data['password']) < 4) {
        return "رمز عبور باید حداقل 4 کاراکتر باشد";
    }
    
    // اعتبارسنجی ایمیل
    if (!filter_var($data['email'], FILTER_VALIDATE_EMAIL)) {
        return "ایمیل نامعتبر است";
    }
    
    // اعتبارسنجی موبایل
    if (!preg_match('/^09[0-9]{9}$/', $data['mobile'])) {
        return "شماره موبایل نامعتبر است";
    }
    
    return true;
}

// تابع ثبت کاربر جدید
function registerUser($data) {
    global $users_file;
    createUsersFileIfNotExists();
    
    $validation = validateUserData($data);
    if ($validation !== true) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'error' => 'داده‌های نامعتبر',
            'message' => $validation
        ]);
        return;
    }
    
    // بررسی تکراری نبودن
    $users = getAllUsers();
    foreach ($users as $user) {
        if ($user['username'] === $data['username']) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'error' => 'نام کاربری تکراری',
                'message' => 'این نام کاربری قبلاً استفاده شده است'
            ]);
            return;
        }
        
        if ($user['email'] === $data['email']) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'error' => 'ایمیل تکراری',
                'message' => 'این ایمیل قبلاً استفاده شده است'
            ]);
            return;
        }
        
        if ($user['mobile'] === $data['mobile']) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'error' => 'موبایل تکراری',
                'message' => 'این شماره موبایل قبلاً استفاده شده است'
            ]);
            return;
        }
    }
    
    // ایجاد کاربر جدید
    $user_id = uniqid('user_');
    $hashed_password = hash('sha256', $data['password']);
    $created_at = date('Y-m-d H:i:s');
    
    $new_user = [
        $user_id,
        $data['username'],
        $hashed_password,
        $data['email'],
        $data['fullName'],
        $data['mobile'],
        $data['position'],
        $created_at,
        $created_at
    ];
    
    // اضافه کردن به فایل CSV
    $csv_line = implode(',', array_map(function($field) {
        return '"' . str_replace('"', '""', $field) . '"';
    }, $new_user)) . "\n";
    
    if (file_put_contents($users_file, $csv_line, FILE_APPEND | LOCK_EX) === false) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'error' => 'خطای سرور',
            'message' => 'خطا در ذخیره کاربر'
        ]);
        return;
    }
    
    writeLog("کاربر جدید ثبت شد: {$data['username']}");
    
    echo json_encode([
        'success' => true,
        'message' => 'کاربر با موفقیت ثبت شد',
        'user_id' => $user_id
    ]);
}

// تابع ورود کاربر
function loginUser($data) {
    $users = getAllUsers();
    
    $username = $data['username'] ?? '';
    $password = $data['password'] ?? '';
    $hashed_password = hash('sha256', $password);
    
    foreach ($users as $user) {
        if ($user['username'] === $username && $user['password'] === $hashed_password) {
            writeLog("ورود موفق: $username");
            echo json_encode([
                'success' => true,
                'message' => 'ورود موفق',
                'user' => [
                    'id' => $user['id'],
                    'username' => $user['username'],
                    'email' => $user['email'],
                    'fullName' => $user['fullName'],
                    'mobile' => $user['mobile'],
                    'position' => $user['position']
                ]
            ]);
            return;
        }
    }
    
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'error' => 'احراز هویت ناموفق',
        'message' => 'نام کاربری یا رمز عبور اشتباه است'
    ]);
}

// تابع دریافت همه کاربران
function getAllUsers() {
    global $users_file;
    createUsersFileIfNotExists();
    
    $users = [];
    $lines = file($users_file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    
    if (count($lines) <= 1) {
        return $users;
    }
    
    $headers = str_getcsv(array_shift($lines));
    
    foreach ($lines as $line) {
        $fields = str_getcsv($line);
        if (count($fields) >= count($headers)) {
            $user = array_combine($headers, $fields);
            $users[] = $user;
        }
    }
    
    return $users;
}

// تابع دریافت لیست کاربران
function getUsersList() {
    $users = getAllUsers();
    
    echo json_encode([
        'success' => true,
        'message' => 'لیست کاربران دریافت شد',
        'users' => $users,
        'count' => count($users)
    ]);
}

// تابع به‌روزرسانی کاربر
function updateUser($data) {
    global $users_file;
    
    if (!isset($data['user_id'])) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'error' => 'شناسه کاربر الزامی است',
            'message' => 'فیلد user_id الزامی است'
        ]);
        return;
    }
    
    $users = getAllUsers();
    $user_found = false;
    $updated_users = [];
    
    foreach ($users as $user) {
        if ($user['id'] === $data['user_id']) {
            $user_found = true;
            $user['email'] = $data['email'] ?? $user['email'];
            $user['fullName'] = $data['fullName'] ?? $user['fullName'];
            $user['mobile'] = $data['mobile'] ?? $user['mobile'];
            $user['position'] = $data['position'] ?? $user['position'];
            $user['updated_at'] = date('Y-m-d H:i:s');
        }
        $updated_users[] = $user;
    }
    
    if (!$user_found) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'error' => 'کاربر یافت نشد',
            'message' => 'کاربر با این شناسه یافت نشد'
        ]);
        return;
    }
    
    // بازنویسی فایل
    $header = "id,username,password,email,fullName,mobile,position,created_at,updated_at\n";
    $content = $header;
    
    foreach ($updated_users as $user) {
        $csv_line = implode(',', array_map(function($field) {
            return '"' . str_replace('"', '""', $field) . '"';
        }, $user)) . "\n";
        $content .= $csv_line;
    }
    
    if (file_put_contents($users_file, $content) === false) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'error' => 'خطای سرور',
            'message' => 'خطا در به‌روزرسانی کاربر'
        ]);
        return;
    }
    
    writeLog("کاربر به‌روزرسانی شد: {$data['user_id']}");
    
    echo json_encode([
        'success' => true,
        'message' => 'کاربر با موفقیت به‌روزرسانی شد'
    ]);
}

// تابع حذف کاربر
function deleteUser($user_id) {
    global $users_file;
    
    $users = getAllUsers();
    $user_found = false;
    $updated_users = [];
    
    foreach ($users as $user) {
        if ($user['id'] !== $user_id) {
            $updated_users[] = $user;
        } else {
            $user_found = true;
        }
    }
    
    if (!$user_found) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'error' => 'کاربر یافت نشد',
            'message' => 'کاربر با این شناسه یافت نشد'
        ]);
        return;
    }
    
    // بازنویسی فایل
    $header = "id,username,password,email,fullName,mobile,position,created_at,updated_at\n";
    $content = $header;
    
    foreach ($updated_users as $user) {
        $csv_line = implode(',', array_map(function($field) {
            return '"' . str_replace('"', '""', $field) . '"';
        }, $user)) . "\n";
        $content .= $csv_line;
    }
    
    if (file_put_contents($users_file, $content) === false) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'error' => 'خطای سرور',
            'message' => 'خطا در حذف کاربر'
        ]);
        return;
    }
    
    writeLog("کاربر حذف شد: $user_id");
    
    echo json_encode([
        'success' => true,
        'message' => 'کاربر با موفقیت حذف شد'
    ]);
}

// پردازش درخواست
$method = $_SERVER['REQUEST_METHOD'];
$action = $_GET['action'] ?? '';

// احراز هویت
authenticate();

writeLog("درخواست $method برای اکشن $action");

switch ($method) {
    case 'GET':
        switch ($action) {
            case 'list':
                getUsersList();
                break;
            default:
                http_response_code(400);
                echo json_encode([
                    'success' => false,
                    'error' => 'اکشن نامعتبر',
                    'message' => 'اکشن باید list باشد'
                ]);
        }
        break;
        
    case 'POST':
        $input = json_decode(file_get_contents('php://input'), true);
        
        if ($input === null) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'error' => 'داده‌های نامعتبر',
                'message' => 'JSON نامعتبر'
            ]);
            break;
        }
        
        switch ($action) {
            case 'register':
                registerUser($input);
                break;
            case 'login':
                loginUser($input);
                break;
            case 'update':
                updateUser($input);
                break;
            case 'delete':
                deleteUser($input['user_id'] ?? '');
                break;
            default:
                http_response_code(400);
                echo json_encode([
                    'success' => false,
                    'error' => 'اکشن نامعتبر',
                    'message' => 'اکشن باید register، login، update یا delete باشد'
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