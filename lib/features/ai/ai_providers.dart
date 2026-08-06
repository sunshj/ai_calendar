import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'service/ai_provider_store.dart';
import 'service/ai_service.dart';

final aiProviderStoreProvider = Provider<AiProviderStore>((ref) {
  return AiProviderStore();
});

final aiHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final aiServiceProvider = Provider<AiService>((ref) {
  return AiService(
    client: ref.watch(aiHttpClientProvider),
    store: ref.watch(aiProviderStoreProvider),
  );
});
