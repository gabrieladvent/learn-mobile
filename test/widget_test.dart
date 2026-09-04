import 'package:flutter_test/flutter_test.dart';
import 'package:learn_mobile/core/network/api_envelope.dart';
import 'package:learn_mobile/core/error/app_failure.dart';

void main() {
  group('ApiEnvelope', () {
    test('membaca envelope sukses', () {
      final envelope = ApiEnvelope.fromJson({
        'response_code': 'success',
        'response_message': 'Berhasil',
        'response_data': {'token': 'abc'},
      });

      expect(envelope.code, 'success');
      expect(envelope.data?['token'], 'abc');
    });

    test('response_data boleh tidak ada', () {
      final envelope = ApiEnvelope.fromJson({
        'response_code': 'success',
        'response_message': 'Berhasil',
      });

      expect(envelope.data, isNull);
    });

    test('membedakan password_change_required dari forbidden biasa', () {
      // Keduanya HTTP 403 tapi perlakuannya berlawanan: yang satu mengarahkan
      // ke layar ganti password, yang lain cuma pesan generik.
      final mustChange = ApiEnvelope.fromJson({
        'response_code': 'password_change_required',
        'response_message': 'Ganti password default kamu dulu.',
      }).toFailure();

      final forbidden = ApiEnvelope.fromJson({
        'response_code': 'forbidden',
        'response_message': 'Kamu tidak punya akses.',
      }).toFailure();

      expect(mustChange, isA<PasswordChangeRequiredFailure>());
      expect(forbidden, isA<ForbiddenFailure>());
    });

    test('memetakan detail validasi per field', () {
      final failure = ApiEnvelope.fromJson({
        'response_code': 'validation_failed',
        'response_message': 'NISN atau password salah.',
        'response_data': {
          'fields': {
            'nisn': ['NISN atau password salah.'],
          },
        },
      }).toFailure();

      expect(failure, isA<ValidationFailure>());
      expect(
        (failure as ValidationFailure).firstFor('nisn'),
        'NISN atau password salah.',
      );
    });

    test('kode tak dikenal jatuh ke ServerFailure, bukan crash', () {
      // Backend boleh menambah kode baru kapan saja tanpa merusak aplikasi lama.
      final failure = ApiEnvelope.fromJson({
        'response_code': 'kode_yang_belum_ada',
        'response_message': 'Sesuatu terjadi.',
      }).toFailure();

      expect(failure, isA<ServerFailure>());
      expect(failure.message, 'Sesuatu terjadi.');
    });
  });
}
