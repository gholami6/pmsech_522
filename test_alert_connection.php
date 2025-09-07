<?php
// تست اتصال API اعلان‌ها
header('Content-Type: application/json; charset=utf-8');

$baseUrl = 'https://sechahoon.liara.run';

// تست API اعلان‌های کارشناسان
function testAlertAPI($url) {
    $data = json_encode(['action' => 'get_alerts']);
    
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, $data);
    curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 10);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);
    curl_close($ch);
    
    return [
        'url' => $url,
        'http_code' => $httpCode,
        'response' => $response,
        'error' => $error
    ];
}

// تست API اعلان‌های مدیریت
function testManagerAlertAPI($url) {
    $data = json_encode(['action' => 'get_manager_alerts']);
    
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, $data);
    curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 10);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);
    curl_close($ch);
    
    return [
        'url' => $url,
        'http_code' => $httpCode,
        'response' => $response,
        'error' => $error
    ];
}

$results = [
    'alert_api' => testAlertAPI($baseUrl . '/alert_api.php'),
    'manager_alert_api' => testManagerAlertAPI($baseUrl . '/manager_alert_api.php')
];

echo json_encode($results, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
?>
