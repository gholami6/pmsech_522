#!/usr/bin/env bash
set -e
cd /var/www/html
cp -a grade_api.php grade_api.php.bak_$(date +%F_%H-%M) 2>/dev/null || true
if [ -f real_grades.csv ]; then tail -n +2 real_grades.csv > body.tmp; fi
printf '%s\n' 'روز,ماه,سال,میانگین عیار خوراک,میانگین عیار محصول,میانگین عیار باطله' > real_grades.csv
if [ -f body.tmp ]; then cat body.tmp >> real_grades.csv; rm -f body.tmp; fi
chmod 644 grade_api.php
chmod 666 real_grades.csv
mkdir -p backups
chmod 775 . backups
