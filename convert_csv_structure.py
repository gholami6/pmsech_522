#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
تبدیل ساختار فایل CSV از فرمت فعلی به فرمت مورد انتظار API
"""

import csv
import uuid
from datetime import datetime

def convert_csv_structure():
    """تبدیل ساختار فایل CSV"""
    
    input_file = 'assets/real_grades.csv'
    output_file = 'assets/real_grades_converted.csv'
    
    # خواندن فایل ورودی
    with open(input_file, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        rows = list(reader)
    
    # حذف هدر
    header = rows[0]
    data_rows = rows[1:]
    
    # ایجاد فایل خروجی با ساختار جدید
    with open(output_file, 'w', encoding='utf-8', newline='') as f:
        writer = csv.writer(f)
        
        # نوشتن هدر جدید
        new_header = ['id', 'date', 'shift', 'grade_type', 'grade_value', 'user_id', 'created_at', 'updated_at']
        writer.writerow(new_header)
        
        # تبدیل داده‌ها
        for row in data_rows:
            if len(row) >= 6:  # اطمینان از وجود حداقل 6 ستون
                day = row[0].strip()
                month = row[1].strip()
                year = row[2].strip()
                feed_grade = row[3].strip()
                product_grade = row[4].strip()
                tailing_grade = row[5].strip()
                
                # تبدیل تاریخ
                date_str = f"{year}/{month.zfill(2)}/{day.zfill(2)}"
                current_time = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                
                # ایجاد رکورد برای هر نوع عیار (اگر مقدار وجود داشته باشد)
                for shift in [1, 2, 3]:  # سه شیفت
                    # عیار خوراک
                    if feed_grade and feed_grade.strip():
                        try:
                            feed_value = float(feed_grade)
                            if 0 <= feed_value <= 100:
                                writer.writerow([
                                    str(uuid.uuid4()),  # id
                                    date_str,           # date
                                    shift,              # shift
                                    'خوراک',           # grade_type
                                    feed_value,         # grade_value
                                    'system',           # user_id
                                    current_time,       # created_at
                                    current_time        # updated_at
                                ])
                        except ValueError:
                            pass
                    
                    # عیار محصول
                    if product_grade and product_grade.strip():
                        try:
                            product_value = float(product_grade)
                            if 0 <= product_value <= 100:
                                writer.writerow([
                                    str(uuid.uuid4()),  # id
                                    date_str,           # date
                                    shift,              # shift
                                    'محصول',           # grade_type
                                    product_value,      # grade_value
                                    'system',           # user_id
                                    current_time,       # created_at
                                    current_time        # updated_at
                                ])
                        except ValueError:
                            pass
                    
                    # عیار باطله
                    if tailing_grade and tailing_grade.strip():
                        try:
                            tailing_value = float(tailing_grade)
                            if 0 <= tailing_value <= 100:
                                writer.writerow([
                                    str(uuid.uuid4()),  # id
                                    date_str,           # date
                                    shift,              # shift
                                    'باطله',           # grade_type
                                    tailing_value,      # grade_value
                                    'system',           # user_id
                                    current_time,       # created_at
                                    current_time        # updated_at
                                ])
                        except ValueError:
                            pass
    
    print(f"فایل تبدیل شده در {output_file} ذخیره شد")
    print("حالا این فایل را جایگزین فایل اصلی کنید")

if __name__ == "__main__":
    convert_csv_structure() 