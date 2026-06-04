@echo off
chcp 65001 > nul
echo.
echo ╔══════════════════════════════════════════════════════╗
echo ║     تشخيص وإصلاح: عدم اكتشاف هاتف أندرويد        ║
echo ╚══════════════════════════════════════════════════════╝
echo.

echo [الخطوة 1] إعادة تشغيل خادم ADB...
adb kill-server
timeout /t 2 /nobreak > nul
adb start-server
timeout /t 2 /nobreak > nul
echo.

echo [الخطوة 2] عرض الأجهزة المتصلة:
adb devices -l
echo.

echo [الخطوة 3] عرض أجهزة Flutter:
flutter devices
echo.

echo ══════════════════════════════════════════════════════
echo  إذا لم يظهر هاتفك، تحقق من الخطوات التالية:
echo ══════════════════════════════════════════════════════
echo.
echo  1. على هاتفك: الإعدادات → حول الهاتف
echo     اضغط على "رقم الإصدار" 7 مرات
echo     حتى يظهر "أنت الآن مطور"
echo.
echo  2. ادخل على: الإعدادات → خيارات المطور
echo     فعّل: "تصحيح أخطاء USB"
echo.
echo  3. افصل الكابل وأعد توصيله
echo     اختر على الهاتف: "نقل الملفات" أو "MTP"
echo     اقبل نافذة "السماح بتصحيح USB" على الهاتف
echo.
echo  4. إذا لم يعمل: ثبّت Google USB Driver:
echo     https://developer.android.com/studio/run/win-usb
echo.
echo  5. بعد التثبيت شغّل هذا السكريبت مجدداً
echo.
pause
