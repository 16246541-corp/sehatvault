import 'package:flutter_test/flutter_test.dart';
import 'package:sehatlocker/models/follow_up_item.dart';

void main() {
  group('FollowUpItem', () {
    test('structuredTitle combines verb, object, and timeframe', () {
      final item = FollowUpItem(
        id: '1',
        category: FollowUpCategory.appointment,
        verb: 'schedule',
        object: 'MRI',
        timeframeRaw: 'within 2 weeks',
        description: 'Schedule MRI within 2 weeks',
        priority: FollowUpPriority.normal,
        sourceConversationId: '123',
        createdAt: DateTime.now(),
      );

      expect(item.structuredTitle, 'Schedule MRI within 2 weeks');
    });

    test('structuredTitle handles null object', () {
      final item = FollowUpItem(
        id: '1',
        category: FollowUpCategory.medication,
        verb: 'take',
        timeframeRaw: 'daily',
        description: 'Take daily',
        priority: FollowUpPriority.normal,
        sourceConversationId: '123',
        createdAt: DateTime.now(),
      );

      expect(item.structuredTitle, 'Take daily');
    });

    test('structuredTitle handles null timeframe', () {
      final item = FollowUpItem(
        id: '1',
        category: FollowUpCategory.test,
        verb: 'perform',
        object: 'blood test',
        description: 'Perform blood test',
        priority: FollowUpPriority.normal,
        sourceConversationId: '123',
        createdAt: DateTime.now(),
      );

      expect(item.structuredTitle, 'Perform blood test');
    });
  });
}
