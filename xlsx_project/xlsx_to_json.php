<?php
require 'vendor/autoload.php';

use PhpOffice\PhpSpreadsheet\IOFactory;
use PhpOffice\PhpSpreadsheet\Shared\Date;

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

function convertExcelDate($value) {
    if (is_numeric($value)) {
        try {
            return Date::excelToDateTimeObject($value)->format('Y-m-d');
        } catch (Exception $e) {
            return null;
        }
    }
    return $value;
}

function convertExcelTime($value) {
    if (is_numeric($value)) {
        try {
            $hours = floor($value * 24);
            $minutes = floor(($value * 24 * 60) % 60);
            return sprintf("%02d:%02d", $hours, $minutes);
        } catch (Exception $e) {
            return null;
        }
    }
    return $value;
}

function processSingleNamedRange($spreadsheet, $rangeName) {
    $stopData = [];
    $productionData = [];
    
    try {
        // Get the named range
        $namedRange = $spreadsheet->getNamedRange($rangeName);
        if (!$namedRange) {
            throw new Exception("Named range '$rangeName' not found");
        }
        
        $worksheet = $spreadsheet->getSheetByName($namedRange->getWorksheet()->getTitle());
        $range = $namedRange->getRange();
        
        // Get all data from the named range
        $rangeData = $worksheet->rangeToArray($range, null, true, false);
        
        // Get header row to understand column structure
        $headers = $rangeData[0];
        
        // Skip header row and process data rows
        for ($i = 1; $i < count($rangeData); $i++) {
            $rowData = $rangeData[$i];
            
            // Skip completely empty rows
            if (empty(array_filter($rowData))) continue;
            
            // Determine if this is stop data or production data based on column structure
            $isStopData = determineIfStopData($headers, $rowData);
            
            if ($isStopData) {
                $processedData = processStopRow($headers, $rowData);
                if ($processedData) {
                    $stopData[] = $processedData;
                }
            } else {
                $processedData = processProductionRow($headers, $rowData);
                if ($processedData) {
                    $productionData[] = $processedData;
                }
            }
        }
        
    } catch (Exception $e) {
        error_log("Error processing named range '$rangeName': " . $e->getMessage());
        return ['stop_data' => [], 'production_data' => []];
    }
    
    return [
        'stop_data' => $stopData,
        'production_data' => $productionData
    ];
}

function determineIfStopData($headers, $rowData) {
    // Check if this row has stop-related columns
    // Look for columns that indicate stop data (like stop_type, stop_duration, equipment)
    
    $stopIndicators = ['stop_type', 'stop_duration', 'equipment', 'توقف', 'مدت توقف', 'تجهیزات'];
    $productionIndicators = ['input_tonnage', 'belt_scale_output', 'service_count', 'تناژ ورودی', 'خروجی باسکول', 'تعداد سرویس'];
    
    $stopCount = 0;
    $productionCount = 0;
    
    // Check header names
    foreach ($headers as $header) {
        $headerLower = strtolower($header);
        foreach ($stopIndicators as $indicator) {
            if (strpos($headerLower, strtolower($indicator)) !== false) {
                $stopCount++;
            }
        }
        foreach ($productionIndicators as $indicator) {
            if (strpos($headerLower, strtolower($indicator)) !== false) {
                $productionCount++;
            }
        }
    }
    
    // Check data values for stop indicators
    foreach ($rowData as $cellValue) {
        if (!empty($cellValue)) {
            $cellLower = strtolower($cellValue);
            // Check if cell contains stop-related keywords
            if (strpos($cellLower, 'توقف') !== false || 
                strpos($cellLower, 'تعمیر') !== false || 
                strpos($cellLower, 'خرابی') !== false) {
                $stopCount++;
            }
        }
    }
    
    // If we have more stop indicators than production indicators, it's stop data
    return $stopCount > $productionCount;
}

