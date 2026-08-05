import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'service/ai_api_key_store.dart';
import 'service/ai_service.dart';

final aiApiKeyStoreProvider = Provider<AiApiKeyStore>((ref) {
  return AiApiKeyStore();
});

final aiHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final aiServiceProvider = Provider<AiService>((ref) {
  return AiService(
    client: ref.watch(aiHttpClientProvider),
    keyStore: ref.watch(aiApiKeyStoreProvider),
  );
});
