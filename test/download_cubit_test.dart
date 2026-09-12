import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:al_minshawi_recitations/core/errors/exceptions.dart';
import 'package:al_minshawi_recitations/core/services/download_service.dart';
import 'package:al_minshawi_recitations/features/recitations/domain/entities/recitation.dart';
import 'package:al_minshawi_recitations/features/recitations/presentation/cubit/download_cubit.dart';
import 'package:al_minshawi_recitations/features/recitations/presentation/cubit/download_state.dart';
import 'package:al_minshawi_recitations/features/recitations/presentation/cubit/recitation_list_cubit.dart';
import 'package:al_minshawi_recitations/features/recitations/domain/repositories/recitation_repository.dart';

class FakeDownloadService implements DownloadService {
  Completer<void> downloadStarted = Completer<void>();
  bool throwInsufficientStorage = false;

  @override
  Future<String> download({
    required Recitation recitation,
    required void Function(double progress) onProgress,
    required CancelToken cancelToken,
  }) async {
    if (throwInsufficientStorage) {
      throw const InsufficientStorageException();
    }
    if (!downloadStarted.isCompleted) downloadStarted.complete();

    for (int i = 1; i <= 10; i++) {
      if (cancelToken.isCancelled) {
        final reason = (cancelToken.cancelError?.error ??
                cancelToken.cancelError?.message ??
                '')
            .toString();
        if (reason.contains('pause')) {
          throw const DownloadPausedException();
        }
        throw const DownloadCancelledException();
      }
      await Future<void>.delayed(const Duration(milliseconds: 30));
      onProgress(i * 0.1);
    }

    return '/fake/path/${recitation.id}.mp3';
  }

  @override
  Future<void> deleteDownload(String recitationId) async {}

  @override
  Future<String?> getValidLocalPath(String recitationId) async => null;

  @override
  Future<int> getPartialFileSize(Recitation recitation) async => 0;
}

class FakeRecitationRepository implements RecitationRepository {
  @override
  Future<List<Recitation>> getRecitations({String? collectionId}) async => [];

  @override
  String? getDownloadedPath(String recitationId) => null;

  @override
  Future<void> removeDownloadedPath(String recitationId) async {}

  @override
  Future<void> saveDownloadedPath({
    required String recitationId,
    required String localFilePath,
  }) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeDownloadService fakeService;
  late RecitationListCubit listCubit;
  late DownloadCubit downloadCubit;

  const testRecitation = Recitation(
    id: 'test_1',
    surahNumber: 1,
    surahNameAr: 'الفاتحة',
    surahNameEn: 'Al-Fatihah',
    audioUrl: 'https://example.com/001.mp3',
    durationSeconds: 120,
    fileSizeBytes: 1024000,
    recordingYear: '1966',
    recordingLocation: 'القاهرة',
    isRare: true,
    quality: '128 kbps',
    verseRange: '1-7',
    collectionId: 'rare_1387',
  );

  setUp(() {
    fakeService = FakeDownloadService();
    listCubit = RecitationListCubit(FakeRecitationRepository());
    downloadCubit = DownloadCubit(
      downloadService: fakeService,
      recitationListCubit: listCubit,
    );
  });

  tearDown(() {
    downloadCubit.close();
    listCubit.close();
  });

  test('Initial state has no active downloads and no errors', () {
    expect(downloadCubit.state, const DownloadState());
    expect(downloadCubit.state.isDownloading('test_1'), false);
    expect(downloadCubit.state.isPaused('test_1'), false);
    expect(downloadCubit.state.getProgress('test_1'), 0.0);
  });

  test('pauseDownload transitions state to paused and keeps progress', () async {
    final downloadFuture = downloadCubit.startDownload(testRecitation);
    await fakeService.downloadStarted.future;

    expect(downloadCubit.state.isDownloading('test_1'), true);

    downloadCubit.pauseDownload('test_1');
    await downloadFuture;

    expect(downloadCubit.state.isDownloading('test_1'), false);
    expect(downloadCubit.state.isPaused('test_1'), true);
    expect(downloadCubit.state.lastError, isNull);
  });

  test('cancelDownload cancels session and removes progress completely', () async {
    final downloadFuture = downloadCubit.startDownload(testRecitation);
    await fakeService.downloadStarted.future;

    expect(downloadCubit.state.isDownloading('test_1'), true);

    await downloadCubit.cancelDownload('test_1');
    await downloadFuture;

    expect(downloadCubit.state.isDownloading('test_1'), false);
    expect(downloadCubit.state.isPaused('test_1'), false);
    expect(downloadCubit.state.hasActiveSession('test_1'), false);
    expect(downloadCubit.state.lastError, isNull);
  });

  test('resumeDownload resumes from paused state into downloading', () async {
    final downloadFuture = downloadCubit.startDownload(testRecitation);
    await fakeService.downloadStarted.future;
    downloadCubit.pauseDownload('test_1');
    await downloadFuture;

    expect(downloadCubit.state.isPaused('test_1'), true);

    fakeService.downloadStarted = Completer<void>();
    final resumeFuture = downloadCubit.resumeDownload(testRecitation);
    await fakeService.downloadStarted.future;

    expect(downloadCubit.state.isDownloading('test_1'), true);
    expect(downloadCubit.state.isPaused('test_1'), false);

    await resumeFuture;
    expect(downloadCubit.state.isDownloading('test_1'), false);
    expect(downloadCubit.state.isPaused('test_1'), false);
  });

  test('InsufficientStorageException aborts download and emits storage full error', () async {
    fakeService.throwInsufficientStorage = true;
    await downloadCubit.startDownload(testRecitation);

    expect(downloadCubit.state.isDownloading('test_1'), false);
    expect(downloadCubit.state.isPaused('test_1'), false);
    expect(downloadCubit.state.lastError, 'مساحة التخزين غير كافية على الهاتف');
    expect(downloadCubit.state.errorRecitationId, 'test_1');
  });
}
