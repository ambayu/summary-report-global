import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class ExportFileHelper {
  static Future<String?> saveBytes({
    required String dialogTitle,
    required String fileName,
    required List<String> allowedExtensions,
    required Uint8List bytes,
  }) async {
    if (bytes.isEmpty) {
      throw FileSystemException('File export kosong');
    }

    final extension = allowedExtensions.isEmpty
        ? null
        : allowedExtensions.first;
    final normalizedFileName = _normalizeFileName(fileName, extension);

    if (Platform.isAndroid || Platform.isIOS) {
      return _saveToAppExports(normalizedFileName, bytes);
    }

    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: dialogTitle,
      fileName: normalizedFileName,
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );

    if (savePath == null || savePath.isEmpty) return null;

    final file = File(_normalizePickedPath(savePath, extension));
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  static Future<void> promptOpenFile(
    BuildContext context, {
    required String filePath,
    required String successMessage,
  }) async {
    if (!context.mounted) return;

    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Export berhasil'),
          content: Text('$successMessage\n\nIngin membuka file sekarang?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Nanti'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Buka File'),
            ),
          ],
        );
      },
    );

    if (shouldOpen != true || !context.mounted) return;

    final result = await OpenFilex.open(filePath);
    if (!context.mounted) return;

    if (result.type != ResultType.done) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File tersimpan, tetapi belum bisa dibuka otomatis.'),
        ),
      );
    }
  }

  static Future<String> _saveToAppExports(
    String fileName,
    Uint8List bytes,
  ) async {
    final baseDirectory = await getApplicationDocumentsDirectory();
    final exportDirectory = Directory(
      '${baseDirectory.path}${Platform.pathSeparator}exports',
    );
    await exportDirectory.create(recursive: true);

    final file = File(
      '${exportDirectory.path}${Platform.pathSeparator}$fileName',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  static String _normalizePickedPath(String path, String? extension) {
    if (extension == null || extension.isEmpty) return path;
    final suffix = '.${extension.toLowerCase()}';
    if (path.toLowerCase().endsWith(suffix)) return path;
    return '$path$suffix';
  }

  static String _normalizeFileName(String fileName, String? extension) {
    final trimmed = fileName.trim().isEmpty ? 'export' : fileName.trim();
    if (extension == null || extension.isEmpty) return trimmed;

    final suffix = '.${extension.toLowerCase()}';
    if (trimmed.toLowerCase().endsWith(suffix)) return trimmed;
    return '$trimmed$suffix';
  }
}
