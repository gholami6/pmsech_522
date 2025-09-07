<?php
// غیرفعال کردن نمایش خطاها در خروجی
error_reporting(0);
ini_set('display_errors', 0);
ini_set('memory_limit', '1G'); // افزایش حافظه
ini_set('max_execution_time', 300); // 5 دقیقه timeout

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST');
header('Access-Control-Allow-Headers: Content-Type');

// خواندن CSV با trim کلیدها
class SimpleCsvReader {
    public function readCSV($filename, $maxRows = null) {
        if (!file_exists($filename)) {
            throw new Exception("فایل پیدا نشد: " . $filename);
        }
        $data = [];
        $headers = [];
        $handle = fopen($filename, 'r');
        if ($handle === false) {
            throw new Exception("خطا در باز کردن فایل: " . $filename);
        }
        $headers = fgetcsv($handle);
        // trim کلیدها (نام ستون‌ها) و حذف کاراکترهای نامرئی (BOM/RTL/ZWNJ) + حل مشکل ستون‌های تکراری
        $cleanHeaders = [];
        foreach ($headers as $index => $h) { 
            $cleanHeader = trim($h);
            // حذف کاراکترهای نامرئی محتمل در خروجی اکسل/CSV
            $cleanHeader = preg_replace('/^\xEF\xBB\xBF/u', '', $cleanHeader); // BOM
            $cleanHeader = preg_replace('/[\x{200E}\x{200F}\x{200C}\x{200D}]/u', '', $cleanHeader); // LRM/RLM/ZWNJ/ZWJ
            // اگر ستون تکراری بود، شماره اضافه کن
            if (in_array($cleanHeader, $cleanHeaders)) {
                $cleanHeader = $cleanHeader . '_' . ($index + 1);
            }
            $cleanHeaders[] = $cleanHeader;
        }
        
        $rowCount = 0;
        while (($row = fgetcsv($handle)) !== false) {
            // محدودیت تعداد ردیف‌ها برای جلوگیری از timeout
            if ($maxRows !== null && $rowCount >= $maxRows) {
                break;
            }
            
            $rowData = [];
            for ($i = 0; $i < count($cleanHeaders); $i++) {
                $val = isset($row[$i]) ? trim($row[$i]) : '';
                // حذف کاراکترهای نامرئی از مقادیر متنی زمان
                if (is_string($val)) {
                    $val = preg_replace('/[\x{200E}\x{200F}\x{200C}\x{200D}]/u', '', $val);
                }
                $rowData[$cleanHeaders[$i]] = $val;
            }
            $data[] = $rowData;
            $rowCount++;
        }
        fclose($handle);
        return $data;
    }
}

// داده‌های تولید
function getProductionData($data) {
    $production = [];
    foreach ($data as $row) {
        if (!empty($row['تناژ ورودی']) && is_numeric($row['تناژ ورودی'])) {
            $production[] = [
                'date' => $row['تاریخ'],
                'year' => intval($row['سال']),
                'month' => intval($row['ماه']),
                'day' => intval($row['روز']),
                'shift' => $row['شیفت'],
                'input_tonnage' => floatval($row['تناژ ورودی']),
                'equipment' => $row['تجهیز'],
                'equipment_code1' => isset($row['کد تجهیز ']) ? $row['کد تجهیز '] : '',
                'equipment_code2' => isset($row['کد تجهیز_9']) ? $row['کد تجهیز_9'] : '',
                'sub_equipment' => $row['ریز تجهیز'],
                'sub_equipment_code' => $row['کد ریز تجهیز'],
                'service_count' => isset($row['تعداد سرویس']) ? intval($row['تعداد سرویس']) : 0,
                'scale3' => isset($row['اسکیل 3']) ? floatval($row['اسکیل 3']) : 0,
                'scale4' => isset($row['اسکیل 4']) ? floatval($row['اسکیل 4']) : 0,
                'scale5' => isset($row['اسکیل 5']) ? floatval($row['اسکیل 5']) : 0,
                'group' => isset($row['گروه']) ? intval($row['گروه']) : 0,
                'direct_feed' => isset($row['فید مستقیم']) ? intval($row['فید مستقیم']) : 0,
            ];
        }
    }
    return $production;
}

