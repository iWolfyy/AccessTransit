import 'package:access_transit/core/utils/time_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TimeUtils Unit Tests', () {
    final now = DateTime(2026, 9, 22, 12, 0, 0);

    test('formatRelativeTime returns Just now for recent timestamps', () {
      final dateTime = now.subtract(const Duration(seconds: 15));
      expect(TimeUtils.formatRelativeTime(dateTime, clock: now), equals('Just now'));
    });

    test('formatRelativeTime returns min/mins ago for minutes difference', () {
      final dateTime1 = now.subtract(const Duration(minutes: 1));
      final dateTime15 = now.subtract(const Duration(minutes: 15));
      expect(TimeUtils.formatRelativeTime(dateTime1, clock: now), equals('1 min ago'));
      expect(TimeUtils.formatRelativeTime(dateTime15, clock: now), equals('15 mins ago'));
    });

    test('formatRelativeTime returns hour/hours ago for hours difference', () {
      final dateTime1 = now.subtract(const Duration(hours: 1));
      final dateTime3 = now.subtract(const Duration(hours: 3));
      expect(TimeUtils.formatRelativeTime(dateTime1, clock: now), equals('1 hour ago'));
      expect(TimeUtils.formatRelativeTime(dateTime3, clock: now), equals('3 hours ago'));
    });

    test('formatRelativeTime returns day/days ago for days difference', () {
      final dateTime1 = now.subtract(const Duration(days: 1));
      final dateTime5 = now.subtract(const Duration(days: 5));
      expect(TimeUtils.formatRelativeTime(dateTime1, clock: now), equals('1 day ago'));
      expect(TimeUtils.formatRelativeTime(dateTime5, clock: now), equals('5 days ago'));
    });
  });
}
