import pandas as pd
import numpy as np

try:
    # خواندن فایل CSV
    df = pd.read_csv('real_grades.csv')
    
    print('=== تحلیل داده‌های عیار ===')
    print(f'تعداد کل رکوردها: {len(df)}')
    
    # حذف ردیف‌های خالی
    df_clean = df.dropna(subset=['میانگین عیار خوراک', 'میانگین عیار محصول', 'میانگین عیار باطله'], how='all')
    print(f'تعداد رکوردهای دارای داده: {len(df_clean)}')
    
    # محاسبه میانگین ماهیانه برای هر نوع عیار
    monthly_avg = df_clean.groupby(['ماه', 'سال']).agg({
        'میانگین عیار خوراک': 'mean',
        'میانگین عیار محصول': 'mean', 
        'میانگین عیار باطله': 'mean'
    }).reset_index()
    
    print('\n=== میانگین ماهیانه عیارها ===')
    for _, row in monthly_avg.iterrows():
        print(f'{row["سال"]}/{row["ماه"]:02d}: خوراک={row["میانگین عیار خوراک"]:.2f}%, محصول={row["میانگین عیار محصول"]:.2f}%, باطله={row["میانگین عیار باطله"]:.2f}%')
    
    # میانگین کلی برای ماه‌های بدون داده
    overall_avg = df_clean[['میانگین عیار خوراک', 'میانگین عیار محصول', 'میانگین عیار باطله']].mean()
    print(f'\n=== میانگین کلی ===')
    print(f'خوراک: {overall_avg["میانگین عیار خوراک"]:.2f}%')
    print(f'محصول: {overall_avg["میانگین عیار محصول"]:.2f}%')
    print(f'باطله: {overall_avg["میانگین عیار باطله"]:.2f}%')
    
    # ذخیره میانگین‌های ماهیانه
    monthly_avg.to_csv('monthly_averages.csv', index=False)
    print('\nمیانگین‌های ماهیانه در فایل monthly_averages.csv ذخیره شد.')
    
except Exception as e:
    print(f'خطا: {e}')
    print('مشکل در خواندن یا پردازش فایل CSV') 