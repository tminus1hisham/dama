import 'package:flutter_test/flutter_test.dart';
import 'package:dama/services/mpesa_service.dart';

void main() {
  group('MpesaService', () {
    test('formatPhone converts 0... to 254...', () {
      expect(MpesaService.formatPhone('0712345678'), '254712345678');
      expect(MpesaService.formatPhone('+254712345678'), '254712345678');
      expect(MpesaService.formatPhone('254712345678'), '254712345678');
      expect(MpesaService.formatPhone('712345678'), '254712345678');
    });

    test('validates Kenyan phone numbers', () {
      // Valid formats - test via formatPhone validation
      final valid1 = MpesaService.formatPhone('0712345678');
      final valid2 = MpesaService.formatPhone('254712345678');
      
      expect(valid1, '254712345678');
      expect(valid2, '254712345678');
    });
  });
}
