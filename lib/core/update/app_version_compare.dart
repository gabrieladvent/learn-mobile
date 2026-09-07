library;

bool isOlderVersion(String? current, String? other) {
  final a = _parse(current);
  final b = _parse(other);

  if (a == null || b == null) return false;

  for (var i = 0; i < (a.length > b.length ? a.length : b.length); i++) {
    final left = i < a.length ? a[i] : 0;
    final right = i < b.length ? b[i] : 0;

    if (left != right) return left < right;
  }

  return false;
}

List<int>? _parse(String? version) {
  final trimmed = version?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;

  final parts = trimmed.split('+').first.split('.');
  final numbers = <int>[];

  for (final part in parts) {
    final number = int.tryParse(part);
    if (number == null || number < 0) return null;

    numbers.add(number);
  }

  return numbers.isEmpty ? null : numbers;
}
