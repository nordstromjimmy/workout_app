import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'data/services/storage_service.dart';
import 'presentation/providers/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = StorageService();
  await storage.init();

  //await storage.clearAll();

  runApp(
    ProviderScope(
      overrides: [storageServiceProvider.overrideWithValue(storage)],
      child: const WorkoutTrackerApp(),
    ),
  );
}
