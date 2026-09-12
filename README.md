# جامع تلاوات المنشاوي
### Al-Minshawi Quran Recitations App

تطبيق قرآني شامل ونقي لوجه الله تعالى، يجمع التراث الصوتي لفضيلة الشيخ محمد صديق المنشاوي (رحمه الله) بأعلى معايير الأداء والجمالية، مبني باستخدام Flutter وفق مبادئ Clean Architecture وبدون أي إعلانات.

*A premium, non-profit, offline-first Quranic recitation application dedicated to the vocal legacy of Sheikh Muhammad Siddiq Al-Minshawi, crafted with Flutter and Clean Architecture principles with zero ads.*

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
تطبيق **"جامع تلاوات المنشاوي"** هو منصة قرآنية صوتية مفتوحة المصدر تهدف إلى توفير تجربة استماع راقية وموثوقة للتراث الصوتي الخالد لفضيلة القارئ الشيخ محمد صديق المنشاوي (رحمه الله). يجمع التطبيق المصحف المرتل كاملاً (١١٤ سورة)، والمصحف المجود كاملاً، بالإضافة إلى التسجيلات الخارجية النادرة لحفلات عام ١٣٨٧ هـ. يتميز التطبيق بمشغل صوتي عصري ومتقدم مستوحى من أفضل منصات الصوتيات، وأدوات متخصصة في حفظ القرآن ومراجعته، مع دعم كامل للتشغيل دون اتصال بالإنترنت وخلو تام من الإعلانات أو أدوات التتبع.

### English
**Al-Minshawi Quran Recitations** is a modern, open-source audio streaming and offline playback platform engineered to present the timeless recordings of Sheikh Muhammad Siddiq Al-Minshawi. It bundles his complete Murattal recitation (114 Surahs), complete Mujawwad recitation, and rare historic external concert recordings from 1387 AH (1967-1968). The app provides an elegant, Spotify-inspired audio experience with Quranic memorization tools, offline caching, and strict zero-advertising and privacy commitments.

---

## المميزات الرئيسية | Key Features

### 1. مشغل صوتي عصري وشريط مصغر تفاعلي (Modern Audio Player & Mini-Player)
- **واجهة عصرية فاخرة:** تصميم رمادي داكن فاحم (Charcoal Grey & Gold Accent) يتناغم بدقة مع ألوان التطبيق في الوضعين الداكن والفاتح.
- **إيماءات سحب سلسة (Bidirectional Swipe Gestures):** سحب لأعلى على الشريط المصغر (Mini-Player) لفتح المشغل الكامل بانتقال ناعم، وسحب لأسفل في المشغل الكامل للرجوع الفوري.
- **تحكم زمني دقيق:** أزرار تقديم وتأخير مخصصة (`+10s` و `-10s`) لتسهيل متابعة الآيات والتدبر.
- **تشغيل في الخلفية وشاشة القفل:** تكامل متكامل مع نظام التشغيل عبر `just_audio` و `audio_service` مع أزرار التحكم في شريط الإشعارات وشاشة القفل.

### 2. أداة التكرار الذكي وحفظ الآيات (A-B Repeat Looping)
- إمكانية تحديد نقطة بداية (A) ونقطة نهاية (B) بدقة بالغة بالثواني والأجزاء المئوية.
- أزرار ضبط دقيق (`+1s` و `-1s`) لكل نقطة للوصول للآية المحددة بدقة.
- تكرار تلقائي بعدد محدد أو تكرار لا نهائي للمساعدة في تثبيت الحفظ ومراجعة الأحكام.

### 3. مكتبة تلاوات متكاملة (Comprehensive Recitation Library)
- **المصحف المرتل كاملاً:** ١١٤ سورة نقية برواية حفص عن عاصم.
- **المصحف المجود:** روائع التلاوات المجودة بجودة صوتية عالية.
- **النوادر الخارجية لعام ١٣٨٧ هـ:** حفلات وتسجيلات خارجية تاريخية نادرة.

### 4. قوائم التشغيل المخصصة والمفضلة (Custom Playlists & Favorites)
- إنشاء وإدارة قوائم تشغيل مخصصة للتلاوات المفضلة وحفظها محلياً بأمان عبر Hive.
- بحث فوري وسريع يدعم تطبيع الحروف والهمزات العربية (`ArabicNormalizer`) لمنع أي فقد في نتائج البحث.
- تشغيل تتابعي ذكي لجميع عناصر القائمة.

### 5. الاستماع دون اتصال والتحميل السريع (Offline Downloads)
- تحميل السور والتلاوات للاستماع أثناء السفر أو في غياب شبكة الإنترنت.
- إدارة ذكية للتحميل تدعم الاستئناف التلقائي والإيقاف المؤقت، مع فحص سلامة الملفات على القرص.

