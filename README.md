# 📱 تطبيق المريض — Patient App v5

---

## ✅ الإصلاحات في هذا الإصدار

| المشكلة | الحل |
|--------|------|
| `intl version solving failed` | رُفع إصدار intl إلى `^0.20.0` |
| `generate: true` بدون l10n.yaml | حُذف السطر من pubspec.yaml |
| `flutter_localizations` غير مستخدم | حُذف من التبعيات |
| هاتف أندرويد 11 لا يُكتشف | إضافة سكريبت التشخيص + تعليمات مفصلة |
| أذونات Android 11+ | تحديث AndroidManifest بأذونات `READ_MEDIA_*` |
| `file_picker` يحتاج FileProvider | إضافة `file_paths.xml` و provider في Manifest |

---

## ⚡ التشغيل السريع

```
انقر مزدوجاً على: SETUP_AND_RUN.bat
```

أو يدوياً:
```bash
flutter pub get
flutter run -d edge        # متصفح
flutter run -d android     # هاتف
```

---

## 📱 إصلاح عدم اكتشاف هاتف أندرويد 11

### الخطوة 1 — تفعيل خيارات المطور على الهاتف
1. اذهب إلى **الإعدادات ← حول الهاتف**
2. اضغط على **رقم الإصدار** (Build Number) **7 مرات** متتالية
3. ستظهر رسالة: *"أنت الآن مطور"*

### الخطوة 2 — تفعيل تصحيح USB
1. اذهب إلى **الإعدادات ← خيارات المطور**
2. فعّل **"تصحيح أخطاء USB"**

### الخطوة 3 — توصيل الكابل
1. وصّل الهاتف بالحاسوب بكابل USB (يفضل USB-A أو USB-C)
2. على الهاتف: اختر **"نقل الملفات (MTP)"** وليس "شحن فقط"
3. ستظهر نافذة على الهاتف: **"السماح بتصحيح USB؟"** → اضغط **السماح**
4. ضع علامة على **"السماح دائماً من هذا الحاسوب"**

### الخطوة 4 — تثبيت تعريف USB (Windows)
إذا لم يُكتشف الهاتف بعد الخطوات السابقة:
1. افتح **Device Manager** (مدير الأجهزة)
2. ابحث عن جهاز بعلامة ⚠️ أصفر
3. انقر بزر يمين → Update Driver
4. أو حمّل: [Google USB Driver](https://developer.android.com/studio/run/win-usb)

### الخطوة 5 — إعادة تشغيل ADB
شغّل **FIX_ANDROID_DETECTION.bat** أو:
```bash
adb kill-server
adb start-server
flutter devices
```

---

## ⚠️ قبل التشغيل

افتح `lib/utils/constants.dart` وغيّر:
```dart
static const String baseUrl = 'https://YOUR-PLATFORM-DOMAIN.com';
// للتطوير على محاكي أندرويد: 'http://10.0.2.2:3000'
// للتطوير على المتصفح:       'http://localhost:3000'
```
