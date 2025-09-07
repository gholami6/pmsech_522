<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

// تنظیمات فایل CSV
$csv_file = 'grade_data.csv';

// تابع خواندن داده‌های عیار
function readGradeData() {
    global $csv_file;
    
    if (!file_exists($csv_file)) {
        return [];
    }
    
    $lines = file($csv_file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    if (count($lines) <= 1) {
        return [];
    }
    
    $grades = [];
    // حذف header
    array_shift($lines);
    
    foreach ($lines as $line) {
        $parts = explode(',', $line);
        if (count($parts) >= 10) {
            $grade = [
                'year' => intval($parts[0]),
                'month' => intval($parts[1]),
                'day' => intval($parts[2]),
                'shift' => intval($parts[3]),
                'grade_type' => $parts[4],
                'grade_value' => floatval($parts[5]),
                'recorded_by' => $parts[6],
                'recorded_at' => $parts[7],
                'equipment_id' => $parts[8],
                'work_group' => intval($parts[9])
            ];
            $grades[] = $grade;
        }
    }
    
    return $grades;
}

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    try {
        $grades = readGradeData();
        
        echo json_encode([
            'success' => true,
            'message' => 'داده‌های عیار با موفقیت دریافت شد',
            'grades' => $grades,
            'count' => count($grades),
            'last_updated' => file_exists($csv_file) ? date('Y-m-d H:i:s', filemtime($csv_file)) : null
        ]);
        
    } catch (Exception $e) {
        echo json_encode([
            'success' => false,
            'message' => 'خطا در دریافت داده‌های عیار: ' . $e->getMessage()
        ]);
    }
} else {
    echo json_encode([
        'success' => false,
        'message' => 'فقط متد GET پشتیبانی می‌شود'
    ]);
}
?>
