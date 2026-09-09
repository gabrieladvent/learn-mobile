import 'package:flutter_test/flutter_test.dart';
import 'package:learn_mobile/features/dashboard/domain/dashboard.dart';

Map<String, dynamic> fullPayload() => <String, dynamic>{
  'courses': [
    <String, dynamic>{
      'id': 'course-1',
      'subject_name': 'Matematika',
      'subject_code': 'MTK',
      'classroom_name': 'X IPA 1',
      'teacher_name': 'Ibu Sari',
      'semester': 1,
      'academic_year': '2025/2026',
      'is_pinned': true,
    },
  ],
  'stats': <String, dynamic>{
    'assignments_pending': 3,
    'assignments_completed': 12,
    'exams_completed': 2,
    'avg_score': 84.5,
    'upcoming_exam': <String, dynamic>{
      'id': 'exam-1',
      'title': 'UH Bab 3',
      'subject_name': 'Matematika',
      'starts_at': '2026-09-08T07:00:00+07:00',
      'duration_minutes': 60,
      'material_id': 'material-1',
    },
  },
  'meta': <String, dynamic>{
    'classroom_name': 'X IPA 1',
    'academic_year': '2025/2026',
    'homeroom_teacher_name': 'Ibu Sari',
    'semester': 1,
    'inspire': 'Belajar itu menyenangkan.',
  },
};

void main() {
  group('Dashboard.fromJson', () {
    test('membaca payload lengkap sesuai kontrak', () {
      final dashboard = Dashboard.fromJson(fullPayload());

      expect(dashboard.courses.single.subjectName, 'Matematika');
      expect(dashboard.courses.single.isPinned, isTrue);
      expect(dashboard.stats!.assignmentsPending, 3);
      expect(dashboard.stats!.avgScore, 84.5);
      expect(dashboard.stats!.upcomingExam!.title, 'UH Bab 3');
      expect(dashboard.stats!.upcomingExam!.materialId, 'material-1');
      expect(dashboard.meta!.inspire, 'Belajar itu menyenangkan.');
    });

    test('waktu ujian dibaca beserta offset zonanya', () {
      final dashboard = Dashboard.fromJson(fullPayload());
      final startsAt = dashboard.stats!.upcomingExam!.startsAt!;

      // 07:00 di +07:00 adalah 00:00 UTC. Membandingkan lewat UTC membuat test
      // ini tidak bergantung pada zona waktu mesin yang menjalankannya.
      expect(startsAt.toUtc().hour, 0);
      expect(startsAt.toUtc().day, 8);
    });

    // Backend mengambil nama lewat relasi opsional (`$cs->subject?->name`),
    // jadi sekolah yang datanya belum lengkap benar-benar mengirim null.
    // Beranda harus tetap terbuka — siswa tidak bisa memperbaiki ini sendiri.
    test('relasi yang belum lengkap tidak membuatnya gagal', () {
      final dashboard = Dashboard.fromJson({
        'courses': [
          {
            'id': 'course-1',
            'subject_name': null,
            'subject_code': null,
            'classroom_name': null,
            'teacher_name': null,
            'semester': null,
            'academic_year': null,
            'is_pinned': false,
          },
        ],
        'stats': null,
        'meta': null,
      });

      expect(dashboard.courses.single.id, 'course-1');
      expect(dashboard.courses.single.subjectName, isNull);
      expect(dashboard.stats, isNull);
      expect(dashboard.meta, isNull);
    });

    test('payload kosong menghasilkan beranda kosong, bukan error', () {
      final dashboard = Dashboard.fromJson(const {});

      expect(dashboard.courses, isEmpty);
      expect(dashboard.stats, isNull);
    });

    // `avg_score` di backend adalah hasil `round()`, yang untuk nilai bulat
    // dikirim sebagai int — bukan double.
    test('avg_score bulat dari server tetap terbaca', () {
      final payload = fullPayload();
      (payload['stats'] as Map)['avg_score'] = 84;

      final dashboard = Dashboard.fromJson(payload);

      expect(dashboard.stats!.avgScore, 84.0);
    });

    test('belum ada nilai dibedakan dari nilai nol', () {
      final payload = fullPayload();
      (payload['stats'] as Map)['avg_score'] = null;

      expect(Dashboard.fromJson(payload).stats!.avgScore, isNull);
    });

    test('tanpa ujian terdekat, field-nya null bukan objek kosong', () {
      final payload = fullPayload();
      (payload['stats'] as Map)['upcoming_exam'] = null;

      expect(Dashboard.fromJson(payload).stats!.upcomingExam, isNull);
    });

    // Kontrak menyebut server SUDAH mengurut yang di-pin di atas. Klien tidak
    // boleh mengurut ulang — dua sumber kebenaran pasti berbeda suatu saat.
    test('urutan course dari server dipertahankan apa adanya', () {
      final dashboard = Dashboard.fromJson({
        'courses': [
          {'id': 'b', 'subject_name': 'B', 'is_pinned': false},
          {'id': 'a', 'subject_name': 'A', 'is_pinned': true},
        ],
      });

      expect(dashboard.courses.map((c) => c.id), ['b', 'a']);
    });
  });
}
