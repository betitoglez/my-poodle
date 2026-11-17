import '../data/storage_backend.dart';

Future<StorageBackend> createPlatformBackend() async => MemoryBackend();