function processStopRow($headers, $rowData) {
    $dateStr = null;
    $shift = '';
    $stopType = '';
    $stopDuration = 0;
    $equipment = '';
    $description = '';
    
    // Find date column
    $dateIndex = findColumnIndex($headers, ['تاریخ', 'date', 'روز']);
    if ($dateIndex !== -1 && isset($rowData[$dateIndex])) {
        $dateStr = convertExcelDate($rowData[$dateIndex]);
    }
    
    if (!$dateStr) return null;
    
    $date = new DateTime($dateStr);
    $year = (int)$date->format('Y');
    $month = (int)$date->format('m');
    $day = (int)$date->format('d');
    
    // Find other columns
    $shiftIndex = findColumnIndex($headers, ['شیفت', 'shift']);
    if ($shiftIndex !== -1 && isset($rowData[$shiftIndex])) {
        $shift = $rowData[$shiftIndex];
    }
    
    $stopTypeIndex = findColumnIndex($headers, ['نوع توقف', 'stop_type', 'توقف']);
    if ($stopTypeIndex !== -1 && isset($rowData[$stopTypeIndex])) {
        $stopType = $rowData[$stopTypeIndex];
    }
    
    $stopDurationIndex = findColumnIndex($headers, ['مدت توقف', 'stop_duration', 'زمان توقف']);
    if ($stopDurationIndex !== -1 && isset($rowData[$stopDurationIndex])) {
        $stopDuration = is_numeric($rowData[$stopDurationIndex]) ? (float)$rowData[$stopDurationIndex] : 0;
    }
    
    $equipmentIndex = findColumnIndex($headers, ['تجهیزات', 'equipment', 'ماشین']);
    if ($equipmentIndex !== -1 && isset($rowData[$equipmentIndex])) {
        $equipment = $rowData[$equipmentIndex];
    }
    
    $descriptionIndex = findColumnIndex($headers, ['توضیحات', 'description', 'شرح']);
    if ($descriptionIndex !== -1 && isset($rowData[$descriptionIndex])) {
        $description = $rowData[$descriptionIndex];
    }
    
    return [
        'year' => $year,
        'month' => $month,
        'day' => $day,
        'shift' => $shift,
        'stop_type' => $stopType,
        'stop_duration' => $stopDuration,
        'equipment' => $equipment,
        'description' => $description,
    ];
}

function processProductionRow($headers, $rowData) {
    $dateStr = null;
    $shift = '';
    $inputTonnage = 0;
    $beltScaleOutput = 0;
    $serviceCount = 0;
    
    // Find date column
    $dateIndex = findColumnIndex($headers, ['تاریخ', 'date', 'روز']);
    if ($dateIndex !== -1 && isset($rowData[$dateIndex])) {
        $dateStr = convertExcelDate($rowData[$dateIndex]);
    }
    
    if (!$dateStr) return null;
    
    $date = new DateTime($dateStr);
    $year = (int)$date->format('Y');
    $month = (int)$date->format('m');
    $day = (int)$date->format('d');
    
    // Find other columns
    $shiftIndex = findColumnIndex($headers, ['شیفت', 'shift']);
    if ($shiftIndex !== -1 && isset($rowData[$shiftIndex])) {
        $shift = $rowData[$shiftIndex];
    }
    
    $inputTonnageIndex = findColumnIndex($headers, ['تناژ ورودی', 'input_tonnage', 'ورودی']);
    if ($inputTonnageIndex !== -1 && isset($rowData[$inputTonnageIndex])) {
        $inputTonnage = is_numeric($rowData[$inputTonnageIndex]) ? (float)$rowData[$inputTonnageIndex] : 0;
    }
    
    $beltScaleOutputIndex = findColumnIndex($headers, ['خروجی باسکول', 'belt_scale_output', 'باسکول']);
    if ($beltScaleOutputIndex !== -1 && isset($rowData[$beltScaleOutputIndex])) {
        $beltScaleOutput = is_numeric($rowData[$beltScaleOutputIndex]) ? (float)$rowData[$beltScaleOutputIndex] : 0;
    }
    
    $serviceCountIndex = findColumnIndex($headers, ['تعداد سرویس', 'service_count', 'سرویس']);
    if ($serviceCountIndex !== -1 && isset($rowData[$serviceCountIndex])) {
        $serviceCount = is_numeric($rowData[$serviceCountIndex]) ? (float)$rowData[$serviceCountIndex] : 0;
    }
    
    return [
        'year' => $year,
        'month' => $month,
        'day' => $day,
        'shift' => $shift,
        'input_tonnage' => $inputTonnage,
        'belt_scale_output' => $beltScaleOutput,
        'service_count' => $serviceCount,
    ];
}

function findColumnIndex($headers, $possibleNames) {
    foreach ($possibleNames as $name) {
        for ($i = 0; $i < count($headers); $i++) {
            if (strtolower($headers[$i]) === strtolower($name)) {
                return $i;
            }
        }
    }
    return -1;
}

