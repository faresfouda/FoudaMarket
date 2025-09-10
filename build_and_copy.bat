@echo off
echo "تنظيف المشروع..."
flutter clean

echo "جلب التبعيات..."
flutter pub get

echo "بناء التطبيق للويب..."
flutter build web --release --base-href "/"

echo "نسخ الملفات المبنية إلى مجلد web..."
xcopy /E /I /Y "build\web\*" "web\"

echo "تم الانتهاء! يمكنك الآن رفع المشروع على Vercel"
pause
