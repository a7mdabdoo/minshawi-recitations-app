# جامع تلاوات المنشاوي
### Al-Minshawi Quran Recitations App

تطبيق قرآني شامل لتلاوات الشيخ محمد صديق المنشاوي (رحمه الله) مبني باستخدام Flutter.  
*A comprehensive Quranic recitation application for Sheikh Muhammad Siddiq Al-Minshawi, built with Flutter.*

---

## إهداء وصدقة جارية | Dedication

> قال رسول الله ﷺ:  
> «إِذَا مَاتَ الإنْسَانُ انْقَطَعَ عَنْهُ عَمَلُهُ إِلَّا مِنْ ثَلَاثَةٍ: إِلَّا مِنْ صَدَقَةٍ جَارِيَةٍ، أَوْ عِلْمٍ يُنْتَفَعُ بِهِ، أَوْ وَلَدٍ صَالِحٍ يَدْعُو لَهُ» (رواه مسلم)

هذا العمل صَدَقَةٌ جَارِيَةٌ:
- عن روح والدتي رحمها الله تعالى وأسكنها الفردوس الأعلى من الجنة.
- وبراً بوالدي حفظه الله تعالى ورعاه وأطال في عمره على طاعته وصالح عمله.
- وعن نفسي، وعن فضيلة الشيخ محمد صديق المنشاوي، وعن كل من ساهم في نشره أو انتفع بالاستماع إليه.

نسأل الله العلي القدير أن يتقبل هذا العمل خالصاً لوجهه الكريم، وأن يجعله نوراً وأجراً مضاعفاً لا ينقطع.

---

## نبذة عن المشروع | Overview

### العربية
تطبيق "جامع تلاوات المنشاوي" هو تطبيق مفتوح المصدر يهدف إلى توفير وصول سلس وموثوق إلى التراث الصوتي لفضيلة القارئ الشيخ محمد صديق المنشاوي. يضم التطبيق المصحف المرتل كاملاً، والمصحف المجود كاملاً، بالإضافة إلى تسجيلات عام 1387 هـ الخارجية النادرة، مع مراعاة أحدث معايير الأداء وتصميم واجهات المستخدم المتجاوبة.

### English
Al-Minshawi Quran Recitations is an open-source mobile application designed to deliver seamless, high-fidelity access to the recorded audio legacy of the prominent Egyptian reciter Sheikh Muhammad Siddiq Al-Minshawi. The application includes his complete Murattal recitation, complete Mujawwad recitation, and rare external recordings from 1387 AH (1967-1968), engineered for smooth performance and responsive user experience.

---

## الخصائص التقنية والوظيفية | Key Features

- **الاستماع والتحميل دون اتصال (Offline Playback & Downloading):** إمكانية تحميل السور في الذاكرة المحلية للجهاز مع إدارة تلقائية للمساحة التخزينية.
- **خدمة تشغيل الخلفية والتحكم بالنظام (Background Audio Service):** تكامل كامل مع خدمات تشغيل الوسائط في نظام التشغيل وإشعارات شاشة القفل (just_audio و audio_service).
- **قوائم التشغيل والمفضلة (Custom Playlists & Bookmarks):** إدارة قوائم التشغيل المخصصة، وإضافة المقاطع إلى المفضلة، مع إمكانية التشغيل التتابعي.
- **أوضاع التكرار وتكرار المقاطع (Repeat Modes & A-B Looping):** دعم تكرار السورة، تكرار القائمة، التشغيل العشوائي، وتحديد مقطع بين نقطتين للتكرار بغرض الحفظ والمراجعة.
- **مؤقت النوم التدريجي (Smart Sleep Timer):** إيقاف التشغيل تلقائياً بعد فترة زمنية محددة مع خفض تدريجي للصوت أو عند نهاية السورة الحالية.
- **تحسينات الأداء ومعدل الإطارات (Performance Optimizations):** اعتماد تقنيات RepaintBoundary وتحديثات الحالة الموضعية عبر BLoC لضمان معدل تحديث ثابت وسلس (60/120 FPS).
- **تصميم متناسق ودعم الوضع الداكن (Dark & Light Theme Support):** واجهة مستخدم إسلامية رصينة تدعم الوضعين الفاتح والداكن ومصممة خصيصاً للغة العربية وقواعد خط المصحف.

---

## البنية البرمجية والتقنيات المستخدمة | Tech Stack & Architecture

- **إطار العمل (Framework):** Flutter (v3.29+)
- **لغة البرمجة (Language):** Dart (v3.7+)
- **نمط التصميم (Architecture):** Clean Architecture (Presentation, Domain, Data Layers)
- **إدارة الحالة (State Management):** BLoC / Cubit (flutter_bloc)
- **قواعد البيانات والتخزين المحلي (Local Storage):** Hive (hive_flutter)
- **محرك الصوتيات (Audio Engine):** just_audio, audio_service, just_audio_background
- **إدارة الشبكة والتحميل (Networking):** Dio (dio)
- **الخطوط والطباعة (Typography):** Amiri & Cairo

---

## هيكل المجلدات | Directory Structure

```
lib/
├── core/
│   ├── constants/              # App themes, colors, API endpoints, manifests
│   ├── di/                     # Dependency injection (GetIt service locator)
│   ├── errors/                 # Failures and custom exceptions
│   ├── network/                # Dio client configuration
│   ├── router/                 # Navigation routing
│   ├── services/               # Audio, storage, and download services
│   ├── settings/               # User settings and playback persistence
│   ├── theme/                  # Theme modes and configuration
│   └── utils/                  # Text normalizers and formatters
├── features/
│   ├── downloads/              # Download manager and storage views
│   ├── favorites/              # Saved favorites collection
│   ├── player/                 # MiniPlayer, audio controller, sleep timer
│   ├── playlists/              # Custom user playlists
│   └── recitations/            # Collections, surah listing, landing and home pages
└── main.dart                   # Application entry point
```

---

## التثبيت والتشغيل | Installation & Setup

### المتطلبات الأساسية (Prerequisites)
- Flutter SDK (الإصدار 3.5.0 أو أحدث)
- Android Studio أو VS Code مع حزم أدوات Flutter و Dart
- جهاز Android حقيقي أو محاكي (Android Emulator)

### خطوات التشغيل (Setup Commands)

1. استنساخ المستودع (Clone repository):
   ```bash
   git clone https://github.com/a7mdabdoo/minshawi-recitations-app.git
   cd minshawi-recitations-app
   ```

2. تثبيت الحزم البرمجية (Install dependencies):
   ```bash
   flutter pub get
   ```

3. تشغيل الاختبارات (Run tests):
   ```bash
   flutter test
   ```

4. تشغيل التطبيق في بيئة التطوير (Run app):
   ```bash
   flutter run
   ```

5. بناء حزمة الإنتاج (Build release APK):
   ```bash
   flutter build apk --release
   ```

---

## الترخيص | License

هذا المشروع متاح بموجب ترخيص [MIT License](LICENSE).
