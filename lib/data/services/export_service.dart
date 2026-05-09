import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'storage_service.dart';

class ExportService {
  final StorageService _storage;

  ExportService(this._storage);

  /// Exports all data to a JSON file and opens the system share sheet.
  Future<void> exportToJson() async {
    try {
      final data = _storage.exportAll();
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);

      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')[0];
      final file = File('${dir.path}/workout_backup_$timestamp.json');
      await file.writeAsString(jsonString);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: 'Workout Tracker Backup',
      );
    } catch (e) {
      debugPrint('Export error: $e');
      rethrow;
    }
  }

  /// Opens a file picker, reads the selected JSON, and imports it.
  /// Returns true on success.
  Future<bool> importFromJson() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return false;

      final bytes = result.files.first.bytes;
      if (bytes == null) {
        final path = result.files.first.path;
        if (path == null) return false;
        final content = await File(path).readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;
        await _storage.importAll(data);
        return true;
      }

      final content = utf8.decode(bytes);
      final data = jsonDecode(content) as Map<String, dynamic>;
      await _storage.importAll(data);
      return true;
    } catch (e) {
      debugPrint('Import error: $e');
      rethrow;
    }
  }
}
