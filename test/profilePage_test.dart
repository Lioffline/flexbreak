import 'package:flutter_test/flutter_test.dart';
import 'package:flexbreak/utils/quota_utils.dart';

void main() {
  test('Парсинг строки квоты в минуты (формат "HH:MM")', () {
    expect(parseQuotaToMinutes('01:30'), 90);
    expect(parseQuotaToMinutes('00:45'), 45);
    expect(parseQuotaToMinutes('02:00'), 120);
    expect(parseQuotaToMinutes('00:00'), 0);
    expect(parseQuotaToMinutes('invalid'), 0);
  });

  test('Конвертация минут в строку квоты (формат "HH:MM")', () {
    expect(minutesToQuota(90), '01:30');
    expect(minutesToQuota(45), '00:45');
    expect(minutesToQuota(120), '02:00');
    expect(minutesToQuota(0), '00:00');
  });
}