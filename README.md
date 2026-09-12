<div align="center">

# 📖 جامع تلاوات المنشاوي
### Al-Minshawi Quran Recitations App

**تطبيق إسلامي قرآني شامل يجمع تراث الشيخ القارئ محمد صديق المنشاوي (رحمه الله)**  
*A comprehensive Flutter application dedicated to the recitations of Sheikh Muhammad Siddiq Al-Minshawi (May Allah have mercy upon him).*

[![Flutter](https://img.shields.io/badge/Flutter-3.5+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.5+-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20Architecture%20%2B%20BLoC-blue?style=for-the-badge)](https://bloclibrary.dev)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

</div>

---

## 🕊️ صدقة جارية (Ongoing Charity)

> قال رسول الله ﷺ: **«إِذَا مَاتَ ابْنُ آدَمَ انْقَطَعَ عَمَلُهُ إِلا مِنْ ثَلاثٍ: صَدَقَةٍ جَارِيَةٍ، أَوْ عِلْمٍ يُنْتَفَعُ بِهِ، أَوْ وَلَدٍ صَالِحٍ يَدْعُو لَهُ»** *(رواه مسلم)*
>
> هذا التطبيق عمل خالص لوجه الله تعالى، صدقة جارية عن الشيخ محمد صديق المنشاوي وعن جميع المسلمين والمسلمات الأحياء منهم والأموات. نسأل الله أن يتقبله وينفع به أمة الإسلام.

---

## 🌟 نبذة عن المشروع (About the Project)

### 🇸🇦 العربية
تطبيق **"جامع تلاوات المنشاوي"** هو موسوعة صوتية متكاملة لتلاوات فضيلة القارئ الشيخ **محمد صديق المنشاوي**. يضم التطبيق المصحف المرتل كاملاً، والمصحف المجود كاملاً، بالإضافة إلى التلاوات الخارجية النادرة المسجلة عام **١٣٨٧ هـ**، كل ذلك بتصميم إسلامي فاخر وأداء سلس للغاية (60/120 FPS).

### 🇬🇧 English
**"Al-Minshawi Quran Recitations"** is a dedicated high-performance audio application featuring the complete recitations of the renowned Egyptian reciter **Sheikh Muhammad Siddiq Al-Minshawi**. The app brings together his complete **Murattal**, complete **Mujawwad**, and rare external studio recordings from **1387 AH (1967-1968)** with a refined hand-crafted Islamic design and smooth 60/120 FPS performance.

---

## ✨ المميزات الرئيسية (Key Features)

| الميزة (Feature) | التفاصيل (Details) |
| :--- | :--- |
| 📥 **الاستماع والتحميل بدون إنترنت** | إمكانية تنزيل السور والاستماع إليها في أي وقت دون اتصال بالإنترنت مع إدارة ذكية للتخزين المؤقت. |
| 🎧 **تشغيل في الخلفية وإشعارات النظام** | دعم كامل لتشغيل الصوت في الخلفية والتحكم به عبر شاشة القفل ومركز الإشعارات وسماعات البلوتوث (`just_audio` & `audio_service`). |
| 📋 **قوائم التشغيل المخصصة والمفضلة** | إنشاء قوائم تشغيل مخصصة (مثل "تلاوات الفجر"، "خواتيم السور") وتنظيم المفضلة وتشغيل المقاطع متتالية تلقائياً. |
| 🔁 **أوضاع التكرار وتكرار المقاطع (A-B Repeat)** | تكرار سورة محددة، تكرار الكل، خلط التشغيل (Shuffle)، ونظام تكرار بين نقطتين (A-B) للمساعدة في الحفظ والمراجعة. |
| ⏱️ **مؤقت النوم الذكي (Sleep Timer)** | مؤقت نوم مخصص مع تلاشي سلس لمستوى الصوت وخيار الإيقاف التلقائي عند انتهاء السورة. |
| ⚡ **أداء فائق وسرعة استجابة (High Performance)** | تجربة خالية من التقطيع بمعدل 60/120 إطاراً في الثانية بفضل تقنيات العزل `RepaintBoundary`، والتخزين المؤقت للبيانات في الذاكرة. |
| 🌙 **مظهر فاخر وداعم للوضع الداكن** | واجهة مستخدم إسلامية راقية باللون الكحلي الداكن والذهبي الدافئ تدعم اللغتين العربية والإنجليزية وخطوط الرقعة والأميري الأصيلة. |

---

## 🛠️ البنية التقنية (Tech Stack & Architecture)

- **Framework:** [Flutter](https://flutter.dev) (v3.29+)
- **Language:** [Dart](https://dart.dev) (v3.7+)
- **Architecture:** Clean Architecture (Presentation, Domain, Data Layers) with Feature-first modular organization.
- **State Management:** [BLoC / Cubit](https://bloclibrary.dev) (`flutter_bloc`) with granular `buildWhen` rebuild optimizations.
- **Local Storage:** [Hive](https://pub.dev/packages/hive) (`hive_flutter`) for instant offline key-value storage (playlists, favorites, download tracks metadata).
- **Audio Engine:** [just_audio](https://pub.dev/packages/just_audio) + [audio_service](https://pub.dev/packages/audio_service) + [just_audio_background](https://pub.dev/packages/just_audio_background).
- **Networking:** [Dio](https://pub.dev/packages/dio) with background progress streams and resilient chunk downloads.
- **Typography:** Custom Arabic fonts (Amiri & Cairo) via `google_fonts`.

---

## 📂 بنية المشروع (Project Structure)

```
lib/
├── core/                       # Shared app infrastructure
│   ├── constants/              # App colors, themes, API urls, collection manifests
│   ├── di/                     # GetIt dependency injection (service_locator.dart)
│   ├── errors/                 # Failures and custom exceptions
│   ├── network/                # Dio HTTP client configuration
│   ├── router/                 # GoRouter navigation setup
│   ├── services/               # Audio, storage, and download services
│   ├── settings/               # App settings & last-played cubit
│   ├── theme/                  # Theme modes & dynamic switcher
│   └── utils/                  # Arabic text normalization, time formatters
├── features/                   # Feature modules
│   ├── downloads/              # Download manager & storage cleanup UI
│   ├── favorites/              # User bookmarked recitations cubit & list
│   ├── player/                 # MiniPlayer, seek slider, sleep timer, audio engine
│   ├── playlists/              # Custom user playlists creation & management
│   └── recitations/            # Collections, surah listings, landing & home views
└── main.dart                   # Application entrypoint & initialization
```

---

## 🚀 البدء والتشغيل (Getting Started)

### المتطلبات المسبقة (Prerequisites)
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.5.0 أو أحدث)
- [Android Studio](https://developer.android.com/studio) أو [VS Code](https://code.visualstudio.com/) مع إضافات Flutter/Dart.
- جهاز بنظام Android أو محاكي (Android Emulator).

### خطوات التثبيت (Installation Steps)

1. **استنساخ المستودع (Clone Repository):**
   ```bash
   git clone https://github.com/a7mdabdoo/minshawi-recitations-app.git
   cd minshawi-recitations-app
   ```

2. **تثبيت الحزم والمكتبات (Install Dependencies):**
   ```bash
   flutter pub get
   ```

3. **تشغيل الاختبارات البرمجية (Run Unit Tests):**
   ```bash
   flutter test
   ```

4. **تشغيل التطبيق في بيئة التطوير (Run in Debug Mode):**
   ```bash
   flutter run
   ```

5. **بناء حزمة الإنتاج (Build Release APK):**
   ```bash
   flutter build apk --release
   ```

---

## 📜 الترخيص (License)

هذا المشروع متاح بموجب ترخيص [MIT License](LICENSE) - يمكنك استخدامه، وتعديله، ومشاركته مع الإبقاء على إشعار حقوق الملكية ودعوة صالحة بظهر الغيب.

