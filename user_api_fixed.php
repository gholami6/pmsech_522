<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST');
header('Access-Control-Allow-Headers: Content-Type');

$users_file = 'users.csv';
$api_key = 'pmsech_user_api_2024';

// بررسی کلید API
if (!isset($_GET['api_key']) || $_GET['api_key'] !== $api_key) {
    echo json_encode(['success' => false, 'message' => 'کلید API نامعتبر است']);
    exit;
}

// ایجاد فایل CSV
if (!file_exists($users_file)) {
    file_put_contents($users_file, "id,username,password,email,fullName,mobile,position,created_at\n");
}

$action = $_GET['action'] ?? '';

switch ($action) {
    case 'list':
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
                    'position' => $data[6]
                ];
            }
        }
        
        echo json_encode([
            'success' => true,
            'users' => $users,
            'count' => count($users)
        ]);
        break;
        
    case 'register':
        $input = json_decode(file_get_contents('php://input'), true);
        
        if (!$input) {
            echo json_encode(['success' => false, 'message' => 'داده‌های نامعتبر']);
            exit;
        }
        
        // بررسی تکراری نبودن
        $lines = file($users_file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
        for ($i = 1; $i < count($lines); $i++) {
            $data = str_getcsv($lines[$i]);
            if ($data[1] === $input['username']) {
                echo json_encode(['success' => false, 'message' => 'نام کاربری تکراری است']);
                exit;
            }
        }
        
        // ثبت کاربر
        $user_id = uniqid();
        $line = "\"$user_id\",\"{$input['username']}\",\"{$input['password']}\",\"{$input['email']}\",\"{$input['fullName']}\",\"{$input['mobile']}\",\"{$input['position']}\",\"" . date('Y-m-d H:i:s') . "\"\n";
        file_put_contents($users_file, $line, FILE_APPEND);
        
        echo json_encode(['success' => true, 'message' => 'کاربر ثبت شد', 'user_id' => $user_id]);
        break;
        
    case 'delete':
        $input = json_decode(file_get_contents('php://input'), true);
        $user_id = $input['user_id'] ?? '';
        
        $lines = file($users_file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
        $new_lines = [$lines[0]]; // header
        
        for ($i = 1; $i < count($lines); $i++) {
            $data = str_getcsv($lines[$i]);
            if ($data[0] !== $user_id) {
                $new_lines[] = $lines[$i];
            }
        }
        
        file_put_contents($users_file, implode("\n", $new_lines) . "\n");
        echo json_encode(['success' => true, 'message' => 'کاربر حذف شد']);
        break;
        
    default:
        echo json_encode(['success' => false, 'message' => 'اکشن نامعتبر']);
        break;
}
?> 