function processSheetFallback($spreadsheet, $sheetName) {
    $data = ['stop_data' => [], 'production_data' => []];
    
    // Fallback: process entire sheet (original method)
    $worksheet = $spreadsheet->getSheetByName($sheetName);
    if (!$worksheet) {
        return $data;
    }
    
    $highestRow = $worksheet->getHighestRow();
    $highestColumn = $worksheet->getHighestColumn();

    for ($row = 2; $row <= $highestRow; $row++) {
        $rowData = $worksheet->rangeToArray('A' . $row . ':' . $highestColumn . $row, null, true, false)[0];
        
        if (empty(array_filter($rowData))) continue;

        $dateStr = convertExcelDate($rowData[0]);
        if ($dateStr) {
            $date = new DateTime($dateStr);
            $year = (int)$date->format('Y');
            $month = (int)$date->format('m');
            $day = (int)$date->format('d');
        } else {
            continue;
        }

        // Determine if this is stop or production data based on column structure
        $isStopData = determineIfStopData(['تاریخ', 'شیفت', 'نوع', 'مدت', 'تجهیزات', 'توضیحات'], $rowData);
        
        if ($isStopData) {
            $stopDuration = is_numeric($rowData[3]) ? (float)$rowData[3] : 0;
            
            $data['stop_data'][] = [
                'year' => $year,
                'month' => $month,
                'day' => $day,
                'shift' => $rowData[1],
                'stop_type' => $rowData[2],
                'stop_duration' => $stopDuration,
                'equipment' => $rowData[4],
                'description' => $rowData[5] ?? '',
            ];
        } else {
            $inputTonnage = is_numeric($rowData[2]) ? (float)$rowData[2] : 0;
            $beltScaleOutput = is_numeric($rowData[3]) ? (float)$rowData[3] : 0;
            $serviceCount = is_numeric($rowData[4]) ? (float)$rowData[4] : 0;
            
            $data['production_data'][] = [
                'year' => $year,
                'month' => $month,
                'day' => $day,
                'shift' => $rowData[1],
                'input_tonnage' => $inputTonnage,
                'belt_scale_output' => $beltScaleOutput,
                'service_count' => $serviceCount,
            ];
        }
    }
    
    return $data;
}

function convertExcelToJson($filePath) {
    try {
        // Load the Excel file
        $spreadsheet = IOFactory::load($filePath);
        $worksheet = $spreadsheet->getActiveSheet();
        
        $data = [];
        $highestRow = $worksheet->getHighestRow();
        
        // Start from row 2 (assuming row 1 is header)
        for ($row = 2; $row <= $highestRow; $row++) {
            // Read all 23 columns from right to left
            $rowData = [];
            
            // ستون اول: تاریخ شمسی
            $shamsiDate = $worksheet->getCellByColumnAndRow(1, $row)->getValue();
            if (empty($shamsiDate)) continue; // Skip empty rows
            
            // ستون دوم: سال
            $year = $worksheet->getCellByColumnAndRow(2, $row)->getValue();
            
            // ستون سوم: ماه
            $month = $worksheet->getCellByColumnAndRow(3, $row)->getValue();
            
            // ستون چهارم: روز
            $day = $worksheet->getCellByColumnAndRow(4, $row)->getValue();
            
            // ستون پنجم: شیفت
            $shift = $worksheet->getCellByColumnAndRow(5, $row)->getValue();
            
            // ستون ششم: شرح توقف
            $stopDescription = $worksheet->getCellByColumnAndRow(6, $row)->getValue() ?? '';
            
            // ستون هفتم: نام تجهیزات
            $equipmentName = $worksheet->getCellByColumnAndRow(7, $row)->getValue() ?? '';
            
            // ستون هشتم: کد تجهیز 1
            $equipmentCode1 = $worksheet->getCellByColumnAndRow(8, $row)->getValue() ?? '';
            
            // ستون نهم: کد تجهیز 2
            $equipmentCode2 = $worksheet->getCellByColumnAndRow(9, $row)->getValue() ?? '';
            
            // ستون دهم: ریز تجهیزات
            $subEquipment = $worksheet->getCellByColumnAndRow(10, $row)->getValue() ?? '';
            
            // ستون یازدهم: کد ریز تجهیز
            $subEquipmentCode = $worksheet->getCellByColumnAndRow(11, $row)->getValue() ?? '';
            
            // ستون دوازدهم: علت توقف
            $stopReason = $worksheet->getCellByColumnAndRow(12, $row)->getValue() ?? '';
            
            // ستون سیزدهم: نوع توقف
            $stopType = $worksheet->getCellByColumnAndRow(13, $row)->getValue() ?? '';
            
            // ستون چهاردهم: شروع توقف
            $stopStartTime = $worksheet->getCellByColumnAndRow(14, $row)->getValue();
            if ($stopStartTime instanceof DateTime) {
                $stopStartTime = $stopStartTime->format('H:i');
            } else {
                $stopStartTime = $stopStartTime ?? '';
            }
            
            // ستون پانزدهم: پایان توقف
            $stopEndTime = $worksheet->getCellByColumnAndRow(15, $row)->getValue();
            if ($stopEndTime instanceof DateTime) {
                $stopEndTime = $stopEndTime->format('H:i');
            } else {
                $stopEndTime = $stopEndTime ?? '';
            }
            
            // ستون شانزدهم: مدت توقف
            $stopDuration = $worksheet->getCellByColumnAndRow(16, $row)->getValue();
            if ($stopDuration instanceof DateTime) {
                $stopDuration = $stopDuration->format('H:i');
            } else {
                $stopDuration = $stopDuration ?? '';
            }
            
            // ستون هفدهم: تعداد سرویس
            $serviceCount = $worksheet->getCellByColumnAndRow(17, $row)->getValue() ?? 0;
            
            // ستون هجدهم: تناژ ورودی
            $inputTonnage = $worksheet->getCellByColumnAndRow(18, $row)->getValue() ?? 0;
            
            // ستون نوزدهم: اسکیل 3
            $scale3 = $worksheet->getCellByColumnAndRow(19, $row)->getValue() ?? 0;
            
            // ستون بیستم: اسکیل 4
            $scale4 = $worksheet->getCellByColumnAndRow(20, $row)->getValue() ?? 0;
            
            // ستون بیست و یکم: اسکیل 5
            $scale5 = $worksheet->getCellByColumnAndRow(21, $row)->getValue() ?? 0;
            
            // ستون بیست و دوم: گروه
            $group = $worksheet->getCellByColumnAndRow(22, $row)->getValue() ?? 1;
            
            // ستون بیست و سوم: فید مستقیم
            $directFeed = $worksheet->getCellByColumnAndRow(23, $row)->getValue() ?? 0;
            
            // Validate required fields
            if (empty($year) || empty($month) || empty($day) || empty($shift)) {
                continue; // Skip invalid rows
            }
            
            $data[] = [
                'shamsi_date' => $shamsiDate,
                'year' => (int)$year,
                'month' => (int)$month,
                'day' => (int)$day,
                'shift' => (int)$shift,
                'stop_description' => $stopDescription,
                'equipment_name' => $equipmentName,
                'equipment_code_1' => $equipmentCode1,
                'equipment_code_2' => $equipmentCode2,
                'sub_equipment' => $subEquipment,
                'sub_equipment_code' => $subEquipmentCode,
                'stop_reason' => $stopReason,
                'stop_type' => $stopType,
                'stop_start_time' => $stopStartTime,
                'stop_end_time' => $stopEndTime,
                'stop_duration' => $stopDuration,
                'service_count' => (int)$serviceCount,
                'input_tonnage' => (float)$inputTonnage,
                'scale_3' => (float)$scale3,
                'scale_4' => (float)$scale4,
                'scale_5' => (float)$scale5,
                'group' => (int)$group,
                'direct_feed' => (int)$directFeed,
            ];
        }
        
        return [
            'success' => true,
            'data' => $data,
            'total_records' => count($data),
            'message' => 'داده‌ها با موفقیت تبدیل شدند'
        ];
        
    } catch (Exception $e) {
        return [
            'success' => false,
            'error' => 'خطا در پردازش فایل: ' . $e->getMessage(),
            'data' => []
        ];
    }
}