// داده‌های توقف - بهینه‌سازی شده
function getStopData($rows) {
    $stops = [];
    $processedCount = 0;
    $maxProcessTime = 60; // افزایش سقف پردازش برای فایل‌های بزرگ
    $startTime = time();
    // حذف فیلترهای سال و ماه - همه داده‌ها پردازش شوند
    // $filterYear = isset($_GET['year']) ? intval($_GET['year']) : null;
    // $filterMonth = isset($_GET['month']) ? intval($_GET['month']) : null;
    
    // کمک‌تابع: تبدیل ارقام فارسی/عربی به لاتین
    $normalizeDigits = function($s){
        if ($s === null) return '';
        $map = [
            '۰'=>'0','۱'=>'1','۲'=>'2','۳'=>'3','۴'=>'4','۵'=>'5','۶'=>'6','۷'=>'7','۸'=>'8','۹'=>'9',
            '٠'=>'0','١'=>'1','٢'=>'2','٣'=>'3','٤'=>'4','٥'=>'5','٦'=>'6','٧'=>'7','٨'=>'8','٩'=>'9'
        ];
        return strtr((string)$s, $map);
    };

    foreach ($rows as $row) {
        // بررسی timeout
        if (time() - $startTime > $maxProcessTime) {
            error_log("⚠️ Timeout در پردازش توقفات - $processedCount ردیف پردازش شد");
            break;
        }
        
        // استخراج فیلدها
        $year = intval($normalizeDigits($row['سال'] ?? 0));
        $month = intval($normalizeDigits($row['ماه'] ?? 0));
        $day = intval($normalizeDigits($row['روز'] ?? 0));
        
        // حذف فیلترهای سال و ماه - همه داده‌ها پردازش شوند
        // if ($filterYear !== null && $year !== $filterYear) { $processedCount++; continue; }
        // if ($filterMonth !== null && $month !== $filterMonth) { $processedCount++; continue; }

        $stopType = $row['نوع توقف'] ?? $row['stop_type'] ?? '';
        $stopDurationRaw = $normalizeDigits($row['مدت توقف'] ?? $row['stop_duration'] ?? '');
        $startTimeStr = $normalizeDigits($row['شروع توقف'] ?? $row['stop_start'] ?? '');
        $endTimeStr = $normalizeDigits($row['پایان توقف'] ?? $row['stop_end'] ?? '');

        // تبدیل مدت توقف
        $minutes = convertDurationToMinutes($stopDurationRaw);
        if (($minutes === 0 || $minutes === null) && $startTimeStr !== '' && $endTimeStr !== '') {
            $toMin = function($t){ $p = explode(':', $t); $h=intval($p[0]??0); $m=intval($p[1]??0); return $h*60+$m; };
            $sm = $toMin($startTimeStr); $em = $toMin($endTimeStr);
            $minutes = ($em >= $sm) ? ($em - $sm) : (24*60 - $sm + $em);
        }

        // فقط ردیف‌های معتبر
        if (!empty($stopType) && $year>0 && $month>0 && $day>0 && $minutes>0) {
            $stops[] = [
                'date' => $row['تاریخ'] ?? '',
                'year' => $year,
                'month' => $month,
                'day' => $day,
                'shift' => $normalizeDigits($row['شیفت'] ?? ''),
                'equipment' => $row['تجهیز'] ?? '',
                'equipment_name' => $row['تجهیز'] ?? '',
                'equipment_code1' => $row['کد تجهیز '] ?? '',
                'equipment_code2' => $row['کد تجهیز'] ?? '',
                'sub_equipment' => $row['ریز تجهیز'] ?? '',
                'sub_equipment_code' => $row['کد ریز تجهیز'] ?? '',
                'stop_type' => $stopType,
                'stop_reason' => $row['علت توقف'] ?? $row['stop_reason'] ?? '',
                'stop_start' => $startTimeStr,
                'stop_end' => $endTimeStr,
                'stop_duration' => $minutes,
                'stop_description' => $row['شرح توقف'] ?? $row['stop_description'] ?? '',
                'service_count' => intval($row['تعداد سرویس'] ?? 0)
            ];
        }
        
        $processedCount++;
        
        // هیچ سقف سختی برای تعداد توقفات نگذار؛ اجازه بده تا زمان مجاز پردازش ادامه یابد
    }
    
    error_log("=== دیباگ توقفات ===");
    error_log("کل ردیف‌ها: " . count($rows));
    error_log("ردیف‌های پردازش شده: $processedCount");
    error_log("توقفات یافت شده: " . count($stops));
    error_log("زمان پردازش: " . (time() - $startTime) . " ثانیه");
    error_log("===================");
    
    return $stops;
}

