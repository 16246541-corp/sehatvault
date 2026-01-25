import 'package:flutter_test/flutter_test.dart';
import 'package:sehatlocker/models/consent_entry.dart';
import 'package:sehatlocker/services/consent_service.dart';

void main() {
  final service = ConsentService();

  test('isValidConsentEntry returns false for null', () {
    expect(service.isValidConsentEntry(null), false);
  });

  test('isValidConsentEntry returns false for revoked consent', () {
    final entry = ConsentEntry(
      id: '1',
      templateId: 'recording',
      version: 'v1',
      timestamp: DateTime(2026, 1, 1),
      userId: 'local_user',
      scope: 'recording',
      granted: true,
      contentHash: 'hash',
      revocationDate: DateTime(2026, 1, 2),
      revocationReason: 'User revoked',
    );

    expect(service.isValidConsentEntry(entry), false);
  });

  test('isValidConsentEntry returns false for denied consent', () {
    final entry = ConsentEntry(
      id: '2',
      templateId: 'recording',
      version: 'v1',
      timestamp: DateTime(2026, 1, 1),
      userId: 'local_user',
      scope: 'recording',
      granted: false,
      contentHash: 'hash',
    );

    expect(service.isValidConsentEntry(entry), false);
  });

  test('isValidConsentEntry returns true for active consent', () {
    final entry = ConsentEntry(
      id: '3',
      templateId: 'recording',
      version: 'v1',
      timestamp: DateTime(2026, 1, 1),
      userId: 'local_user',
      scope: 'recording',
      granted: true,
      contentHash: 'hash',
    );

    expect(service.isValidConsentEntry(entry), true);
  });
}
