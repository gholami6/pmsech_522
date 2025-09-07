<?php
header('Content-Type: application/json; charset=utf-8');

echo json_encode([
    'message' => 'شروع حل مشکل دسترسی‌ها...',
    'timestamp' => date('Y-m-d H:i:s')
]);

// تنظیمات
$csv_file = 'real_grades.csv';
$backup_dir = 'backups/';
$log_file = 'grade_api.log';

$results = [];

// 1. ایجاد پوشه backups اگر وجود ندارد
if (!file_exists($backup_dir)) {
    if (mkdir($backup_dir, 0755, true)) {
        $results['backup_dir_created'] = true;
        $results['backup_dir_message'] = 'پوشه backups ایجاد شد';
    } else {
        $results['backup_dir_created'] = false;
        $results['backup_dir_message'] = 'خطا در ایجاد پوشه backups';
    }
} else {
    $results['backup_dir_created'] = true;
    $results['backup_dir_message'] = 'پوشه backups قبلاً وجود دارد';
}

// 2. ایجاد فایل لاگ اگر وجود ندارد
if (!file_exists($log_file)) {
    if (file_put_contents($log_file, "=== شروع لاگ ===\n") !== false) {
        $results['log_file_created'] = true;
        $results['log_file_message'] = 'فایل لاگ ایجاد شد';
    } else {
        $results['log_file_created'] = false;
        $results['log_file_message'] = 'خطا در ایجاد فایل لاگ';
    }
} else {
    $results['log_file_created'] = true;
    $results['log_file_message'] = 'فایل لاگ قبلاً وجود دارد';
}

// 3. تغییر دسترسی فایل CSV
if (file_exists($csv_file)) {
    if (chmod($csv_file, 0666)) {
        $results['csv_permissions_fixed'] = true;
        $results['csv_permissions_message'] = 'دسترسی فایل CSV تغییر یافت';
    } else {
        $results['csv_permissions_fixed'] = false;
        $results['csv_permissions_message'] = 'خطا در تغییر دسترسی فایل CSV';
    }
} else {
    $results['csv_permissions_fixed'] = false;
    $results['csv_permissions_message'] = 'فایل CSV وجود ندارد';
}

// 4. تغییر دسترسی پوشه backups
if (file_exists($backup_dir)) {
    if (chmod($backup_dir, 0755)) {
        $results['backup_dir_permissions_fixed'] = true;
        $results['backup_dir_permissions_message'] = 'دسترسی پوشه backups تغییر یافت';
    } else {
        $results['backup_dir_permissions_fixed'] = false;
        $results['backup_dir_permissions_message'] = 'خطا در تغییر دسترسی پوشه backups';
    }
}

// 5. تغییر دسترسی فایل لاگ
if (file_exists($log_file)) {
    if (chmod($log_file, 0666)) {
        $results['log_file_permissions_fixed'] = true;
        $results['log_file_permissions_message'] = 'دسترسی فایل لاگ تغییر یافت';
    } else {
        $results['log_file_permissions_fixed'] = false;
        $results['log_file_permissions_message'] = 'خطا در تغییر دسترسی فایل لاگ';
    }
}

// 6. تست نهایی
$final_test = [
    'csv_exists' => file_exists($csv_file),
    'csv_readable' => is_readable($csv_file),
    'csv_writable' => is_writable($csv_file),
    'backup_dir_exists' => file_exists($backup_dir),
    'backup_dir_writable' => is_writable($backup_dir),
    'log_file_writable' => is_writable($log_file),
    'current_dir' => getcwd(),
    'csv_size' => file_exists($csv_file) ? filesize($csv_file) : 0,
];

$results['final_test'] = $final_test;

// 7. نتیجه کلی
$all_fixed = $final_test['csv_writable'] && 
             $final_test['backup_dir_writable'] && 
             $final_test['log_file_writable'];

$results['success'] = $all_fixed;
$results['message'] = $all_fixed ? 
    '✅ تمام مشکلات دسترسی حل شد!' : 
    '❌ برخی مشکلات دسترسی باقی مانده';

echo json_encode($results, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
?>
