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
$databaseFile = $tempDir . '/manager_alerts_database.json';

// ذخیره دیتابیس در فایل موقت
function saveDatabase($data) {
    global $databaseFile;
    $result = file_put_contents($databaseFile, json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));
    error_log("Manager database saved to temp file: " . $databaseFile . " - Result: " . ($result ? "SUCCESS" : "FAILED"));
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
        error_log("Manager database file not found: " . $databaseFile);
        $data = ['alerts' => [], 'users' => []];
    }
    error_log("Manager database loaded from temp file: " . $databaseFile . " - Alerts count: " . count($data['alerts']));
    return $data;
}

// دریافت داده‌های ورودی
$input = json_decode(file_get_contents('php://input'), true);
$action = $input['action'] ?? '';

switch ($action) {
    case 'create_manager_alert':
        error_log("Creating manager alert with input: " . json_encode($input));
        
        $userId = $input['user_id'] ?? '';
        $title = $input['title'] ?? '';
        $message = $input['message'] ?? '';
        $category = $input['category'] ?? '';
        $targetStakeholderTypes = $input['target_stakeholder_types'] ?? [];
        $targetRoleTypes = $input['target_role_types'] ?? [];
        $allowReplies = $input['allow_replies'] ?? true;
        
        if (empty($userId) || empty($title) || empty($message) || empty($category)) {
            error_log("Missing required fields");
            echo json_encode(['success' => false, 'message' => 'اطلاعات ناقص است']);
            break;
        }
        
        $db = loadDatabase();
        error_log("Database before adding manager alert: " . json_encode($db));
        
        $alert = [
            'id' => uniqid(),
            'user_id' => $userId,
            'title' => $title,
            'message' => $message,
            'category' => $category,
            'target_stakeholder_types' => $targetStakeholderTypes,
            'target_role_types' => $targetRoleTypes,
            'allow_replies' => $allowReplies,
            'created_at' => date('Y-m-d H:i:s'),
            'replies' => [],
            'seen_by' => []
        ];
        
        $db['alerts'][] = $alert;
        error_log("Database after adding manager alert: " . json_encode($db));
        
        $saveResult = saveDatabase($db);
        error_log("Save result: " . ($saveResult ? "SUCCESS" : "FAILED"));
        
        echo json_encode(['success' => true, 'alert_id' => $alert['id']]);
        break;
        
    case 'get_manager_alerts':
        error_log("Getting all manager alerts");
        $db = loadDatabase();
        $alerts = $db['alerts'] ?? [];
        error_log("Returning " . count($alerts) . " manager alerts");
        echo json_encode(['success' => true, 'alerts' => $alerts]);
        break;
        
    case 'add_manager_reply':
        error_log("Adding manager reply with input: " . json_encode($input));
        
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
        
    case 'mark_manager_alert_as_seen':
        error_log("Marking manager alert as seen with input: " . json_encode($input));
        
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
        
    case 'delete_manager_alert':
        error_log("Deleting manager alert with input: " . json_encode($input));
        
        $alertId = $input['alert_id'] ?? '';
        
        if (empty($alertId)) {
            echo json_encode(['success' => false, 'message' => 'شناسه اعلان الزامی است']);
            break;
        }
        
        $db = loadDatabase();
        $alertFound = false;
        
        foreach ($db['alerts'] as $key => $alert) {
            if ($alert['id'] === $alertId) {
                unset($db['alerts'][$key]);
                $alertFound = true;
                break;
            }
        }
        
        if ($alertFound) {
            $db['alerts'] = array_values($db['alerts']); // بازسازی آرایه
            saveDatabase($db);
            echo json_encode(['success' => true]);
        } else {
            echo json_encode(['success' => false, 'message' => 'اعلان یافت نشد']);
        }
        break;
        
    case 'update_manager_alert':
        error_log("Updating manager alert with input: " . json_encode($input));
        
        $alertId = $input['alert_id'] ?? '';
        $title = $input['title'] ?? '';
        $message = $input['message'] ?? '';
        $category = $input['category'] ?? '';
        $targetStakeholderTypes = $input['target_stakeholder_types'] ?? [];
        $targetRoleTypes = $input['target_role_types'] ?? [];
        $allowReplies = $input['allow_replies'] ?? true;
        
        if (empty($alertId) || empty($title) || empty($message) || empty($category)) {
            echo json_encode(['success' => false, 'message' => 'اطلاعات ناقص است']);
            break;
        }
        
        $db = loadDatabase();
        $alertFound = false;
        
        foreach ($db['alerts'] as &$alert) {
            if ($alert['id'] === $alertId) {
                $alert['title'] = $title;
                $alert['message'] = $message;
                $alert['category'] = $category;
                $alert['target_stakeholder_types'] = $targetStakeholderTypes;
                $alert['target_role_types'] = $targetRoleTypes;
                $alert['allow_replies'] = $allowReplies;
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
        
    case 'get_manager_alert_by_id':
        error_log("Getting manager alert by ID with input: " . json_encode($input));
        
        $alertId = $input['alert_id'] ?? '';
        
        if (empty($alertId)) {
            echo json_encode(['success' => false, 'message' => 'شناسه اعلان الزامی است']);
            break;
        }
        
        $db = loadDatabase();
        $alertFound = false;
        
        foreach ($db['alerts'] as $alert) {
            if ($alert['id'] === $alertId) {
                echo json_encode(['success' => true, 'alert' => $alert]);
                $alertFound = true;
                break;
            }
        }
        
        if (!$alertFound) {
            echo json_encode(['success' => false, 'message' => 'اعلان یافت نشد']);
        }
        break;
        
    case 'add_reply_to_manager_alert':
        error_log("Adding reply to manager alert with input: " . json_encode($input));
        
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
                    'user_id' => $userId,
                    'message' => $message,
                    'created_at' => date('Y-m-d H:i:s')
                ];
                
                if (!isset($alert['replies'])) {
                    $alert['replies'] = [];
                }
                
                $alert['replies'][] = $reply;
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
        
    default:
        echo json_encode(['success' => false, 'message' => 'عملیات نامعتبر']);
        break;
}
?> 