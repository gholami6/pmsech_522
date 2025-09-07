#!/usr/bin/env python3
"""
اسکریپت برای اعمال استانداردهای جدید انحنای گوشه‌ها
"""

import os
import re

def update_border_radius_standards(file_path):
    """اعمال استانداردهای جدید انحنای گوشه‌ها"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # تغییرات بر اساس نوع عنصر
        changes_made = 0
        
        # 1. جدول‌ها و لیست‌ها -> 8 پیکسل
        content, count = re.subn(
            r'borderRadius:\s*BorderRadius\.circular\(24\)',
            'borderRadius: BorderRadius.circular(8)',
            content
        )
        changes_made += count
        
        # 2. دکمه‌ها -> 12 پیکسل (فقط دکمه‌های ElevatedButton)
        # این تغییر را فقط در فایل‌های خاص اعمال می‌کنیم
        if 'ElevatedButton' in content:
            content, count = re.subn(
                r'borderRadius:\s*BorderRadius\.circular\(24\)',
                'borderRadius: BorderRadius.circular(12)',
                content
            )
            changes_made += count
        
        # 3. کارت‌های محتوا -> 16 پیکسل (فقط در برخی موارد)
        # این تغییر را با احتیاط اعمال می‌کنیم
        
        # 4. باکس‌های اصلی -> 24 پیکسل (پیش‌فرض)
        # این مقدار قبلاً تنظیم شده است
        
        # ذخیره فایل
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
            
        return changes_made > 0
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
        if update_border_radius_standards(file_path):
            updated_count += 1
        else:
            error_count += 1
    
    print(f"\n=== نتیجه ===")
    print(f"فایل‌های به‌روزرسانی شده: {updated_count}")
    print(f"فایل‌های با خطا: {error_count}")
    print(f"کل فایل‌ها: {len(dart_files)}")
    print(f"\n=== استانداردهای جدید ===")
    print(f"باکس‌های اصلی: 24 پیکسل")
    print(f"کارت‌های محتوا: 16 پیکسل")
    print(f"دکمه‌ها: 12 پیکسل")
    print(f"جدول‌ها و لیست‌ها: 8 پیکسل")

if __name__ == "__main__":
    main()