// Handle different request methods
$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    // Get Excel file path from query parameter or use default
    $excelFile = $_GET['file'] ?? 'production_data.xlsx';
    $filePath = __DIR__ . '/' . $excelFile;
    
    if (!file_exists($filePath)) {
        echo json_encode([
            'success' => false,
            'error' => 'فایل اکسل یافت نشد: ' . $excelFile,
            'data' => []
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    $result = convertExcelToJson($filePath);
    echo json_encode($result, JSON_UNESCAPED_UNICODE);
    
} elseif ($method === 'POST') {
    // Handle file upload
    if (isset($_FILES['excel_file'])) {
        $uploadedFile = $_FILES['excel_file'];
        
        if ($uploadedFile['error'] !== UPLOAD_ERR_OK) {
            echo json_encode([
                'success' => false,
                'error' => 'خطا در آپلود فایل: ' . $uploadedFile['error'],
                'data' => []
            ], JSON_UNESCAPED_UNICODE);
            exit;
        }
        
        // Validate file type
        $allowedTypes = [
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'application/vnd.ms-excel'
        ];
        
        if (!in_array($uploadedFile['type'], $allowedTypes)) {
            echo json_encode([
                'success' => false,
                'error' => 'نوع فایل نامعتبر است. فقط فایل‌های اکسل پذیرفته می‌شوند.',
                'data' => []
            ], JSON_UNESCAPED_UNICODE);
            exit;
        }
        
        $result = convertExcelToJson($uploadedFile['tmp_name']);
        echo json_encode($result, JSON_UNESCAPED_UNICODE);
        
    } else {
        echo json_encode([
            'success' => false,
            'error' => 'هیچ فایلی ارسال نشده است',
            'data' => []
        ], JSON_UNESCAPED_UNICODE);
    }
} else {
    echo json_encode([
        'success' => false,
        'error' => 'متد نامعتبر',
        'data' => []
    ], JSON_UNESCAPED_UNICODE);
} 