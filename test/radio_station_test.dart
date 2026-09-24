import 'package:flutter_test/flutter_test.dart';
import 'package:wirdi/core/models/radio_station.dart';

void main() {
  group('RadioStation.isSecureUrl', () {
    test('accepts https streams', () {
      expect(RadioStation.isSecureUrl('https://example.com/stream'), isTrue);
      expect(RadioStation.isSecureUrl('  HTTPS://example.com/stream '), isTrue);
    });

    test('rejects cleartext and empty urls (cleartext traffic is disabled app-wide)', () {
      expect(RadioStation.isSecureUrl('http://example.com/stream'), isFalse);
      expect(RadioStation.isSecureUrl(''), isFalse);
      expect(RadioStation.isSecureUrl('example.com/stream'), isFalse);
    });
  });
}
