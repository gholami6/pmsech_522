<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Simple WebSocket simulation for manager alerts
// This is a polling endpoint that simulates WebSocket behavior

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Get user_id from query parameter
$user_id = isset($_GET['user_id']) ? $_GET['user_id'] : null;

if (!$user_id) {
    http_response_code(400);
    echo json_encode(['error' => 'user_id required']);
    exit();
}

// For now, return empty response to avoid connection errors
// In a real implementation, this would check for new alerts
$response = [
    'status' => 'connected',
    'user_id' => $user_id,
    'message' => 'WebSocket simulation active',
    'timestamp' => date('Y-m-d H:i:s'),
    'alerts' => [] // Empty alerts for now
];

echo json_encode($response);
?>
