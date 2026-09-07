import 'package:freezed_annotation/freezed_annotation.dart';

part 'student.freezed.dart';
part 'student.g.dart';

@freezed
abstract class Student with _$Student {
  const factory Student({
    required String id,
    @JsonKey(name: 'full_name') required String fullName,
    required String? nisn,

    @JsonKey(name: 'class') required String? className,
    @JsonKey(name: 'photo_url') String? photoUrl,
    @JsonKey(name: 'tracking_opt_out') @Default(false) bool trackingOptOut,
    @JsonKey(name: 'tracking_disclosure_seen')
    @Default(false)
    bool trackingDisclosureSeen,
  }) = _Student;

  factory Student.fromJson(Map<String, dynamic> json) =>
      _$StudentFromJson(json);
}
