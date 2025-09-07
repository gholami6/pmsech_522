import pandas as pd
import numpy as np
from datetime import datetime, timedelta

def jalali_to_gregorian(year, month, day):
    """تبدیل تاریخ شمسی به میلادی - تقریبی"""
    # تقریب ساده برای تبدیل تاریخ
    gregorian_year = year + 621
    if month > 10:
        gregorian_year += 1
    return gregorian_year, month, day

def create_complete_grade_file():
    print("=== شروع ایجاد فایل کامل عیارها ===")
    
    # خواندن فایل فعلی
    try:
        df_current = pd.read_csv('real_grades.csv')
        print(f"فایل فعلی خوانده شد: {len(df_current)} رکورد")
    except Exception as e:
        print(f"خطا در خواندن فایل: {e}")
        return
    
    # محاسبه میانگین‌های ماهیانه از داده‌های موجود
    df_clean = df_current.dropna(subset=['میانگین عیار خوراک', 'میانگین عیار محصول', 'میانگین عیار باطله'], how='all')
    
    monthly_avg = df_clean.groupby(['ماه', 'سال']).agg({
        'میانگین عیار خوراک': 'mean',
        'میانگین عیار محصول': 'mean', 
        'میانگین عیار باطله': 'mean'
    }).reset_index()
    
    print("میانگین‌های ماهیانه محاسبه شده:")
    for _, row in monthly_avg.iterrows():
        print(f"  {row['سال']}/{row['ماه']:02d}: خوراک={row['میانگین عیار خوراک']:.2f}%, محصول={row['میانگین عیار محصول']:.2f}%, باطله={row['میانگین عیار باطله']:.2f}%")
    
    # میانگین کلی برای ماه‌های بدون داده
    overall_avg = df_clean[['میانگین عیار خوراک', 'میانگین عیار محصول', 'میانگین عیار باطله']].mean()
    print(f"\nمیانگین کلی: خوراک={overall_avg['میانگین عیار خوراک']:.2f}%, محصول={overall_avg['میانگین عیار محصول']:.2f}%, باطله={overall_avg['میانگین عیار باطله']:.2f}%")
    
    # ایجاد فهرست کامل روزها
    complete_data = []
    
    # تعریف روزهای هر ماه شمسی
    days_in_month = [31, 31, 31, 31, 31, 31, 30, 30, 30, 30, 30, 29]  # سال عادی
    month_names = ['فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور', 
                   'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند']
    
    print("\n=== ایجاد داده‌های کامل ===")
    
    # سال‌های مورد نیاز: 1402 تا 1404
    for year in range(1402, 1405):
        for month in range(1, 13):
            # بررسی محدودیت: فقط تا 10 تیر 1404
            if year == 1404 and month == 4:  # تیر ماه 1404
                max_day = 10
            elif year == 1404 and month > 4:  # بعد از تیر 1404
                break
            else:
                max_day = days_in_month[month - 1]
                # سال کبیسه
                if month == 12 and year % 4 == 2:  # اسفند سال کبیسه
                    max_day = 30
            
            print(f"پردازش {month_names[month-1]} {year} ({max_day} روز)")
            
            # پیدا کردن میانگین ماهیانه برای این ماه
            month_data = monthly_avg[(monthly_avg['سال'] == year) & (monthly_avg['ماه'] == month)]
            
            if not month_data.empty:
                # استفاده از میانگین ماهیانه
                avg_feed = month_data.iloc[0]['میانگین عیار خوراک']
                avg_product = month_data.iloc[0]['میانگین عیار محصول'] 
                avg_waste = month_data.iloc[0]['میانگین عیار باطله']
            else:
                # استفاده از میانگین کلی
                avg_feed = overall_avg['میانگین عیار خوراک']
                avg_product = overall_avg['میانگین عیار محصول']
                avg_waste = overall_avg['میانگین عیار باطله']
            
            # ایجاد رکورد برای هر روز
            for day in range(1, max_day + 1):
                # بررسی اینکه آیا داده واقعی وجود دارد
                existing_data = df_current[
                    (df_current['سال'] == year) & 
                    (df_current['ماه'] == month) & 
                    (df_current['روز '] == day)
                ]
                
                if not existing_data.empty and not pd.isna(existing_data.iloc[0]['میانگین عیار خوراک']):
                    # استفاده از داده واقعی
                    complete_data.append({
                        'روز ': day,
                        'ماه': month,
                        'سال ': year,
                        'میانگین عیار خوراک': existing_data.iloc[0]['میانگین عیار خوراک'],
                        'میانگین عیار محصول': existing_data.iloc[0]['میانگین عیار محصول'],
                        'میانگین عیار باطله ': existing_data.iloc[0]['میانگین عیار باطله ']
                    })
                else:
                    # استفاده از میانگین ماهیانه
                    complete_data.append({
                        'روز ': day,
                        'ماه': month,
                        'سال ': year,
                        'میانگین عیار خوراک': round(avg_feed, 2),
                        'میانگین عیار محصول': round(avg_product, 2),
                        'میانگین عیار باطله ': round(avg_waste, 2)
                    })
    
    # ایجاد DataFrame نهایی
    df_complete = pd.DataFrame(complete_data)
    
    print(f"\nتعداد کل رکوردهای ایجاد شده: {len(df_complete)}")
    print(f"از {df_complete.iloc[0]['سال ']}/{df_complete.iloc[0]['ماه']}/{df_complete.iloc[0]['روز ']} تا {df_complete.iloc[-1]['سال ']}/{df_complete.iloc[-1]['ماه']}/{df_complete.iloc[-1]['روز ']}")
    
    # ذخیره فایل
    df_complete.to_csv('real_grades_complete.csv', index=False)
    print("\nفایل کامل در real_grades_complete.csv ذخیره شد! ✅")
    
    # نمایش آمار
    print(f"\nآمار نهایی:")
    print(f"- تعداد کل روزها: {len(df_complete)}")
    print(f"- محدوده عیار خوراک: {df_complete['میانگین عیار خوراک'].min():.2f}% تا {df_complete['میانگین عیار خوراک'].max():.2f}%")
    print(f"- محدوده عیار محصول: {df_complete['میانگین عیار محصول'].min():.2f}% تا {df_complete['میانگین عیار محصول'].max():.2f}%")
    print(f"- محدوده عیار باطله: {df_complete['میانگین عیار باطله '].min():.2f}% تا {df_complete['میانگین عیار باطله '].max():.2f}%")

if __name__ == "__main__":
    create_complete_grade_file() 