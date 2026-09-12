/// Application-wide constants.
abstract class AppConstants {
  AppConstants._();

  // App Identity
  static const String appName = 'التلاوات الجديدة';
  static const String appSubtitle = 'الشيخ محمد صديق المنشاوي';
  static const String sheikhNameAr = 'الشيخ محمد صديق المنشاوي';
  static const String sheikhNameEn = 'Sheikh Mohamed Siddiq Al-Minshawi';
  static const String collectionTitle = 'التلاوات النادرة';

  // Assets
  static const String manifestAssetPath = 'assets/data/recitations_manifest.json';
  static const String defaultArtworkAsset = 'assets/images/artwork.png';

  // Hive Boxes
  static const String recitationsBoxName = 'recitations_box';
  static const String downloadedFilesBoxName = 'downloaded_files_box';
  static const String settingsBoxName = 'settings_box';
  static const String favoritesBoxName = 'favorites_box';
  static const String playlistsBoxName = 'playlists_box';

  // Hive Keys
  static const String downloadedFilePathKey = 'downloaded_file_path';
  static const String themeKey = 'app_theme';
  static const String lastPlayedRecitationIdKey = 'last_played_recitation_id';
  static const String lastPlayedPositionSecondsKey =
      'last_played_position_seconds';

  // Developer & Social Links
  static const String devNameAr = 'أحمد محمد عبده';
  static const String devTitleAr = 'مطور تطبيقات الموبايل';
  static const String devFacebookUrl = 'https://www.facebook.com/a7mdabdoo/';
  static const String devGithubUrl = 'https://github.com/a7mdabdoo';
  static const String devLinkedinUrl = 'https://www.linkedin.com/in/ahmd-mhmd-abdo';
  static const String devEmail = 'mailto:ahmed@mohamed-abdo.com';
  static const String devDedication = 'صدقة جارية عني وعن والديّ وجميع المسلمين والمسلمات';

  // Download Settings
  static const String downloadsDirName = 'recitations_downloads';
  static const int maxConcurrentDownloads = 3;
  static const int connectTimeoutSeconds = 30;
  static const int receiveTimeoutSeconds = 0; // 0 = no timeout for streaming

  // Audio
  static const String audioBackgroundTaskId = 'com.islamic.audio.al_minshawi';
  static const String audioNotificationChannelId = 'al_minshawi_audio_channel';
  static const String audioNotificationChannelName = 'تلاوات المنشاوي';

  // Skip Durations
  static const int skipForwardSeconds = 10;
  static const int skipBackwardSeconds = 10;
}
