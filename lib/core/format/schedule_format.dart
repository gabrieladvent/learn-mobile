String formatDayMonth(DateTime local) =>
    '${_days[local.weekday - 1]}, ${local.day} ${_months[local.month - 1]}';

String formatSchedule(DateTime at, {DateTime? now}) {
  final local = at.toLocal();
  final reference = (now ?? DateTime.now()).toLocal();
  final dayOffset = _calendarDay(local)
      .difference(_calendarDay(reference))
      .inDays;

  final day = switch (dayOffset) {
    0 => 'hari ini',
    1 => 'besok',
    -1 => 'kemarin',
    _ when local.year == reference.year => formatDayMonth(local),
    _ => '${formatDayMonth(local)} ${local.year}',
  };

  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');

  return '$day $hour.$minute';
}

DateTime _calendarDay(DateTime local) =>
    DateTime.utc(local.year, local.month, local.day);

const _days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];