// داده‌های شیفت - جدید
function getShiftData($data) {
    $shifts = [];
    $shiftMap = [];
    
    // دیباگ: بررسی ستون‌های موجود
    if (!empty($data)) {
        $firstRow = $data[0];
        error_log("=== دیباگ شیفت ===");
        error_log("ستون‌های موجود: " . implode(', ', array_keys($firstRow)));
        error_log("نمونه تاریخ: " . ($firstRow['تاریخ'] ?? 'خالی'));
        error_log("نمونه شیفت: " . ($firstRow['شیفت'] ?? 'خالی'));
        error_log("==========================");
    }
    
    foreach ($data as $row) {
        $date = $row['﻿تاریخ'] ?? $row['تاریخ'] ?? ''; // اصلاح برای کاراکتر نامرئی
        $shift = $row['شیفت'] ?? '';
        
        // هر ردیف که تاریخ یا شیفت داره رو اضافه کن
        if (!empty($date) && !empty($shift)) {
            $key = $date . '_' . $shift;
            if (!isset($shiftMap[$key])) {
                $shiftMap[$key] = [
                    'date' => $date,
                    'year' => intval($row['سال'] ?? 0),
                    'month' => intval($row['ماه'] ?? 0),
                    'day' => intval($row['روز'] ?? 0),
                    'shift' => $shift,
                    'equipment' => $row['تجهیز'] ?? '',
                    'equipment_code1' => $row['کد تجهیز'] ?? '',
                    'equipment_code2' => $row['کد تجهیز_9'] ?? '',
                    'sub_equipment' => $row['ریز تجهیز'] ?? '',
                    'sub_equipment_code' => $row['کد ریز تجهیز'] ?? '',
                ];
            }
        }
    }
    
    error_log("تعداد شیفت‌های یافت شده: " . count($shiftMap));
    return array_values($shiftMap);
}

// تابع جدید برای تبدیل مدت توقفات به دقیقه (عدد)
function convertDurationToMinutes($duration) {
    // اگر خالی یا صفر باشد
    if (empty($duration) || $duration == '0') {
        return 0;
    }
    
    // اگر قبلاً فرمت hh:mm است، تبدیل به دقیقه
    if (strpos($duration, ':') !== false) {
        $parts = explode(':', $duration);
        if (count($parts) == 2) {
            $hours = intval($parts[0]);
            $minutes = intval($parts[1]);
            return ($hours * 60) + $minutes;
        }
    }
    
    // اگر عدد است، مستقیماً برگردان
    return intval($duration);
}

// تابع قدیمی برای تبدیل به فرمت hh:mm (حفظ شده)
function convertDurationToHHMM($duration) {
    // اگر خالی یا صفر باشد
    if (empty($duration) || $duration == '0') {
        return '00:00';
    }
    
    // اگر قبلاً فرمت hh:mm است، همان را برگردان
    if (strpos($duration, ':') !== false) {
        return $duration;
    }
    
    // تبدیل عدد به دقیقه
    $minutes = intval($duration);
    
    // تبدیل به فرمت hh:mm
    $hours = intval($minutes / 60);
    $remainingMinutes = $minutes % 60;
    
    return sprintf('%02d:%02d', $hours, $remainingMinutes);
}

// داده‌های تجهیزات (لیست یکتا)
function getEquipmentData($data) {
    $equipment = [];
    $equipmentMap = [];
    foreach ($data as $row) {
        $name = $row['تجهیز'];
        if (!empty($name) && !isset($equipmentMap[$name])) {
            $equipmentMap[$name] = [
                'name' => $name,
                'equipment_code1' => isset($row['کد تجهیز ']) ? $row['کد تجهیز '] : '',
                'equipment_code2' => isset($row['کد تجهیز_9']) ? $row['کد تجهیز_9'] : '',
                'sub_equipment' => $row['ریز تجهیز'],
                'sub_equipment_code' => $row['کد ریز تجهیز'],
            ];
        }
    }
    return array_values($equipmentMap);
}