### 6. مؤقت النوم الذكي (Smart Sleep Timer)
- خيارات زمنية مرنة مع إيقاف تدريجي هادئ للصوت لحماية السمع ومنع انقطاع الصوت المفاجئ.

### 7. دعم السمات والتصميم المتجاوب (Dark & Light Themes)
- دعم كامل للوضع الداكن (Dark Theme) المريح للعين والوضع الفاتح الأنيق، مع مراعاة كاملة لاتجاه القراءة من اليمين إلى اليسار (RTL).

---

## البنية البرمجية والتقنيات المستخدمة | Tech Stack & Architecture

- **إطار العمل (Framework):** Flutter (v3.29+)
- **لغة البرمجة (Language):** Dart (v3.7+)
- **نمط التصميم (Architecture):** Clean Architecture (Presentation, Domain, Data Layers)
- **إدارة الحالة (State Management):** BLoC / Cubit (`flutter_bloc`) مع تحسينات إعادة البناء `buildWhen` لأعلى أداء (60/120 FPS).
- **قواعد البيانات والتخزين المحلي (Local Storage):** Hive (`hive_flutter`) لحفظ التفضيلات وقوائم التشغيل ومسارات التنزيل محلياً وسريعاً.
- **محرك الصوتيات (Audio Engine):** `just_audio`, `audio_service`, `just_audio_background`
- **التنقل والتوجيه (Navigation):** `go_router`
- **إدارة الشبكة (Networking):** `dio`
- **الخطوط والطباعة (Typography):** Amiri (لأسماء السور والنصوص القرآنية) و Cairo (لواجهات المستخدم).

---

## هيكل المجلدات | Directory Structure

```
lib/
├── core/
│   ├── constants/              # ألوان التطبيق، الروابط، والثيمات
│   ├── di/                     # حقن التبعيات (GetIt service locator)
│   ├── errors/                 # معالجة الأخطاء والاستثناءات
│   ├── network/                # إعدادات عميل Dio
│   ├── router/                 # مسارات التنقل والتوجيه عبر GoRouter
│   ├── services/               # خدمات الصوت والتنزيل
│   ├── settings/               # إعدادات المستخدم وتفضيلات التشغيل
│   ├── theme/                  # تكوين الثيمات (Dark & Light Mode)
│   └── utils/                  # أدوات معالجة النصوص وتنسيق الوقت
├── features/
│   ├── downloads/              # إدارة التنزيلات وعرض السور المحملة
│   ├── favorites/              # المفضلة والتسجيلات المحفوظة
│   ├── player/                 # مشغل الصوت الكامل، المشغل المصغر، مؤقت النوم، وتكرار A-B
│   ├── playlists/              # إدارة قوائم التشغيل المخصصة والبحث
│   └── recitations/            # فهرس السور والمصاحف والصفحة الرئيسية
└── main.dart                   # نقطة انطلاق التطبيق
```

---

## سياسة الخصوصية | Privacy Policy

التطبيق مجاني 100%، بدون أي إعلانات تجارية أو أدوات تتبع، ولا يجمع أو يشارك أي بيانات شخصية للمستخدمين. للاطلاع على الوثيقة الرسمية لسياسة الخصوصية، يرجى زيارة:
- [سياسة الخصوصية الكاملة (PRIVACY_POLICY.md)](PRIVACY_POLICY.md)
- [الرابط العام على GitHub](https://github.com/a7mdabdoo/minshawi-recitations-app/blob/main/PRIVACY_POLICY.md)

---

## التثبيت والتشغيل | Installation & Setup

### المتطلبات الأساسية (Prerequisites)
- Flutter SDK (الإصدار 3.29.0 أو أحدث)
- Android SDK مع دعم Android 8.0 (API 26) فما فوق
- بيئة تطوير متكاملة (VS Code أو Android Studio)

### خطوات التشغيل (Setup Commands)

1. **استنساخ المستودع (Clone repository):**
   ```bash
   git clone https://github.com/a7mdabdoo/minshawi-recitations-app.git
   cd minshawi-recitations-app
   ```

2. **تثبيت الحزم البرمجية (Install dependencies):**
   ```bash
   flutter pub get
   ```

3. **تشغيل الاختبارات البرمجية (Run tests):**
   ```bash
   flutter test
   ```

4. **تشغيل التطبيق في بيئة التطوير (Run app):**
   ```bash
   flutter run
   ```

5. **بناء حزمة الإنتاج (Build release APK):**
   ```bash
   flutter build apk --release
   ```

---

## الترخيص | License

هذا المشروع متاح بموجب ترخيص [MIT License](LICENSE). جميع التلاوات الصوتية هي تراث إسلامي عام لفضيلة الشيخ محمد صديق المنشاوي (رحمه الله).
