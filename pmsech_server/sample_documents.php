<?php
// فایل برای ایجاد فایل‌های نمونه PDF
header('Content-Type: application/json; charset=utf-8');

// ایجاد فایل‌ها در ریشه سرور
$uploadDir = './';

// تابع ایجاد فایل PDF نمونه
function createSamplePDF($fileName, $title, $content) {
    $pdfContent = "%PDF-1.4
1 0 obj
<<
/Type /Catalog
/Pages 2 0 R
>>
endobj
2 0 obj
<<
/Type /Pages
/Kids [3 0 R]
/Count 1
>>
endobj
3 0 obj
<<
/Type /Page
/Parent 2 0 R
/MediaBox [0 0 612 792]
/Contents 4 0 R
>>
endobj
4 0 obj
<<
/Length 500
>>
stream
BT
/F1 20 Tf
72 720 Td
($title) Tj
0 -40 Td
/F1 14 Tf
(نام فایل: $fileName) Tj
0 -30 Td
(تاریخ ایجاد: " . date('Y-m-d H:i:s') . ") Tj
0 -30 Td
(توضیحات: $content) Tj
0 -30 Td
(این یک فایل نمونه است که برای تست سیستم دانلود ایجاد شده است.) Tj
0 -30 Td
(شما می‌توانید فایل‌های واقعی خود را در پوشه documents قرار دهید.) Tj
ET
endstream
endobj
xref
0 5
0000000000 65535 f 
0000000009 00000 n 
0000000058 00000 n 
0000000115 00000 n 
0000000204 00000 n 
trailer
<<
/Size 5
/Root 1 0 R
>>
startxref
800
%%EOF";

    return $pdfContent;
}

// ایجاد فایل‌های نمونه
$sampleFiles = [
    'user_manual.pdf' => [
        'title' => 'راهنمای کاربری سیستم',
        'content' => 'راهنمای کامل استفاده از سیستم مدیریت کارخانه'
    ],
    'monthly_report.pdf' => [
        'title' => 'گزارش ماهانه تولید',
        'content' => 'گزارش تفصیلی تولید ماه جاری'
    ],
    'safety_manual.pdf' => [
        'title' => 'دستورالعمل ایمنی',
        'content' => 'دستورالعمل‌های ایمنی کارگاه'
    ]
];

$createdFiles = [];

foreach ($sampleFiles as $fileName => $fileInfo) {
    $filePath = $uploadDir . $fileName;
    $pdfContent = createSamplePDF($fileName, $fileInfo['title'], $fileInfo['content']);
    
    if (file_put_contents($filePath, $pdfContent)) {
        $createdFiles[] = [
            'file' => $fileName,
            'size' => filesize($filePath),
            'status' => 'created'
        ];
    } else {
        $createdFiles[] = [
            'file' => $fileName,
            'status' => 'failed'
        ];
    }
}

echo json_encode([
    'success' => true,
    'message' => 'فایل‌های نمونه ایجاد شدند',
    'files' => $createdFiles
], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
?> 