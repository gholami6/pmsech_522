<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

// تنظیمات فایل CSV
$csv_file = 'grade_data.csv';
$backup_dir = 'backups/';

// ایجاد پوشه‌های مورد نیاز
if (!file_exists($backup_dir)) {
    mkdir($backup_dir, 0755, true);
}

// تابع ایجاد فایل CSV اگر وجود نداشته باشد
function createCsvIfNotExists() {
    global $csv_file;
    
    if (!file_exists($csv_file)) {
        $headers = "year,month,day,shift,grade_type,grade_value,recorded_by,recorded_at,equipment_id,work_group\n";
        file_put_contents($csv_file, $headers);
    }
}

// تابع پشتیبان‌گیری از فایل
function backupFile() {
    global $csv_file, $backup_dir;
    
    if (file_exists($csv_file)) {
        $backup_name = $backup_dir . 'grade_data_backup_' . date('Y-m-d_H-i-s') . '.csv';
        copy($csv_file, $backup_name);
    }
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input || !isset($input['grades'])) {
        echo json_encode([
            'success' => false,
            'message' => 'داده‌های ورودی نامعتبر است'
        ]);
        exit;
    }
    
    $grades = $input['grades'];
    $uploadedCount = 0;
    $errors = [];
    
    try {
        // ایجاد فایل CSV اگر وجود نداشته باشد
        createCsvIfNotExists();
        
        // پشتیبان‌گیری از فایل موجود
        if (isset($input['clear_existing']) && $input['clear_existing']) {
            backupFile();
            // پاک کردن فایل موجود
            file_put_contents($csv_file, "year,month,day,shift,grade_type,grade_value,recorded_by,recorded_at,equipment_id,work_group\n");
        }
        
        // خواندن داده‌های موجود
        $existingData = [];
        if (file_exists($csv_file)) {
            $lines = file($csv_file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
            if (count($lines) > 1) { // اگر header وجود دارد
                for ($i = 1; $i < count($lines); $i++) {
                    $existingData[] = $lines[$i];
                }
            }
        }
        
        // اضافه کردن داده‌های جدید
        foreach ($grades as $grade) {
            try {
                $year = intval($grade['year']);
                $month = intval($grade['month']);
                $day = intval($grade['day']);
                $shift = 1; // پیش‌فرض شیفت 1
                $recordedBy = 'system_batch_upload';
                $recordedAt = date('Y-m-d H:i:s');
                $equipmentId = '';
                $workGroup = 1;
                
                // درج عیار خوراک
                if (!empty($grade['feed_grade'])) {
                    $csvLine = "$year,$month,$day,$shift,خوراک," . floatval($grade['feed_grade']) . ",$recordedBy,$recordedAt,$equipmentId,$workGroup";
                    $existingData[] = $csvLine;
                    $uploadedCount++;
                }
                
                // درج عیار محصول
                if (!empty($grade['product_grade'])) {
                    $csvLine = "$year,$month,$day,$shift,محصول," . floatval($grade['product_grade']) . ",$recordedBy,$recordedAt,$equipmentId,$workGroup";
                    $existingData[] = $csvLine;
                    $uploadedCount++;
                }
                
                // درج عیار باطله
                if (!empty($grade['tailing_grade'])) {
                    $csvLine = "$year,$month,$day,$shift,باطله," . floatval($grade['tailing_grade']) . ",$recordedBy,$recordedAt,$equipmentId,$workGroup";
                    $existingData[] = $csvLine;
                    $uploadedCount++;
                }
                
            } catch (Exception $e) {
                $errors[] = "خطا در رکورد {$grade['day']}/{$grade['month']}/{$grade['year']}: " . $e->getMessage();
            }
        }
        
        // ذخیره تمام داده‌ها در فایل CSV
        $header = "year,month,day,shift,grade_type,grade_value,recorded_by,recorded_at,equipment_id,work_group\n";
        $content = $header . implode("\n", $existingData);
        
        if (file_put_contents($csv_file, $content) === false) {
            throw new Exception('خطا در ذخیره فایل CSV');
        }
        
        echo json_encode([
            'success' => true,
            'message' => "تعداد {$uploadedCount} رکورد عیار با موفقیت آپلود شد",
            'uploaded_count' => $uploadedCount,
            'errors' => $errors
        ]);
        
    } catch (Exception $e) {
        echo json_encode([
            'success' => false,
            'message' => 'خطا در آپلود دسته‌ای: ' . $e->getMessage(),
            'errors' => $errors
        ]);
    }
    
} else {
    echo json_encode([
        'success' => false,
        'message' => 'فقط متد POST پشتیبانی می‌شود'
    ]);
}
?>
