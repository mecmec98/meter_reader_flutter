import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class CapturedPhoto {
  final String path;
  final String fileName;

  const CapturedPhoto({
    required this.path,
    required this.fileName,
  });
}

class CameraHelper {
  CameraHelper({ImagePicker? imagePicker})
      : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  Future<CapturedPhoto?> takePhoto({
    required String accountNo,
    String category = 'notices',
    int imageQuality = 70,
    double maxWidth = 1200,
  }) async {
    final photo = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: imageQuality,
      maxWidth: maxWidth,
    );
    if (photo == null) return null;

    return _copyToAppStorage(
      sourcePath: photo.path,
      accountNo: accountNo,
      category: category,
    );
  }

  Future<CapturedPhoto?> pickFromGallery({
    required String accountNo,
    String category = 'notices',
    int imageQuality = 70,
    double maxWidth = 1200,
  }) async {
    final photo = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: imageQuality,
      maxWidth: maxWidth,
    );
    if (photo == null) return null;

    return _copyToAppStorage(
      sourcePath: photo.path,
      accountNo: accountNo,
      category: category,
    );
  }

  Future<List<CapturedPhoto>> getPhotos({
    required String accountNo,
    String category = 'notices',
  }) async {
    final directory = await _getCategoryDirectory(category);
    final prefix = _safeFileName(accountNo);
    final files = await directory
        .list()
        .where((entity) => entity is File)
        .cast<File>()
        .where((file) {
      final name = path.basename(file.path);
      return name.startsWith('$prefix-');
    }).toList();

    files.sort(
      (a, b) => b.path.toLowerCase().compareTo(a.path.toLowerCase()),
    );
    return files
        .map(
          (file) => CapturedPhoto(
            path: file.path,
            fileName: path.basename(file.path),
          ),
        )
        .toList();
  }

  Future<void> deletePhoto(String photoPath) async {
    final file = File(photoPath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<CapturedPhoto> _copyToAppStorage({
    required String sourcePath,
    required String accountNo,
    required String category,
  }) async {
    final directory = await _getCategoryDirectory(category);
    final now = DateTime.now();
    final timestamp = '${now.year}${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
    final fileName = '${_safeFileName(accountNo)}-$timestamp.jpg';
    final destination = File(path.join(directory.path, fileName));
    await File(sourcePath).copy(destination.path);

    return CapturedPhoto(
      path: destination.path,
      fileName: fileName,
    );
  }

  Future<Directory> _getCategoryDirectory(String category) async {
    if (Platform.isAndroid) {
      try {
        final publicDirectory = Directory(
          path.join(
            '/storage/emulated/0/Download',
            'MeterReaderPhotos',
            category,
          ),
        );
        await publicDirectory.create(recursive: true);
        return publicDirectory;
      } catch (_) {
        // Fall back to app-private storage if public Downloads is unavailable.
      }
    }

    final documents = await getApplicationDocumentsDirectory();
    final privateDirectory =
        Directory(path.join(documents.path, 'meter_reader_photos', category));
    await privateDirectory.create(recursive: true);
    return privateDirectory;
  }

  String _safeFileName(String accountNo) {
    final safe = accountNo.replaceAll(RegExp(r'[^\w.-]'), '_');
    return safe.isEmpty ? 'account' : safe;
  }
}
