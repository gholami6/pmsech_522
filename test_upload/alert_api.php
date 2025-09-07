<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// تنظیمات دیتابیس
$dbFile = 'alerts_database.json';

// ایجاد فایل دیتابیس اگر وجود ندارد
if (!file_exists($dbFile)) {
    file_put_contents($dbFile, json_encode([
        'alerts' => [],
        'users' => []
    ]));
}

// خواندن دیتابیس
function loadDatabase() {
    global $dbFile;
    $content = file_get_contents($dbFile);
    return json_decode($content, true) ?: ['alerts' => [], 'users' => []];
}

// ذخیره دیتابیس
function saveDatabase($data) {
    global $dbFile;
    file_put_contents($dbFile, json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));
}

// دریافت داده‌های ورودی
$input = json_decode(file_get_contents('php://input'), true);
$action = $input['action'] ?? '';

switch ($action) {
    case 'create_alert':
        $userId = $input['user_id'] ?? '';
        $equipmentId = $input['equipment_id'] ?? '';
        $message = $input['message'] ?? '';
        
        if (empty($userId) || empty($equipmentId) || empty($message)) {
            echo json_encode(['success' => false, 'message' => 'اطلاعات ناقص است']);
            break;
        }
        
        $db = loadDatabase();
        
        $alert = [
            'id' => uniqid(),
            'user_id' => $userId,
            'equipment_id' => $equipmentId,
            'message' => $message,
            'created_at' => date('Y-m-d H:i:s'),
            'replies' => [],
            'seen_by' => []
        ];
        
        $db['alerts'][] = $alert;
        saveDatabase($db);
        
        echo json_encode(['success' => true, 'alert_id' => $alert['id']]);
        break;
        
    case 'get_alerts':
        $db = loadDatabase();
        $alerts = $db['alerts'] ?? [];
        
        // مرتب‌سازی بر اساس تاریخ (جدیدترین اول)
        usort($alerts, function($a, $b) {
            return strtotime($b['created_at']) - strtotime($a['created_at']);
        });
        
        echo json_encode(['success' => true, 'alerts' => $alerts]);
        break;
        
    case 'add_reply':
        $alertId = $input['alert_id'] ?? '';
        $userId = $input['user_id'] ?? '';
        $message = $input['message'] ?? '';
        
        if (empty($alertId) || empty($userId) || empty($message)) {
            echo json_encode(['success' => false, 'message' => 'اطلاعات ناقص است']);
            break;
        }
        
        $db = loadDatabase();
        
        foreach ($db['alerts'] as &$alert) {
            if ($alert['id'] === $alertId) {
                $reply = [
                    'id' => uniqid(),
                    'user_id' => $userId,
                    'message' => $message,
                    'created_at' => date('Y-m-d H:i:s')
                ];
                $alert['replies'][] = $reply;
                break;
            }
        }
        
        saveDatabase($db);
        echo json_encode(['success' => true]);
        break;
        
    case 'mark_as_seen':
        $alertId = $input['alert_id'] ?? '';
        $userId = $input['user_id'] ?? '';
        
        if (empty($alertId) || empty($userId)) {
            echo json_encode(['success' => false, 'message' => 'اطلاعات ناقص است']);
            break;
        }
        
        $db = loadDatabase();
        
        foreach ($db['alerts'] as &$alert) {
            if ($alert['id'] === $alertId) {
                $alert['seen_by'][$userId] = [
                    'seen' => true,
                    'seen_at' => date('Y-m-d H:i:s')
                ];
                break;
            }
        }
        
        saveDatabase($db);
        echo json_encode(['success' => true]);
        break;
        
    case 'get_unseen_count':
        $userId = $input['user_id'] ?? '';
        
        if (empty($userId)) {
            echo json_encode(['success' => false, 'message' => 'شناسه کاربر نیاز است']);
            break;
        }
        
        $db = loadDatabase();
        $unseenCount = 0;
        
        foreach ($db['alerts'] as $alert) {
            if (!isset($alert['seen_by'][$userId]) || !$alert['seen_by'][$userId]['seen']) {
                $unseenCount++;
            }
        }
        
        echo json_encode(['success' => true, 'count' => $unseenCount]);
        break;
        
    default:
        echo json_encode(['success' => false, 'message' => 'عملیات نامعتبر است']);
        break;
}
?> 