import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/cache/cached.dart';
import '../data/dashboard_repository.dart';
import '../domain/dashboard.dart';

part 'dashboard_controller.g.dart';

@riverpod
Stream<Cached<Dashboard>> dashboard(Ref ref) =>
    ref.watch(dashboardRepositoryProvider).watch();
