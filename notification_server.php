<?php

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// استفاده از فایل‌های موقت
$tempDir = sys_get_temp_dir();
$databaseFile = $tempDir . '/notification_database.json';

// ذخیره دیتابیس در فایل موقت
function saveDatabase($data) {
    global $databaseFile;
    $result = file_put_contents($databaseFile, json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));
    error_log("Notification database saved to temp file: " . $databaseFile . " - Result: " . ($result ? "SUCCESS" : "FAILED"));
    return $result !== false;
}

// خواندن دیتابیس از فایل موقت
function loadDatabase() {
    global $databaseFile;
    if (file_exists($databaseFile)) {
        $content = file_get_contents($databaseFile);
        $data = json_decode($content, true);
        if ($data === null) {
            error_log("Failed to decode JSON from: " . $databaseFile);
            $data = ['notifications' => [], 'users' => []];
        }
    } else {
        error_log("Notification database file not found: " . $databaseFile);
        $data = ['notifications' => [], 'users' => []];
    }
    error_log("Notification database loaded from temp file: " . $databaseFile . " - Notifications count: " . count($data['notifications']));
    return $data;
}

// دریافت داده‌های ورودی
$input = json_decode(file_get_contents('php://input'), true);
$action = $input['action'] ?? '';

switch ($action) {
    case 'send_notification_to_all':
        error_log("Sending notification to all users with input: " . json_encode($input));
        
        $title = $input['title'] ?? '';
        $message = $input['message'] ?? '';
        $type = $input['type'] ?? '';
        $data = $input['data'] ?? [];
        
        if (empty($title) || empty($message)) {
            error_log("Missing required fields");
            echo json_encode(['success' => false, 'message' => 'عنوان و پیام الزامی است']);
            break;
        }
        
        $db = loadDatabase();
        error_log("Database before adding notification: " . json_encode($db));
        
        $notificationId = uniqid();
        $notification = [
            'id' => $notificationId,
            'title' => $title,
            'message' => $message,
            'type' => $type,
            'data' => $data,
            'created_at' => date('Y-m-d H:i:s'),
            'read_by' => []
        ];

        // اگر شناسه کاربر ارسال‌کننده در data نیست، سعی کن از انواع متداول جایگذاری کنی
        if (!isset($notification['data']) || !is_array($notification['data'])) {
            $notification['data'] = [];
        }
        if (!isset($notification['data']['user_id']) && isset($input['user_id'])) {
            $notification['data']['user_id'] = $input['user_id'];
        }
        
        $db['notifications'][] = $notification;
        error_log("Database after adding notification: " . json_encode($db));
        
        $saveResult = saveDatabase($db);
        error_log("Save result: " . ($saveResult ? "SUCCESS" : "FAILED"));
        
        echo json_encode(['success' => true, 'notification_id' => $notificationId]);
        break;
        
    case 'get_notifications_for_user':
        error_log("Getting notifications for user with input: " . json_encode($input));
        
        $userId = $input['user_id'] ?? '';
        $lastSyncTime = $input['last_sync_time'] ?? null;
        
        if (empty($userId)) {
            echo json_encode(['success' => false, 'message' => 'شناسه کاربر الزامی است']);
            break;
        }
        
        $db = loadDatabase();
        $notifications = $db['notifications'] ?? [];

        // فیلتر بر اساس last_sync_time (اگر موجود باشد)
        if (!empty($lastSyncTime)) {
            $notifications = array_filter($notifications, function($n) use ($lastSyncTime) {
                return strtotime($n['created_at'] ?? '1970-01-01 00:00:00') > strtotime($lastSyncTime);
            });
        }

        // حذف اعلان‌هایی که خود کاربر تولید کرده (اگر data.user_id وجود دارد)
        $notifications = array_filter($notifications, function($n) use ($userId) {
            $dataUserId = isset($n['data']) && is_array($n['data']) ? ($n['data']['user_id'] ?? null) : null;
            return $dataUserId === null || $dataUserId !== $userId;
        });

        // مرتب‌سازی بر اساس created_at صعودی
        usort($notifications, function($a, $b) {
            return strtotime(($a['created_at'] ?? '')) <=> strtotime(($b['created_at'] ?? ''));
        });

        $notifications = array_values($notifications);

        error_log("Returning " . count($notifications) . " notifications for user $userId after filters");
        echo json_encode(['success' => true, 'notifications' => $notifications]);
        break;
        
    case 'mark_notification_read':
        error_log("Marking notification as read with input: " . json_encode($input));
        
        $notificationId = $input['notification_id'] ?? '';
        $userId = $input['user_id'] ?? '';
        
        if (empty($notificationId) || empty($userId)) {
            echo json_encode(['success' => false, 'message' => 'اطلاعات ناقص است']);
            break;
        }
        
        $db = loadDatabase();
        $notificationFound = false;
        
        foreach ($db['notifications'] as &$notification) {
            if ($notification['id'] === $notificationId) {
                if (!in_array($userId, $notification['read_by'])) {
                    $notification['read_by'][] = $userId;
                }
                $notificationFound = true;
                break;
            }
        }
        
        if ($notificationFound) {
            saveDatabase($db);
            echo json_encode(['success' => true]);
        } else {
            echo json_encode(['success' => false, 'message' => 'نوتیفیکیشن یافت نشد']);
        }
        break;
        
    case 'get_unread_count':
        error_log("Getting unread count with input: " . json_encode($input));
        
        $userId = $input['user_id'] ?? '';
        
        if (empty($userId)) {
            echo json_encode(['success' => false, 'message' => 'شناسه کاربر الزامی است']);
            break;
        }
        
        $db = loadDatabase();
        $notifications = $db['notifications'] ?? [];
        $unreadCount = 0;
        
        foreach ($notifications as $notification) {
            if (!in_array($userId, $notification['read_by'])) {
                $unreadCount++;
            }
        }
        
        error_log("Unread count for user $userId: $unreadCount");
        echo json_encode(['success' => true, 'unread_count' => $unreadCount]);
        break;
        
    default:
        echo json_encode(['success' => false, 'message' => 'عملیات نامعتبر']);
        break;
}
?> 