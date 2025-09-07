<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// تنظیمات
$users_file = 'users.csv';
$valid_api_key = 'pmsech_user_api_2024';

// دریافت درخواست
$action = $_GET['action'] ?? '';
$api_key = $_GET['api_key'] ?? '';

// بررسی کلید API
if ($api_key !== $valid_api_key) {
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'error' => 'احراز هویت ناموفق',
        'message' => 'کلید API نامعتبر است'
    ]);
    exit;
}

// ایجاد فایل CSV اگر وجود نداشته باشد
if (!file_exists($users_file)) {
    $header = "id,username,password,email,fullName,mobile,position,created_at,updated_at\n";
    file_put_contents($users_file, $header);
}

// پردازش درخواست‌ها
switch ($action) {
    case 'list':
        getAllUsers();
        break;
    case 'register':
        registerUser();
        break;
    case 'login':
        loginUser();
        break;
    case 'update':
        updateUser();
        break;
    case 'delete':
        deleteUser();
        break;
    default:
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'error' => 'اکشن نامعتبر',
            'message' => 'اکشن باید list، register، login، update یا delete باشد'
        ]);
        break;
}

// تابع دریافت همه کاربران
function getAllUsers() {
    global $users_file;
    
    if (!file_exists($users_file)) {
        echo json_encode([
            'success' => true,
            'message' => 'هیچ کاربری یافت نشد',
            'users' => [],
            'count' => 0
        ]);
        return;
    }
    
    $lines = file($users_file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    $users = [];
    
    for ($i = 1; $i < count($lines); $i++) {
        $data = str_getcsv($lines[$i]);
        if (count($data) >= 7) {
            $users[] = [
                'id' => $data[0],
                'username' => $data[1],
                'password' => $data[2],
                'email' => $data[3],
                'fullName' => $data[4],
                'mobile' => $data[5],
                'position' => $data[6],
                'created_at' => $data[7] ?? '',
                'updated_at' => $data[8] ?? ''
            ];
        }
    }
    
    echo json_encode([
        'success' => true,
        'message' => 'کاربران با موفقیت دریافت شدند',
        'users' => $users,
        'count' => count($users)
    ]);
}

// تابع ثبت کاربر
function registerUser() {
    global $users_file;
    
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'error' => 'داده‌های نامعتبر',
            'message' => 'داده‌های JSON ارسال نشده'
        ]);
        return;
    }
    
    // بررسی فیلدهای الزامی
    $required = ['username', 'password', 'email', 'fullName', 'mobile', 'position'];
    foreach ($required as $field) {
        if (empty($input[$field])) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'error' => 'فیلد الزامی',
                'message' => "فیلد $field الزامی است"
            ]);
            return;
        }
    }
    
    // بررسی تکراری نبودن نام کاربری
    if (file_exists($users_file)) {
        $lines = file($users_file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
        for ($i = 1; $i < count($lines); $i++) {
            $data = str_getcsv($lines[$i]);
            if ($data[1] === $input['username']) {
                http_response_code(400);
                echo json_encode([
                    'success' => false,
                    'error' => 'نام کاربری تکراری',
                    'message' => 'این نام کاربری قبلاً استفاده شده است'
                ]);
                return;
            }
        }
    }
    
    // ایجاد شناسه منحصر
    $user_id = uniqid();
    $created_at = date('Y-m-d H:i:s');
    
    // ذخیره در فایل CSV
    $user_data = [
        $user_id,
        $input['username'],
        $input['password'],
        $input['email'],
        $input['fullName'],
        $input['mobile'],
        $input['position'],
        $created_at,
        $created_at
    ];
    
    $line = '"' . implode('","', $user_data) . '"' . "\n";
    file_put_contents($users_file, $line, FILE_APPEND | LOCK_EX);
    
    echo json_encode([
        'success' => true,
        'message' => 'کاربر با موفقیت ثبت شد',
        'user_id' => $user_id
    ]);
}

// تابع ورود کاربر
function loginUser() {
    global $users_file;
    
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input || empty($input['username']) || empty($input['password'])) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'error' => 'داده‌های نامعتبر',
            'message' => 'نام کاربری و رمز عبور الزامی است'
        ]);
        return;
    }
    
    if (!file_exists($users_file)) {
        http_response_code(401);
        echo json_encode([
            'success' => false,
            'error' => 'احراز هویت ناموفق',
            'message' => 'نام کاربری یا رمز عبور اشتباه است'
        ]);
        return;
    }
    
    $lines = file($users_file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    
    for ($i = 1; $i < count($lines); $i++) {
        $data = str_getcsv($lines[$i]);
        if (count($data) >= 3 && 
            $data[1] === $input['username'] && 
            $data[2] === $input['password']) {
            
            echo json_encode([
                'success' => true,
                'message' => 'ورود موفقیت‌آمیز',
                'user' => [
                    'id' => $data[0],
                    'username' => $data[1],
                    'email' => $data[3],
                    'fullName' => $data[4],
                    'mobile' => $data[5],
                    'position' => $data[6]
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

// تابع به‌روزرسانی کاربر
function updateUser() {
    global $users_file;
    
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input || empty($input['user_id'])) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'error' => 'شناسه کاربر الزامی است',
            'message' => 'شناسه کاربر ارسال نشده'
        ]);
        return;
    }
    
    if (!file_exists($users_file)) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'error' => 'کاربر یافت نشد',
            'message' => 'کاربر مورد نظر یافت نشد'
        ]);
        return;
    }
    
    $lines = file($users_file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    $updated = false;
    
    for ($i = 1; $i < count($lines); $i++) {
        $data = str_getcsv($lines[$i]);
        if ($data[0] === $input['user_id']) {
            // به‌روزرسانی فیلدها
            if (!empty($input['email'])) $data[3] = $input['email'];
            if (!empty($input['fullName'])) $data[4] = $input['fullName'];
            if (!empty($input['mobile'])) $data[5] = $input['mobile'];
            if (!empty($input['position'])) $data[6] = $input['position'];
            $data[8] = date('Y-m-d H:i:s'); // updated_at
            
            $lines[$i] = '"' . implode('","', $data) . '"';
            $updated = true;
            break;
        }
    }
    
    if ($updated) {
        file_put_contents($users_file, implode("\n", $lines) . "\n");
        echo json_encode([
            'success' => true,
            'message' => 'کاربر با موفقیت به‌روزرسانی شد'
        ]);
    } else {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'error' => 'کاربر یافت نشد',
            'message' => 'کاربر مورد نظر یافت نشد'
        ]);
    }
}

// تابع حذف کاربر
function deleteUser() {
    global $users_file;
    
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input || empty($input['user_id'])) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'error' => 'شناسه کاربر الزامی است',
            'message' => 'شناسه کاربر ارسال نشده'
        ]);
        return;
    }
    
    if (!file_exists($users_file)) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'error' => 'کاربر یافت نشد',
            'message' => 'کاربر مورد نظر یافت نشد'
        ]);
        return;
    }
    
    $lines = file($users_file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    $deleted = false;
    
    for ($i = 1; $i < count($lines); $i++) {
        $data = str_getcsv($lines[$i]);
        if ($data[0] === $input['user_id']) {
            unset($lines[$i]);
            $deleted = true;
            break;
        }
    }
    
    if ($deleted) {
        file_put_contents($users_file, implode("\n", $lines) . "\n");
        echo json_encode([
            'success' => true,
            'message' => 'کاربر با موفقیت حذف شد'
        ]);
    } else {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'error' => 'کاربر یافت نشد',
            'message' => 'کاربر مورد نظر یافت نشد'
        ]);
    }
}
?> 