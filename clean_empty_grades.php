<?php
// پاک‌سازی عیارهای خالی از فایل CSV
header('Content-Type: application/json; charset=utf-8');

// تنظیمات
$csv_file = 'real_grades.csv';
$backup_file = 'real_grades_backup_' . date('Y-m-d_H-i-s') . '.csv';

echo "=== پاک‌سازی عیارهای خالی ===\n";

// ایجاد پشتیبان
if (file_exists($csv_file)) {
    copy($csv_file, $backup_file);
    echo "پشتیبان ایجاد شد: $backup_file\n";
} else {
    echo "فایل اصلی یافت نشد: $csv_file\n";
    exit;
}

// خواندن فایل
$csv_content = file_get_contents($csv_file);
$lines = explode("\n", trim($csv_content));
$header = array_shift($lines);

echo "تعداد ردیف‌ها قبل از پاک‌سازی: " . count($lines) . "\n";

$cleaned_lines = [];
$removed_count = 0;

foreach ($lines as $line) {
    if (!empty(trim($line))) {
        $fields = str_getcsv($line);
        if (count($fields) >= 6) {
            $feed = trim($fields[3]);
            $product = trim($fields[4]);
            $tailing = trim($fields[5]);
            
            // بررسی اینکه آیا تمام عیارها خالی هستند
            $allEmpty = true;
            if ($feed !== '' && is_numeric($feed) && floatval($feed) > 0) $allEmpty = false;
            if ($product !== '' && is_numeric($product) && floatval($product) > 0) $allEmpty = false;
            if ($tailing !== '' && is_numeric($tailing) && floatval($tailing) > 0) $allEmpty = false;
            
            if ($allEmpty) {
                echo "حذف ردیف خالی: " . implode(',', $fields) . "\n";
                $removed_count++;
            } else {
                $cleaned_lines[] = $line;
            }
        } else {
            $cleaned_lines[] = $line;
        }
    }
}

echo "تعداد ردیف‌های حذف شده: $removed_count\n";
echo "تعداد ردیف‌های باقی‌مانده: " . count($cleaned_lines) . "\n";

// بازنویسی فایل
$new_content = $header . "\n" . implode("\n", $cleaned_lines) . "\n";
file_put_contents($csv_file, $new_content);

echo "فایل پاک‌سازی شد: $csv_file\n";
echo "=== پایان پاک‌سازی ===\n";
?>
