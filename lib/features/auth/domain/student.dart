import 'package:freezed_annotation/freezed_annotation.dart';

part 'student.freezed.dart';
part 'student.g.dart';

/// Identitas siswa yang sedang login.
///
/// Lapisan `domain` = bentuk data yang dipakai seluruh aplikasi. Sengaja tidak
/// tahu apa-apa soal HTTP, database, atau Flutter — jadi bisa dites tanpa
/// menjalankan aplikasi.
///
/// `freezed` menghasilkan: konstruktor const, `==`/`hashCode`, `copyWith`, dan
/// `toString`. Tanpa itu, dua objek dengan isi sama dianggap berbeda oleh
/// Riverpod dan layar akan rebuild terus-menerus tanpa alasan.
@freezed
abstract class Student with _$Student {
  const factory Student({
    required String id,
    @JsonKey(name: 'full_name') required String fullName,
    required String? nisn,
    /// Nama rombel, mis. "X IPA 1". Bukan tipe data kelas — ini string dari server.
    @JsonKey(name: 'class') required String? className,
    @JsonKey(name: 'photo_url') String? photoUrl,
    @JsonKey(name: 'tracking_opt_out') @Default(false) bool trackingOptOut,
    @JsonKey(name: 'tracking_disclosure_seen') @Default(false) bool trackingDisclosureSeen,
  }) = _Student;

  factory Student.fromJson(Map<String, dynamic> json) => _$StudentFromJson(json);
}
