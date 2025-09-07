<?php
header('Content-Type: application/json; charset=utf-8');

$csv_file = 'real_grades.csv';
$backup_dir = 'backups/';
$log_file = 'grade_api.log';

echo json_encode([
    'success' => true,
    'tests' => [
        'csv_exists' => file_exists($csv_file),
        'csv_readable' => is_readable($csv_file),
        'csv_writable' => is_writable($csv_file),
        'backup_dir_exists' => file_exists($backup_dir),
        'backup_dir_writable' => is_writable($backup_dir),
        'log_file_writable' => is_writable($log_file),
        'current_dir' => getcwd(),
        'csv_size' => file_exists($csv_file) ? filesize($csv_file) : 0,
    ]
]);
?>
