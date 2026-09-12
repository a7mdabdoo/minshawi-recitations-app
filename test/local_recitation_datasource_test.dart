import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:al_minshawi_recitations/features/recitations/data/datasources/local_recitation_data_source.dart';

void main() {
  late Directory tempDir;
  late Box<dynamic> box;
  late LocalRecitationDataSource dataSource;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_datasource_test');
    Hive.init(tempDir.path);
    box = await Hive.openBox('test_downloaded_box');
    dataSource = LocalRecitationDataSource(box);
  });

  tearDown(() async {
    await box.close();
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('getAllDownloadedMap returns all saved paths', () async {
    expect(dataSource.getAllDownloadedMap(), isEmpty);

    await dataSource.saveDownloadedPath(
      recitationId: 'rare_001',
      localFilePath: '/data/rare_001.mp3',
    );
    await dataSource.saveDownloadedPath(
      recitationId: 'rare_002',
      localFilePath: '/data/rare_002.mp3',
    );

    final map = dataSource.getAllDownloadedMap();
    expect(map.length, equals(2));
    expect(map['rare_001'], equals('/data/rare_001.mp3'));
    expect(map['rare_002'], equals('/data/rare_002.mp3'));

    final ids = dataSource.getAllDownloadedIds();
    expect(ids, containsAll({'rare_001', 'rare_002'}));

    await dataSource.removeDownloadedPath('rare_001');
    expect(dataSource.getAllDownloadedMap().length, equals(1));
    expect(dataSource.getDownloadedPath('rare_001'), isNull);
  });
}
