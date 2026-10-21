#!/bin/bash

echo "شروع آپدیت..."
git pull origin main --allow-unrelated-histories --no-edit
git add .
git commit -m "آپدیت کلی پروژه"
git push origin main

# بررسی اینکه آیا پوش واقعا موفق بوده است یا خیر
if [ $? -eq 0 ]; then
    echo "✅ آپلود با موفقیت انجام شد."
else
    echo "❌ خطا در آپلود! لطفا متن خطای بالا را بررسی کنید."
fi