<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Configuration
$documentsDir = './'; // تغییر به ریشه سرور
$documentsConfigFile = './documents_config.json';

// Create documents directory if it doesn't exist
if (!file_exists($documentsDir)) {
    mkdir($documentsDir, 0755, true);
}

// Load documents configuration
function loadDocumentsConfig() {
    global $documentsConfigFile;
    
    // تلاش در مسیرهای مختلف برای بارگذاری کانفیگ
    $possibleConfigPaths = [
        $documentsConfigFile,
        './documents_config.json',
        '/tmp/documents_config.json'
    ];
    
    foreach ($possibleConfigPaths as $configFile) {
        if (file_exists($configFile)) {
            try {
                $content = file_get_contents($configFile);
                $config = json_decode($content, true);
                if ($config) {
                    error_log("Config loaded successfully from: $configFile");
                    return $config;
                }
            } catch (Exception $e) {
                error_log("Failed to load config from $configFile: " . $e->getMessage());
            }
        }
    }
    
    error_log("No valid config file found, returning empty array");
    return [];
}

// Save documents configuration
function saveDocumentsConfig($config) {
    global $documentsConfigFile;
    
    // تلاش در مسیرهای مختلف برای ذخیره کانفیگ
    $possibleConfigPaths = [
        $documentsConfigFile,
        './documents_config.json',
        '/tmp/documents_config.json'
    ];
    
    foreach ($possibleConfigPaths as $configFile) {
        try {
            if (file_put_contents($configFile, json_encode($config, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE))) {
                error_log("Config saved successfully to: $configFile");
                return true;
            }
        } catch (Exception $e) {
            error_log("Failed to save config to $configFile: " . $e->getMessage());
        }
    }
    
    error_log("Failed to save config to any location");
    return false;
}

// Check user permission for document
function checkUserPermission($document, $userPosition) {
    // اگر فایل عمومی باشد
    if ($document['is_public']) {
        return true;
    }
    
    // اگر کاربر مدیر باشد
    if (strpos($userPosition, 'مدیر') !== false) {
        return true;
    }
    
    // بررسی دسترسی بر اساس موقعیت کاربر
    if (isset($document['allowed_positions']) && is_array($document['allowed_positions'])) {
        foreach ($document['allowed_positions'] as $allowedPosition) {
            if (strpos($userPosition, $allowedPosition) !== false) {
                return true;
            }
        }
    }
    
    return false;
}

