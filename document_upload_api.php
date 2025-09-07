<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS, DELETE');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Configuration
$uploadDir = './uploads/documents/';
$maxFileSize = 50 * 1024 * 1024; // 50MB
$allowedExtensions = ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'jpg', 'jpeg', 'png', 'gif'];
$databaseFile = './documents_database.json';

// Create upload directory if it doesn't exist
if (!file_exists($uploadDir)) {
    mkdir($uploadDir, 0755, true);
}

// Load documents database
function loadDocumentsDatabase() {
    global $databaseFile;
    if (file_exists($databaseFile)) {
        $content = file_get_contents($databaseFile);
        return json_decode($content, true) ?: [];
    }
    return [];
}

// Save documents database
function saveDocumentsDatabase($data) {
    global $databaseFile;
    file_put_contents($databaseFile, json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));
}

// Get file extension
function getFileExtension($fileName) {
    return strtolower(pathinfo($fileName, PATHINFO_EXTENSION));
}

// Format file size
function formatFileSize($bytes) {
    if ($bytes < 1024) return $bytes . ' B';
    if ($bytes < 1024 * 1024) return round($bytes / 1024, 1) . ' KB';
    if ($bytes < 1024 * 1024 * 1024) return round($bytes / (1024 * 1024), 1) . ' MB';
    return round($bytes / (1024 * 1024 * 1024), 1) . ' GB';
}

// Generate unique ID
function generateUniqueId() {
    return uniqid() . '_' . time();
}

// Validate file
function validateFile($file) {
    global $maxFileSize, $allowedExtensions;
    
    if (!isset($file['tmp_name']) || !is_uploaded_file($file['tmp_name'])) {
        return ['valid' => false, 'message' => 'فایل آپلود نشده است'];
    }
    
    if ($file['size'] > $maxFileSize) {
        return ['valid' => false, 'message' => 'حجم فایل بیش از 50 مگابایت است'];
    }
    
    $extension = getFileExtension($file['name']);
    if (!in_array($extension, $allowedExtensions)) {
        return ['valid' => false, 'message' => 'نوع فایل مجاز نیست'];
    }
    
    return ['valid' => true];
}

// Get request action
$action = $_GET['action'] ?? '';

