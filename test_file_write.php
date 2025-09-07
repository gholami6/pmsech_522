<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

$result = [];

// تست نوشتن فایل ساده
$testFile = 'test_write.txt';
$testContent = 'Test content: ' . date('Y-m-d H:i:s');

try {
    if (file_put_contents($testFile, $testContent)) {
        $result['test_write'] = [
            'success' => true,
            'message' => 'فایل تست با موفقیت نوشته شد',
            'file_size' => filesize($testFile),
            'content' => file_get_contents($testFile)
        ];
    } else {
        $result['test_write'] = [
            'success' => false,
            'message' => 'خطا در نوشتن فایل تست'
        ];
    }
} catch (Exception $e) {
    $result['test_write'] = [
        'success' => false,
        'message' => 'Exception: ' . $e->getMessage()
    ];
}

// تست نوشتن فایل JSON
$jsonFile = 'test_alerts.json';
$jsonContent = json_encode([
    'alerts' => [
        [
            'id' => 'test_' . time(),
            'message' => 'Test alert',
            'timestamp' => date('Y-m-d H:i:s')
        ]
    ]
]);

try {
    if (file_put_contents($jsonFile, $jsonContent)) {
        $result['test_json_write'] = [
            'success' => true,
            'message' => 'فایل JSON با موفقیت نوشته شد',
            'file_size' => filesize($jsonFile),
            'content' => file_get_contents($jsonFile)
        ];
    } else {
        $result['test_json_write'] = [
            'success' => false,
            'message' => 'خطا در نوشتن فایل JSON'
        ];
    }
} catch (Exception $e) {
    $result['test_json_write'] = [
        'success' => false,
        'message' => 'Exception: ' . $e->getMessage()
    ];
}

// بررسی مجدد فایل‌های موجود
$result['files_after_test'] = scandir('.');

echo json_encode($result, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
?> 