// Get file size
function getFileSize($filePath) {
    if (file_exists($filePath)) {
        return filesize($filePath);
    }
    return 0;
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

// Get request data
$input = json_decode(file_get_contents('php://input'), true);
$action = $input['action'] ?? $_POST['action'] ?? $_GET['action'] ?? '';

// دیباگ action
error_log("Action received: $action");
error_log("POST action: " . ($_POST['action'] ?? 'not set'));
error_log("GET action: " . ($_GET['action'] ?? 'not set'));

// API Endpoints
switch ($action) {
    case 'ping':
        echo json_encode(['success' => true, 'message' => 'API is working']);
        break;
        
    case 'list':
        $userId = $input['user_id'] ?? '';
        $userPosition = $input['user_position'] ?? '';
        
        $config = loadDocumentsConfig();
        $documents = [];
        
        // اسکن پوشه documents و ایجاد کانفیگ برای فایل‌های واقعی
        if (is_dir($documentsDir)) {
            $files = scandir($documentsDir);
            $realDocuments = [];
            
            // دیباگ: نمایش همه فایل‌ها
            error_log("All files in directory: " . print_r($files, true));
            
            foreach ($files as $file) {
                if ($file !== '.' && $file !== '..' && is_file($documentsDir . $file)) {
                    $extension = getFileExtension($file);
                    
                    // دیباگ: نمایش فایل‌های PDF
                    if ($extension === 'pdf') {
                        error_log("Found PDF file: " . $file);
                    }
                    
                    // فقط فایل‌های PDF را در نظر بگیر
                    if ($extension === 'pdf') {
                        $filePath = $documentsDir . $file;
                        $fileName = pathinfo($file, PATHINFO_FILENAME);
                        
                        // بررسی وجود کانفیگ
                        $documentConfig = null;
                        foreach ($config as $doc) {
                            if ($doc['file_name'] === $file) {
                                $documentConfig = $doc;
                                break;
                            }
                        }
                        
                        // اگر کانفیگ وجود ندارد، ایجاد کانفیگ پیش‌فرض
                        if (!$documentConfig) {
                            $documentConfig = [
                                'id' => uniqid(),
                                'name' => $fileName,
                                'file_name' => $file,
                                'extension' => $extension,
                                'size' => getFileSize($filePath),
                                'category' => 'مدارک عمومی',
                                'equipment' => null,
                                'is_public' => true,
                                'allowed_positions' => [],
                                'description' => 'فایل ' . $fileName,
                                'upload_date' => date('Y-m-d H:i:s', filemtime($filePath))
                            ];
                        }
                        
                        $realDocuments[] = $documentConfig;
                    }
                }
            }
            
            // دیباگ: نمایش فایل‌های واقعی پیدا شده
            error_log("Real documents found: " . count($realDocuments));
            
            // اگر فایل‌های واقعی وجود دارند، از آن‌ها استفاده کن
            if (!empty($realDocuments)) {
                $config = $realDocuments;
                saveDocumentsConfig($config);
                error_log("Using real documents: " . print_r($config, true));
            }
        }
        
        // اگر هنوز فایل‌های واقعی وجود ندارد، فایل‌های موجود را شناسایی کن
        if (empty($config)) {
            // شناسایی فایل‌های PDF موجود
            $existingFiles = [
                [
                    'id' => 'doc1',
                    'name' => 'مدرک شماره 1',
                    'file_name' => '1.pdf',
                    'extension' => 'pdf',
                    'size' => file_exists('./1.pdf') ? filesize('./1.pdf') : (file_exists('/tmp/1.pdf') ? filesize('/tmp/1.pdf') : (file_exists('/var/www/html/1.pdf') ? filesize('/var/www/html/1.pdf') : 1024000)),
                    'category' => 'مدارک عمومی',
                    'equipment' => 'خط یک',
                    'is_public' => true,
                    'allowed_positions' => [],
                    'description' => 'مدرک شماره 1',
                    'upload_date' => date('Y-m-d H:i:s')
                ],
                [
                    'id' => 'doc2',
                    'name' => 'مدرک شماره 2',
                    'file_name' => '2.pdf',
                    'extension' => 'pdf',
                    'size' => file_exists('./2.pdf') ? filesize('./2.pdf') : (file_exists('/tmp/2.pdf') ? filesize('/tmp/2.pdf') : (file_exists('/var/www/html/2.pdf') ? filesize('/var/www/html/2.pdf') : 1024000)),
                    'category' => 'مدارک عمومی',
                    'equipment' => 'سنگ شکن',
                    'is_public' => true,
                    'allowed_positions' => [],
                    'description' => 'مدرک شماره 2',
                    'upload_date' => date('Y-m-d H:i:s')
                ],
                [
                    'id' => 'doc3',
                    'name' => 'مدرک شماره 3',
                    'file_name' => '3.pdf',
                    'extension' => 'pdf',
                    'size' => file_exists('./3.pdf') ? filesize('./3.pdf') : (file_exists('/tmp/3.pdf') ? filesize('/tmp/3.pdf') : (file_exists('/var/www/html/3.pdf') ? filesize('/var/www/html/3.pdf') : 1024000)),
                    'category' => 'مدارک عمومی',
                    'equipment' => 'تلشکی',
                    'is_public' => true,
                    'allowed_positions' => [],
                    'description' => 'مدرک شماره 3',
                    'upload_date' => date('Y-m-d H:i:s')
                ],
                [
                    'id' => 'doc4',
                    'name' => 'برنامه شماره 4',
                    'file_name' => 'plan_4.pdf',
                    'extension' => 'pdf',
                    'size' => file_exists('./plan_4.pdf') ? filesize('./plan_4.pdf') : (file_exists('/tmp/plan_4.pdf') ? filesize('/tmp/plan_4.pdf') : (file_exists('/var/www/html/plan_4.pdf') ? filesize('/var/www/html/plan_4.pdf') : 1024000)),
                    'category' => 'برنامه‌ریزی',
                    'equipment' => 'خط یک',
                    'is_public' => true,
                    'allowed_positions' => [],
                    'description' => 'برنامه شماره 4',
                    'upload_date' => date('Y-m-d H:i:s')
                ]
            ];
            
            $config = $existingFiles;
            saveDocumentsConfig($config);
        }
        
        // اگر هیچ فایلی پیدا نشد، فایل‌های نمونه را برگردان
        if (empty($documents)) {
            $documents = $config;
        }
        
        echo json_encode([
            'success' => true,
            'documents' => $documents
        ]);
        break;
        
    case 'download_info':
        $documentId = $input['document_id'] ?? '';
        $userId = $input['user_id'] ?? '';
        $userPosition = $input['user_position'] ?? '';
        
        $config = loadDocumentsConfig();
        $document = null;
        
        // Find document
        foreach ($config as $doc) {
            if ($doc['id'] === $documentId) {
                $document = $doc;
                break;
            }
        }
        
        if (!$document) {
            echo json_encode([
                'success' => false,
                'message' => 'فایل مورد نظر یافت نشد'
            ]);
            break;
        }
        
        // Check permission
        if (!checkUserPermission($document, $userPosition)) {
            echo json_encode([
                'success' => false,
                'message' => 'شما مجوز دسترسی به این فایل را ندارید'
            ]);
            break;
        }
        
        // تلاش در مسیرهای مختلف برای یافتن فایل
        $possiblePaths = [
            './' . $document['file_name'],
            '/tmp/' . $document['file_name'],
            './uploads/' . $document['file_name'],
            $document['file_name'],
            '/var/www/html/' . $document['file_name'],
            '/home/liara/' . $document['file_name']
        ];
        
        $filePath = null;
        foreach ($possiblePaths as $path) {
            if (file_exists($path)) {
                $filePath = $path;
                break;
            }
        }
        
        if (!$filePath) {
            echo json_encode([
                'success' => false,
                'message' => 'فایل در سرور موجود نیست'
            ]);
            break;
        }
        
        echo json_encode([
            'success' => true,
            'document' => $document,
            'file_size' => getFileSize($filePath),
            'formatted_size' => formatFileSize(getFileSize($filePath))
        ]);
        break;
        
    case 'upload':
        // آپلود فایل جدید
        error_log("Upload action received - Method: " . $_SERVER['REQUEST_METHOD']);
        error_log("POST data: " . print_r($_POST, true));
        error_log("FILES data: " . print_r($_FILES, true));
        
        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            echo json_encode(['success' => false, 'message' => 'فقط درخواست POST مجاز است']);
            break;
        }
        
        error_log("Upload request received");
        error_log("POST data: " . print_r($_POST, true));
        error_log("FILES data: " . print_r($_FILES, true));
        
        // بررسی وجود فایل
        if (!isset($_FILES['file']) || $_FILES['file']['error'] !== UPLOAD_ERR_OK) {
            echo json_encode(['success' => false, 'message' => 'فایل آپلود نشده یا خطا در آپلود']);
            break;
        }
        
        $file = $_FILES['file'];
        $fileName = $file['name'];
        $fileSize = $file['size'];
        $fileTmpName = $file['tmp_name'];
        
        // بررسی حجم فایل (50MB)
        if ($fileSize > 50 * 1024 * 1024) {
            echo json_encode(['success' => false, 'message' => 'حجم فایل بیش از 50 مگابایت است']);
            break;
        }
        
        // بررسی نوع فایل
        $allowedExtensions = ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'jpg', 'jpeg', 'png', 'gif'];
        $fileExtension = strtolower(pathinfo($fileName, PATHINFO_EXTENSION));
        if (!in_array($fileExtension, $allowedExtensions)) {
            echo json_encode(['success' => false, 'message' => 'نوع فایل مجاز نیست']);
            break;
        }
        
        // ایجاد نام فایل منحصر به فرد
        $uniqueFileName = uniqid() . '_' . $fileName;
        $uploadPath = './' . $uniqueFileName;
        
        // آپلود فایل - تلاش در مسیرهای مختلف
        $possibleUploadPaths = [
            './' . $uniqueFileName,
            '/tmp/' . $uniqueFileName,
            './uploads/' . $uniqueFileName
        ];
        
        $uploadSuccess = false;
        $finalUploadPath = '';
        
        foreach ($possibleUploadPaths as $path) {
            if (move_uploaded_file($fileTmpName, $path)) {
                $uploadSuccess = true;
                $finalUploadPath = $path;
                error_log("File uploaded successfully to: $path");
                break;
            }
        }
        
        if ($uploadSuccess) {
            // دریافت اطلاعات اضافی
            $userId = $_POST['user_id'] ?? '';
            $userName = $_POST['user_name'] ?? '';
            $description = $_POST['description'] ?? '';
            $category = $_POST['category'] ?? 'نامه‌های ارسالی';
            $equipment = $_POST['equipment'] ?? '';
            $isPublic = isset($_POST['is_public']) ? ($_POST['is_public'] === 'true') : true;
            
            // ایجاد رکورد جدید
            $newDocument = [
                'id' => uniqid(),
                'name' => pathinfo($fileName, PATHINFO_FILENAME),
                'file_name' => basename($finalUploadPath),
                'extension' => $fileExtension,
                'size' => $fileSize,
                'category' => $category,
                'equipment' => $equipment,
                'is_public' => $isPublic,
                'allowed_positions' => [],
                'description' => $description,
                'upload_date' => date('Y-m-d H:i:s'),
                'uploaded_by' => $userName,
                'user_id' => $userId
            ];
            
            // اضافه کردن به کانفیگ (بدون ذخیره فایل)
            $config = loadDocumentsConfig();
            $config[] = $newDocument;
            
            // تلاش برای ذخیره کانفیگ
            try {
                saveDocumentsConfig($config);
                error_log("Config saved successfully");
            } catch (Exception $e) {
                error_log("Failed to save config: " . $e->getMessage());
                // حتی اگر کانفیگ ذخیره نشد، فایل آپلود شده است
            }
            
            echo json_encode([
                'success' => true,
                'message' => 'فایل با موفقیت آپلود شد',
                'document' => $newDocument
            ]);
        } else {
            echo json_encode(['success' => false, 'message' => 'خطا در ذخیره فایل در هیچ مسیری']);
        }
        break;
        
    case 'download':
        // دریافت پارامترها از GET یا POST
        $documentId = $_GET['document_id'] ?? $input['document_id'] ?? '';
        $userId = $_GET['user_id'] ?? $input['user_id'] ?? '';
        $userPosition = $_GET['user_position'] ?? $input['user_position'] ?? '';
        
        error_log("Download request - Document ID: $documentId, User ID: $userId, Position: $userPosition");
        
        $config = loadDocumentsConfig();
        $document = null;
        
        // جستجو در کانفیگ
        foreach ($config as $doc) {
            if ($doc['id'] === $documentId) {
                $document = $doc;
                break;
            }
        }
        
        if (!$document) {
            error_log("Document not found: $documentId");
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'فایل یافت نشد']);
            break;
        }
        
        // بررسی مجوز دسترسی
        if (!checkUserPermission($document, $userPosition)) {
            error_log("Access denied for user: $userId, position: $userPosition");
            http_response_code(403);
            echo json_encode(['success' => false, 'message' => 'دسترسی غیرمجاز']);
            break;
        }
        
        // تلاش در مسیرهای مختلف برای یافتن فایل
        $possiblePaths = [
            './' . $document['file_name'],
            '/tmp/' . $document['file_name'],
            './uploads/' . $document['file_name'],
            $document['file_name'],
            '/var/www/html/' . $document['file_name'],
            '/home/liara/' . $document['file_name']
        ];
        
        $filePath = null;
        foreach ($possiblePaths as $path) {
            error_log("Checking path: $path");
            if (file_exists($path)) {
                $filePath = $path;
                error_log("File found at: $filePath, size: " . filesize($path));
                break;
            }
        }
        
        if (!$filePath) {
            error_log("File not found in any path for: " . $document['file_name']);
            error_log("Available files in current directory: " . print_r(scandir('.'), true));
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'فایل مورد نظر در سرور موجود نیست']);
            break;
        }
        
        // Set headers for file download
        header('Content-Type: application/octet-stream');
        header('Content-Disposition: attachment; filename="' . $document['file_name'] . '"');
        header('Content-Length: ' . filesize($filePath));
        header('Cache-Control: no-cache, must-revalidate');
        header('Expires: 0');
        header('Access-Control-Allow-Origin: *');
        header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
        header('Access-Control-Allow-Headers: Content-Type, Authorization');
        
        error_log("Sending file: $filePath, size: " . filesize($filePath));
        
        // Output file content
        readfile($filePath);
        break;
        
    default:
        echo json_encode([
            'success' => false,
            'message' => 'عملیات نامعتبر'
        ]);
        break;
}
?> 