// API Endpoints
switch ($action) {
    case 'upload':
        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'متد نامعتبر']);
            break;
        }
        
        // Validate uploaded file
        if (!isset($_FILES['document'])) {
            echo json_encode(['success' => false, 'message' => 'فایلی انتخاب نشده است']);
            break;
        }
        
        $file = $_FILES['document'];
        $validation = validateFile($file);
        
        if (!$validation['valid']) {
            echo json_encode(['success' => false, 'message' => $validation['message']]);
            break;
        }
        
        // Get form data
        $userId = $_POST['user_id'] ?? '';
        $userName = $_POST['user_name'] ?? 'کاربر ناشناس';
        $description = $_POST['description'] ?? '';
        $category = $_POST['category'] ?? 'عمومی';
        $isPublic = isset($_POST['is_public']) ? $_POST['is_public'] === 'true' : true;
        
        // Generate unique filename
        $originalName = $file['name'];
        $extension = getFileExtension($originalName);
        $uniqueId = generateUniqueId();
        $newFileName = $uniqueId . '.' . $extension;
        $filePath = $uploadDir . $newFileName;
        
        // Move uploaded file
        if (!move_uploaded_file($file['tmp_name'], $filePath)) {
            echo json_encode(['success' => false, 'message' => 'خطا در ذخیره فایل']);
            break;
        }
        
        // Save to database
        $database = loadDocumentsDatabase();
        $document = [
            'id' => $uniqueId,
            'name' => $originalName,
            'file_name' => $newFileName,
            'extension' => $extension,
            'size' => $file['size'],
            'formatted_size' => formatFileSize($file['size']),
            'user_id' => $userId,
            'user_name' => $userName,
            'description' => $description,
            'category' => $category,
            'is_public' => $isPublic,
            'upload_date' => date('Y-m-d H:i:s'),
            'download_count' => 0,
            'file_path' => $filePath
        ];
        
        $database[] = $document;
        saveDocumentsDatabase($database);
        
        echo json_encode([
            'success' => true,
            'message' => 'فایل با موفقیت آپلود شد',
            'document' => $document
        ]);
        break;
        
    case 'list':
        $category = $_GET['category'] ?? null;
        $userId = $_GET['user_id'] ?? null;
        $isPublic = $_GET['public'] ?? null;
        
        $database = loadDocumentsDatabase();
        $documents = $database;
        
        // Apply filters
        if ($category && $category !== 'همه') {
            $documents = array_filter($documents, function($doc) use ($category) {
                return $doc['category'] === $category;
            });
        }
        
        if ($userId) {
            $documents = array_filter($documents, function($doc) use ($userId) {
                return $doc['user_id'] === $userId;
            });
        }
        
        if ($isPublic !== null) {
            $isPublicBool = $isPublic === 'true';
            $documents = array_filter($documents, function($doc) use ($isPublicBool) {
                return $doc['is_public'] === $isPublicBool;
            });
        }
        
        // Remove sensitive data
        foreach ($documents as &$doc) {
            unset($doc['file_path']);
        }
        
        echo json_encode([
            'success' => true,
            'documents' => array_values($documents)
        ]);
        break;
        
    case 'download':
        $documentId = $_GET['id'] ?? '';
        
        if (empty($documentId)) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'شناسه فایل مشخص نشده است']);
            break;
        }
        
        $database = loadDocumentsDatabase();
        $document = null;
        
        foreach ($database as $doc) {
            if ($doc['id'] === $documentId) {
                $document = $doc;
                break;
            }
        }
        
        if (!$document) {
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'فایل یافت نشد']);
            break;
        }
        
        $filePath = $document['file_path'];
        
        if (!file_exists($filePath)) {
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'فایل در سرور موجود نیست']);
            break;
        }
        
        // Update download count
        $document['download_count']++;
        foreach ($database as &$doc) {
            if ($doc['id'] === $documentId) {
                $doc['download_count'] = $document['download_count'];
                break;
            }
        }
        saveDocumentsDatabase($database);
        
        // Set headers for file download
        header('Content-Type: application/octet-stream');
        header('Content-Disposition: attachment; filename="' . $document['name'] . '"');
        header('Content-Length: ' . filesize($filePath));
        header('Cache-Control: no-cache, must-revalidate');
        header('Expires: 0');
        
        // Output file content
        readfile($filePath);
        break;
        
    case 'delete':
        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'متد نامعتبر']);
            break;
        }
        
        $documentId = $_POST['id'] ?? '';
        $userId = $_POST['user_id'] ?? '';
        
        if (empty($documentId) || empty($userId)) {
            echo json_encode(['success' => false, 'message' => 'پارامترهای نامعتبر']);
            break;
        }
        
        $database = loadDocumentsDatabase();
        $document = null;
        $documentIndex = -1;
        
        foreach ($database as $index => $doc) {
            if ($doc['id'] === $documentId) {
                $document = $doc;
                $documentIndex = $index;
                break;
            }
        }
        
        if (!$document) {
            echo json_encode(['success' => false, 'message' => 'فایل یافت نشد']);
            break;
        }
        
        // Check if user can delete (owner or admin)
        if ($document['user_id'] !== $userId) {
            echo json_encode(['success' => false, 'message' => 'شما مجوز حذف این فایل را ندارید']);
            break;
        }
        
        // Delete file from server
        if (file_exists($document['file_path'])) {
            unlink($document['file_path']);
        }
        
        // Remove from database
        array_splice($database, $documentIndex, 1);
        saveDocumentsDatabase($database);
        
        echo json_encode(['success' => true, 'message' => 'فایل با موفقیت حذف شد']);
        break;
        
    case 'info':
        $database = loadDocumentsDatabase();
        
        $totalFiles = count($database);
        $totalSize = 0;
        $categories = [];
        $publicFiles = 0;
        
        foreach ($database as $doc) {
            $totalSize += $doc['size'];
            $categories[$doc['category']] = ($categories[$doc['category']] ?? 0) + 1;
            if ($doc['is_public']) $publicFiles++;
        }
        
        echo json_encode([
            'success' => true,
            'info' => [
                'total_files' => $totalFiles,
                'total_size' => $totalSize,
                'formatted_total_size' => formatFileSize($totalSize),
                'public_files' => $publicFiles,
                'private_files' => $totalFiles - $publicFiles,
                'categories' => $categories
            ]
        ]);
        break;
        
    default:
        echo json_encode([
            'success' => false,
            'message' => 'عملیات نامعتبر',
            'available_actions' => ['upload', 'list', 'download', 'delete', 'info']
        ]);
        break;
}
?> 