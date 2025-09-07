<?php
// اسکریپت انتقال توقفات سال 1404 از production_data.csv به دیتابیس StopData

// تنظیمات دیتابیس
$dbPath = 'stop_data.db';

try {
    // ایجاد اتصال به دیتابیس SQLite
    $pdo = new PDO("sqlite:$dbPath");
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // ایجاد جدول stop_data اگر وجود ندارد
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS stop_data (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            year INTEGER,
            month INTEGER,
            day INTEGER,
            shift INTEGER,
            stopType TEXT,
            stopDuration TEXT,
            equipment TEXT,
            description TEXT
        )
    ");
    
    // خواندن فایل CSV
    $csvFile = 'production_data.csv';
    if (!file_exists($csvFile)) {
        die("فایل $csvFile موجود نیست!");
    }
    
    $handle = fopen($csvFile, 'r');
    if (!$handle) {
        die("نمی‌توان فایل $csvFile را باز کرد!");
    }
    
    // رد کردن سطر هدر
    fgetcsv($handle);
    
    $importedCount = 0;
    $skippedCount = 0;
    
    // آماده‌سازی query برای insert
    $stmt = $pdo->prepare("
        INSERT INTO stop_data (year, month, day, shift, stopType, stopDuration, equipment, description)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ");
    
    while (($data = fgetcsv($handle)) !== FALSE) {
        // بررسی اینکه آیا این رکورد مربوط به سال 1404 است
        if (count($data) >= 15 && $data[1] == '1404') {
            $year = intval($data[1]);
            $month = intval($data[2]);
            $day = intval($data[3]);
            $shift = intval($data[4]);
            $description = $data[5];
            $equipment = $data[6];
            $stopType = $data[12];
            $stopDuration = $data[15];
            
            // بررسی اینکه آیا این رکورد توقف است
            if (!empty($stopType) && !empty($stopDuration) && $stopDuration != '0:00') {
                try {
                    $stmt->execute([
                        $year,
                        $month,
                        $day,
                        $shift,
                        $stopType,
                        $stopDuration,
                        $equipment,
                        $description
                    ]);
                    $importedCount++;
                    
                    if ($importedCount % 100 == 0) {
                        echo "توقفات منتقل شده: $importedCount\n";
                    }
                } catch (Exception $e) {
                    echo "خطا در انتقال توقف: " . $e->getMessage() . "\n";
                    $skippedCount++;
                }
            }
        }
    }
    
    fclose($handle);
    
    echo "\n=== خلاصه انتقال ===\n";
    echo "توقفات منتقل شده: $importedCount\n";
    echo "توقفات رد شده: $skippedCount\n";
    
    // نمایش آمار توقفات منتقل شده
    $stats = $pdo->query("
        SELECT year, month, COUNT(*) as count 
        FROM stop_data 
        WHERE year = 1404 
        GROUP BY year, month 
        ORDER BY month
    ")->fetchAll(PDO::FETCH_ASSOC);
    
    echo "\n=== آمار توقفات سال 1404 ===\n";
    foreach ($stats as $stat) {
        echo "ماه {$stat['month']}: {$stat['count']} توقف\n";
    }
    
} catch (Exception $e) {
    echo "خطا: " . $e->getMessage() . "\n";
}
?>
