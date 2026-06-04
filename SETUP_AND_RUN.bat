@echo off
chcp 65001 > nul
echo.
echo ╔══════════════════════════════════════════════════════╗
echo ║          إعداد وتشغيل تطبيق المريض                 ║
echo ╚══════════════════════════════════════════════════════╝
echo.

echo [1/3] تثبيت الحزم (pub get)...
flutter pub get
if %errorlevel% neq 0 (
    echo.
    echo ✗ فشل pub get. تحقق من اتصال الإنترنت.
    pause
    exit /b 1
)
echo ✓ تم تثبيت الحزم
echo.

echo [2/3] التحقق من البيئة...
flutter doctor --android-licenses 2>nul
echo.

echo [3/3] عرض الأجهزة المتاحة...
adb kill-server 2>nul
adb start-server 2>nul
timeout /t 1 /nobreak > nul
flutter devices
echo.

echo ══════════════════════════════════════════════════════
echo  اختر طريقة التشغيل:
echo ══════════════════════════════════════════════════════
echo  [1] تشغيل على المتصفح Edge
echo  [2] تشغيل على هاتف أندرويد
echo  [3] خروج
echo.
set /p choice="اختيارك (1/2/3): "

if "%choice%"=="1" (
    echo.
    echo ► تشغيل على Edge...
    flutter run -d edge
) else if "%choice%"=="2" (
    echo.
    echo ► تشغيل على أندرويد...
    echo   تأكد أن الهاتف متصل وتصحيح USB مفعّل
    flutter run -d android
    if %errorlevel% neq 0 (
        echo.
        echo ✗ تعذّر الاتصال بالهاتف.
        echo   شغّل FIX_ANDROID_DETECTION.bat للتشخيص
    )
) else (
    exit /b 0
)

pause
