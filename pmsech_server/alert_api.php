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
$databaseFile = $tempDir . '/alerts_database.json';

// ذخیره دیتابیس در فایل موقت
function saveDatabase($data) {
    global $databaseFile;
    $result = file_put_contents($databaseFile, json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));
    error_log("Database saved to temp file: " . $databaseFile . " - Result: " . ($result ? "SUCCESS" : "FAILED"));
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
            $data = ['alerts' => [], 'users' => []];
        }
    } else {
        error_log("Database file not found: " . $databaseFile);
        $data = ['alerts' => [], 'users' => []];
    }
    error_log("Database loaded from temp file: " . $databaseFile . " - Alerts count: " . count($data['alerts']));
    return $data;
}

// دریافت داده‌های ورودی
$input = json_decode(file_get_contents('php://input'), true);
$action = $input['action'] ?? '';

switch ($action) {
    case 'create_alert':
        error_log("Creating alert with input: " . json_encode($input));
        
        $userId = $input['user_id'] ?? '';
        $equipmentId = $input['equipment_id'] ?? '';
        $message = $input['message'] ?? '';
        $category = $input['category'] ?? 'عمومی';
        
        if (empty($userId) || empty($equipmentId) || empty($message)) {
            error_log("Missing required fields");
            echo json_encode(['success' => false, 'message' => 'اطلاعات ناقص است']);
            break;
        }
        
        $db = loadDatabase();
        error_log("Database before adding alert: " . json_encode($db));
        
        $alert = [
            'id' => uniqid(),
            'user_id' => $userId,
            'equipment_id' => $equipmentId,
            'message' => $message,
            'category' => $category,
            'created_at' => date('Y-m-d H:i:s'),
            'replies' => [],
            'seen_by' => []
        ];
        
        $db['alerts'][] = $alert;
        error_log("Database after adding alert: " . json_encode($db));
        
        $saveResult = saveDatabase($db);
        error_log("Save result: " . ($saveResult ? "SUCCESS" : "FAILED"));
        
        echo json_encode(['success' => true, 'alert_id' => $alert['id']]);
        break;
        
    case 'get_alerts':
        error_log("Getting all alerts");
        $db = loadDatabase();
        $alerts = $db['alerts'] ?? [];
        error_log("Returning " . count($alerts) . " alerts");
        echo json_encode(['success' => true, 'alerts' => $alerts]);
        break;
        
    case 'add_reply':
        error_log("Adding reply with input: " . json_encode($input));
        
        $alertId = $input['alert_id'] ?? '';
        $userId = $input['user_id'] ?? '';
        $message = $input['message'] ?? '';
        
        if (empty($alertId) || empty($userId) || empty($message)) {
            echo json_encode(['success' => false, 'message' => 'اطلاعات ناقص است']);
            break;
        }
        
        $db = loadDatabase();
        $alertFound = false;
        
        foreach ($db['alerts'] as &$alert) {
            if ($alert['id'] === $alertId) {
                $reply = [
                    'id' => uniqid(),
                    'user_id' => $userId,
                    'message' => $message,
                    'created_at' => date('Y-m-d H:i:s')
                ];
                $alert['replies'][] = $reply;
                $alertFound = true;
                break;
            }
        }
        
        if ($alertFound) {
            saveDatabase($db);
            echo json_encode(['success' => true, 'reply_id' => $reply['id']]);
        } else {
            echo json_encode(['success' => false, 'message' => 'اعلان یافت نشد']);
        }
        break;
        
    case 'mark_as_seen':
        error_log("Marking alert as seen with input: " . json_encode($input));
        
        $alertId = $input['alert_id'] ?? '';
        $userId = $input['user_id'] ?? '';
        
        if (empty($alertId) || empty($userId)) {
            echo json_encode(['success' => false, 'message' => 'اطلاعات ناقص است']);
            break;
        }
        
        $db = loadDatabase();
        $alertFound = false;
        
        foreach ($db['alerts'] as &$alert) {
            if ($alert['id'] === $alertId) {
                if (!in_array($userId, $alert['seen_by'])) {
                    $alert['seen_by'][] = $userId;
                }
                $alertFound = true;
                break;
            }
        }
        
        if ($alertFound) {
            saveDatabase($db);
            echo json_encode(['success' => true]);
        } else {
            echo json_encode(['success' => false, 'message' => 'اعلان یافت نشد']);
        }
        break;
        
    case 'delete_alert':
        error_log("Deleting alert with input: " . json_encode($input));
        
        $alertId = $input['alert_id'] ?? '';
        $userId = $input['user_id'] ?? '';
        
        if (empty($alertId) || empty($userId)) {
            echo json_encode(['success' => false, 'message' => 'شناسه اعلان و کاربر الزامی است']);
            break;
        }
        
        $db = loadDatabase();
        $alertFound = false;
        $canDelete = false;
        
        foreach ($db['alerts'] as $key => $alert) {
            if ($alert['id'] === $alertId) {
                // بررسی مجوز حذف - فقط صادرکننده اعلان می‌تواند آن را حذف کند
                if ($alert['user_id'] === $userId) {
                    unset($db['alerts'][$key]);
                    $alertFound = true;
                    $canDelete = true;
                } else {
                    echo json_encode(['success' => false, 'message' => 'شما مجاز به حذف این اعلان نیستید']);
                    break;
                }
                break;
            }
        }
        
        if ($alertFound && $canDelete) {
            $db['alerts'] = array_values($db['alerts']); // بازسازی آرایه
            saveDatabase($db);
            echo json_encode(['success' => true]);
        } elseif (!$alertFound) {
            echo json_encode(['success' => false, 'message' => 'اعلان یافت نشد']);
        }
        break;
        
    case 'update_alert':
        error_log("Updating alert with input: " . json_encode($input));
        
        $alertId = $input['alert_id'] ?? '';
        $userId = $input['user_id'] ?? '';
        $message = $input['message'] ?? '';
        $equipmentId = $input['equipment_id'] ?? '';
        $category = $input['category'] ?? 'عمومی';
        
        if (empty($alertId) || empty($userId) || empty($message)) {
            echo json_encode(['success' => false, 'message' => 'اطلاعات ناقص است']);
            break;
        }
        
        $db = loadDatabase();
        $alertFound = false;
        $canUpdate = false;
        
        foreach ($db['alerts'] as &$alert) {
            if ($alert['id'] === $alertId) {
                // بررسی مجوز ویرایش - فقط صادرکننده اعلان می‌تواند آن را ویرایش کند
                if ($alert['user_id'] === $userId) {
                    $alert['message'] = $message;
                    if (!empty($equipmentId)) {
                        $alert['equipment_id'] = $equipmentId;
                    }
                    $alert['category'] = $category;
                    $alertFound = true;
                    $canUpdate = true;
                } else {
                    echo json_encode(['success' => false, 'message' => 'شما مجاز به ویرایش این اعلان نیستید']);
                    break;
                }
                break;
            }
        }
        
        if ($alertFound && $canUpdate) {
            saveDatabase($db);
            echo json_encode(['success' => true]);
        } elseif (!$alertFound) {
            echo json_encode(['success' => false, 'message' => 'اعلان یافت نشد']);
        }
        break;
        
    default:
        echo json_encode(['success' => false, 'message' => 'عملیات نامعتبر']);
        break;
}
?> 