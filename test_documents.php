<?php
header('Content-Type: application/json; charset=utf-8');

// Test root directory for PDF files
$rootDir = './';

echo json_encode([
    'root_dir_exists' => is_dir($rootDir),
    'root_dir_path' => realpath($rootDir),
    'all_files_in_root' => scandir($rootDir),
    'pdf_files_only' => array_filter(scandir($rootDir), function($file) {
        return pathinfo($file, PATHINFO_EXTENSION) === 'pdf';
    }),
    'php_files' => array_filter(scandir($rootDir), function($file) {
        return pathinfo($file, PATHINFO_EXTENSION) === 'php';
    }),
    'config_file_exists' => file_exists('./documents_config.json'),
    'config_content' => file_exists('./documents_config.json') ? json_decode(file_get_contents('./documents_config.json'), true) : null
]);
?> 