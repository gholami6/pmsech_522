#!/usr/bin/env python3
"""
اسکریپت برای تغییر همه borderRadius ها به 24 پیکسل
"""

import os
import re

def update_border_radius_in_file(file_path):
    """تغییر borderRadius در یک فایل"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # تغییر borderRadius: 12 به borderRadius: 24
        content = re.sub(
            r'borderRadius:\s*BorderRadius\.circular\(12\)',
            'borderRadius: BorderRadius.circular(24)',
            content
        )
        
        # تغییر borderRadius: 16 به borderRadius: 24
        content = re.sub(
            r'borderRadius:\s*BorderRadius\.circular\(16\)',
            'borderRadius: BorderRadius.circular(24)',
            content
        )
        
        # تغییر Radius.circular(12) به Radius.circular(24)
        content = re.sub(
            r'Radius\.circular\(12\)',
            'Radius.circular(24)',
            content
        )
        
        # تغییر Radius.circular(16) به Radius.circular(24)
        content = re.sub(
            r'Radius\.circular\(16\)',
            'Radius.circular(24)',
            content
        )
        
        # ذخیره فایل
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
            
        return True
    except Exception as e:
        print(f"خطا در فایل {file_path}: {e}")
        return False

def find_dart_files(directory):
    """یافتن همه فایل‌های .dart"""
    dart_files = []
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                dart_files.append(os.path.join(root, file))
    return dart_files

def main():
    # مسیر پروژه
    project_path = "lib"
    
    # یافتن همه فایل‌های .dart
    dart_files = find_dart_files(project_path)
    
    print(f"تعداد فایل‌های .dart یافت شده: {len(dart_files)}")
    
    updated_count = 0
    error_count = 0
    
    for file_path in dart_files:
        print(f"در حال پردازش: {file_path}")
        if update_border_radius_in_file(file_path):
            updated_count += 1
        else:
            error_count += 1
    
    print(f"\n=== نتیجه ===")
    print(f"فایل‌های به‌روزرسانی شده: {updated_count}")
    print(f"فایل‌های با خطا: {error_count}")
    print(f"کل فایل‌ها: {len(dart_files)}")

if __name__ == "__main__":
    main()
