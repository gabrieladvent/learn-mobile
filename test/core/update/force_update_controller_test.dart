import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_mobile/core/update/force_update_controller.dart';
import 'package:learn_mobile/core/update/force_update_info.dart';

void main() {
  group('ForceUpdateController', () {
    test('mulai tanpa kunci', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(forceUpdateControllerProvider), isNull);
    });

    test('laporan pertama yang menang', () {
      // Beberapa permintaan paralel akan sama-sama kena 426. Yang pertama
      // sudah cukup; menimpanya hanya membuat router menghitung ulang tanpa
      // hasil yang berbeda.
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(
        forceUpdateControllerProvider.notifier,
      );

      controller.reportRejected(const ForceUpdateInfo(message: 'pertama'));
      controller.reportRejected(const ForceUpdateInfo(message: 'kedua'));

      expect(container.read(forceUpdateControllerProvider)?.message, 'pertama');
    });
  });
}