try {
    // انتخاب فایل بر اساس نوع
    $type = isset($_GET['type']) ? $_GET['type'] : 'all';
    
    // همه چیز از production_data.csv
    $filename = 'production_data.csv';
    
    // اگر فایل خاصی درخواست شده
    if (isset($_GET['file'])) {
        $filename = $_GET['file'];
    }
    
    // اضافه کردن حالت debug
    $debug = isset($_GET['debug']) ? $_GET['debug'] : false;
    
    if ($debug === 'csv') {
        // نمایش اطلاعات فایل CSV
        $fileInfo = [
            'current_directory' => getcwd(),
            'files_in_directory' => scandir('.'),
            'requested_file' => $filename,
            'file_exists' => file_exists($filename),
            'file_size' => file_exists($filename) ? filesize($filename) : 0,
            'file_permissions' => file_exists($filename) ? substr(sprintf('%o', fileperms($filename)), -4) : 'N/A'
        ];
        
        echo json_encode([
            'success' => true,
            'debug_info' => $fileInfo,
            'timestamp' => date('Y-m-d H:i:s')
        ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
        exit;
    }
    
    if ($debug === 'columns') {
        // نمایش ستون‌های CSV
        if (file_exists($filename)) {
            try {
                $reader = new SimpleCsvReader();
                $data = $reader->readCSV($filename, 1000); // محدود به 1000 ردیف
                
                if (!empty($data)) {
                    $firstRow = $data[0];
                    $columns = array_keys($firstRow);
                    
                    echo json_encode([
                        'success' => true,
                        'columns' => $columns,
                        'total_rows' => count($data),
                        'sample_row' => $firstRow,
                        'timestamp' => date('Y-m-d H:i:s')
                    ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
                } else {
                    echo json_encode([
                        'success' => false,
                        'error' => 'فایل CSV خالی است',
                        'timestamp' => date('Y-m-d H:i:s')
                    ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
                }
            } catch (Exception $e) {
                echo json_encode([
                    'success' => false,
                    'error' => 'خطا در خواندن فایل: ' . $e->getMessage(),
                    'timestamp' => date('Y-m-d H:i:s')
                ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
            }
        } else {
            echo json_encode([
                'success' => false,
                'error' => 'فایل CSV یافت نشد: ' . $filename,
                'current_dir' => getcwd(),
                'files' => scandir('.'),
                'timestamp' => date('Y-m-d H:i:s')
            ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
        }
        exit;
    }

    if (!file_exists($filename)) {
        // اگر فایل اصلی وجود نداشت، خطا برگردان
        echo json_encode([
            'success' => false,
            'error' => 'فایل CSV یافت نشد: ' . $filename,
            'message' => 'لطفاً فایل production_data.csv را در هاست آپلود کنید.',
            'timestamp' => date('Y-m-d H:i:s'),
            'debug_info' => [
                'current_directory' => getcwd(),
                'files_in_directory' => scandir('.'),
                'requested_file' => $filename
            ]
        ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
        exit;
    }

    $reader = new SimpleCsvReader();
    
    // بدون محدودیت ردیف؛ کنترل با time budget انجام می‌شود
    $maxRows = null;
    
    $data = $reader->readCSV($filename, $maxRows);

    if (empty($data)) {
        throw new Exception("فایل CSV خالی است یا ساختار صحیحی ندارد");
    }

    // دیباگ: نمایش ستون‌های موجود
    if (!empty($data)) {
        $firstRow = $data[0];
        error_log("=== دیباگ ستون‌های CSV ===");
        error_log("ستون‌های موجود: " . implode(', ', array_keys($firstRow)));
        error_log("تعداد کل ردیف‌ها: " . count($data));
        
        // بررسی ستون‌های توقف
        $stopColumns = ['نوع توقف', 'مدت توقف', 'علت توقف', 'شروع توقف', 'پایان توقف', 'شرح توقف'];
        foreach ($stopColumns as $col) {
            $hasColumn = array_key_exists($col, $firstRow);
            $sampleValue = $hasColumn ? $firstRow[$col] : 'N/A';
            error_log("ستون '$col': " . ($hasColumn ? 'موجود' : 'غیرموجود') . " (نمونه: $sampleValue)");
        }
        error_log("==========================");
    }

    $result = [];
    switch ($type) {
        case 'production':
            $result = getProductionData($data);
            break;
        case 'stops':
            $result = getStopData($data);
            break;
        case 'equipment':
            $result = getEquipmentData($data);
            break;
        case 'shift':
            $result = getShiftData($data);
            break;
        default:
            $productionData = getProductionData($data);
            $stopData = getStopData($data);
            $equipmentData = getEquipmentData($data);
            $shiftData = getShiftData($data);
            
            // لاگ برای دیباگ
            error_log("=== دیباگ API ===");
            error_log("کل ردیف‌ها: " . count($data));
            error_log("تولید: " . count($productionData));
            error_log("توقف: " . count($stopData));
            error_log("تجهیزات: " . count($equipmentData));
            error_log("شیفت: " . count($shiftData));
            error_log("==================");
            
            $result = [
                'production' => $productionData,
                'stops' => $stopData,
                'equipment' => $equipmentData,
                'shift' => $shiftData
            ];
    }

    echo json_encode([
        'success' => true,
        'data' => $result,
        'timestamp' => date('Y-m-d H:i:s'),
        'count' => is_array($result) ? count($result) : 0,
        'file_used' => $filename,
        'total_rows' => count($data),
        'max_rows_processed' => $maxRows
    ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage(),
        'timestamp' => date('Y-m-d H:i:s'),
        'debug_info' => [
            'current_directory' => getcwd(),
            'files_in_directory' => scandir('.'),
            'requested_file' => isset($filename) ? $filename : 'نامشخص'
        ]
    ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
}
?> 