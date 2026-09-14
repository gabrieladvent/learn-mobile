import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/app_failure.dart';

import '../data/dashboard_repository.dart';
import 'dashboard_controller.dart';

part 'course_pin_controller.g.dart';

@riverpod
class CoursePinController extends _$CoursePinController {
  final _inFlight = <String>{};

  @override
  Map<String, bool> build() {
    ref.listen(dashboardProvider, (_, next) {
      final cached = next.value;

      if (cached == null || !cached.isFresh) return;

      final settled = <String>[
        for (final course in cached.value.courses)
          if (!_inFlight.contains(course.id) &&
              state[course.id] == course.isPinned)
            course.id,
      ];

      if (settled.isEmpty) return;

      state = {...state}..removeWhere((id, _) => settled.contains(id));
    });

    return const {};
  }

  Future<void> toggle(String courseId, {required bool pinned}) async {
    state = {...state, courseId: pinned};

    if (!_inFlight.add(courseId)) return;

    try {
      bool? sent;

      while (ref.mounted) {
        final target = state[courseId];
        if (target == null || target == sent) break;

        await ref
            .read(dashboardRepositoryProvider)
            .setPinned(courseId, pinned: target);
        sent = target;
      }

      if (ref.mounted) ref.invalidate(dashboardProvider);
    } on NotFoundFailure {
      if (ref.mounted) {
        state = {...state}..remove(courseId);
        ref.invalidate(dashboardProvider);
      }
      rethrow;
    } catch (_) {
      if (ref.mounted) state = {...state}..remove(courseId);
      rethrow;
    } finally {
      _inFlight.remove(courseId);
    }
  }
}
