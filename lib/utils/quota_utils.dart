// lib/utils/quota_utils.dart

/// Преобразует строку "часы:минуты" (например, "01:30") в общее количество минут.
int parseQuotaToMinutes(String quota) {
  final parts = quota.split(':');
  if (parts.length != 2) return 0;
  final hours = int.tryParse(parts[0]) ?? 0;
  final minutes = int.tryParse(parts[1]) ?? 0;
  return hours * 60 + minutes;
}

/// Преобразует минуты обратно в строку формата "часы:минуты" (например, 90 -> "01:30").
String minutesToQuota(int minutes) {
  final hours = minutes ~/ 60;
  final remainingMinutes = minutes % 60;
  return '${hours.toString().padLeft(2, '0')}:${remainingMinutes.toString().padLeft(2, '0')}';
}


String convertWeekday(int day) {
  final daysOfWeek = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];
  return daysOfWeek[day - 1];
}