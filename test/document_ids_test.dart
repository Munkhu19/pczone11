import 'package:flutter_test/flutter_test.dart';
import 'package:pc_app/utils/document_ids.dart';

void main() {
  test('creates readable ids from Mongolian Cyrillic labels', () {
    final timestamp = DateTime.fromMillisecondsSinceEpoch(12345);

    expect(
      readableDocumentId('Өргөө тоглоомын төв', timestamp: timestamp),
      'urguu-togloomin-tuv-12345',
    );
  });

  test('booking ids include center and customer names', () {
    final timestamp = DateTime.fromMillisecondsSinceEpoch(67890);

    expect(
      readableBookingDocumentId(
        centerName: 'Их наяд',
        customerName: 'Бат',
        timestamp: timestamp,
      ),
      'booking-ih-nayad-bat-67890',
    );
  });
}
