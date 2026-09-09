import 'package:freezed_annotation/freezed_annotation.dart';

part 'dashboard.freezed.dart';
part 'dashboard.g.dart';

@freezed
abstract class Dashboard with _$Dashboard {
  const factory Dashboard({
    @Default(<CourseSummary>[]) List<CourseSummary> courses,
    DashboardStats? stats,
    DashboardMeta? meta,
  }) = _Dashboard;

  factory Dashboard.fromJson(Map<String, dynamic> json) =>
      _$DashboardFromJson(json);
}

@freezed
abstract class CourseSummary with _$CourseSummary {
  const factory CourseSummary({
    required String id,
    @JsonKey(name: 'subject_name') String? subjectName,
    @JsonKey(name: 'subject_code') String? subjectCode,
    @JsonKey(name: 'classroom_name') String? classroomName,
    @JsonKey(name: 'teacher_name') String? teacherName,
    int? semester,
    @JsonKey(name: 'academic_year') String? academicYear,
    @JsonKey(name: 'is_pinned') @Default(false) bool isPinned,
  }) = _CourseSummary;

  factory CourseSummary.fromJson(Map<String, dynamic> json) =>
      _$CourseSummaryFromJson(json);
}

@freezed
abstract class DashboardStats with _$DashboardStats {
  const factory DashboardStats({
    @JsonKey(name: 'assignments_pending') @Default(0) int assignmentsPending,
    @JsonKey(name: 'assignments_completed')
    @Default(0)

    int assignmentsCompleted,
    
    @JsonKey(name: 'exams_completed') @Default(0) int examsCompleted,
    @JsonKey(name: 'avg_score') double? avgScore,
    @JsonKey(name: 'upcoming_exam') UpcomingExam? upcomingExam,
  }) = _DashboardStats;

  factory DashboardStats.fromJson(Map<String, dynamic> json) =>
      _$DashboardStatsFromJson(json);
}

@freezed
abstract class UpcomingExam with _$UpcomingExam {
  const factory UpcomingExam({
    required String id,
    String? title,

    @JsonKey(name: 'subject_name') String? subjectName,
    @JsonKey(name: 'starts_at') DateTime? startsAt,
    @JsonKey(name: 'duration_minutes') int? durationMinutes,
    @JsonKey(name: 'material_id') String? materialId,
  }) = _UpcomingExam;

  factory UpcomingExam.fromJson(Map<String, dynamic> json) =>
      _$UpcomingExamFromJson(json);
}

@freezed
abstract class DashboardMeta with _$DashboardMeta {
  const factory DashboardMeta({
    @JsonKey(name: 'classroom_name') String? classroomName,
    @JsonKey(name: 'academic_year') String? academicYear,
    @JsonKey(name: 'homeroom_teacher_name') String? homeroomTeacherName,
    
    int? semester,
    String? inspire,
  }) = _DashboardMeta;

  factory DashboardMeta.fromJson(Map<String, dynamic> json) =>
      _$DashboardMetaFromJson(json);
}
