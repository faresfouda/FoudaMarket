#!/bin/bash

# سكريبت نشر التطبيق على Vercel
# Deploy script for Vercel

echo "🚀 بدء عملية النشر على Vercel..."
echo "🚀 Starting Vercel deployment..."

# التأكد من وجود Flutter
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter غير مثبت. يرجى تثبيت Flutter أولاً"
    echo "❌ Flutter is not installed. Please install Flutter first"
    exit 1
fi

# تنظيف المشروع
echo "🧹 تنظيف المشروع..."
flutter clean

# جلب التبعيات
echo "📦 جلب التبعيات..."
flutter pub get

# بناء التطبيق للويب
echo "🔨 بناء التطبيق للويب..."
flutter build web --release --web-renderer canvaskit --base-href "/"

# التحقق من نجاح البناء
if [ ! -d "build/web" ]; then
    echo "❌ فشل في بناء التطبيق"
    echo "❌ Failed to build the app"
    exit 1
fi

# نسخ الملفات إلى مجلد web
echo "📋 نسخ الملفات المبنية..."
rm -rf web/build
cp -r build/web/* web/

# التأكد من وجود ملفات Firebase
if [ ! -f "web/firebase-messaging-sw.js" ]; then
    echo "⚠️  تحذير: ملف firebase-messaging-sw.js غير موجود"
fi

# التحقق من ملف manifest.json
if [ ! -f "web/manifest.json" ]; then
    echo "❌ ملف manifest.json غير موجود"
    exit 1
fi

# نشر على Vercel
echo "🚀 نشر على Vercel..."
if command -v vercel &> /dev/null; then
    vercel --prod
else
    echo "⚠️  Vercel CLI غير مثبت. يرجى تثبيته أولاً:"
    echo "npm i -g vercel"
    echo "أو ارفع المجلد web/ يدوياً على Vercel"
fi

echo "✅ تم الانتهاء من عملية النشر!"
echo "✅ Deployment completed!"
