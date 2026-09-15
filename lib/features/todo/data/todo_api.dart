import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_envelope.dart';

part 'todo_api.g.dart';

class TodoApi {
  const TodoApi(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> fetch() async {
    final res = await _client.get<Map<String, dynamic>>('/todo');

    return ApiEnvelope.fromJson(res.data!).data ?? const {};
  }
}

@Riverpod(keepAlive: true)
TodoApi todoApi(Ref ref) => TodoApi(ref.watch(apiClientProvider));
