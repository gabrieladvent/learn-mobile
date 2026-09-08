import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/app_config.dart';
import '../config/app_version.dart';
import '../storage/token_storage.dart';
import '../update/force_update_controller.dart';
import 'auth_interceptor.dart';
import 'error_interceptor.dart';

part 'dio_provider.g.dart';

@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.current.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      validateStatus: (status) => status != null && status < 400,
    ),
  );

  dio.interceptors.addAll([
    AuthInterceptor(
      ref.watch(tokenStorageProvider),
      ref.watch(appVersionProvider),
    ),

    ErrorInterceptor(
      onClientTooOld: (info) =>
          ref.read(forceUpdateControllerProvider.notifier).reportRejected(info),
    ),
  ]);

  return dio;
}
