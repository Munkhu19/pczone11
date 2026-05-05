String readableDocumentId(
  String label, {
  String prefix = '',
  DateTime? timestamp,
}) {
  final slug = _slugify(label);
  final fallback = prefix.isEmpty ? 'item' : prefix;
  final base = slug.isEmpty ? fallback : slug;
  final millis = (timestamp ?? DateTime.now()).millisecondsSinceEpoch;

  if (prefix.isEmpty || base.startsWith('$prefix-')) {
    return '$base-$millis';
  }
  return '$prefix-$base-$millis';
}

String readableBookingDocumentId({
  required String centerName,
  required String customerName,
  DateTime? timestamp,
}) {
  final label = <String>[
    centerName,
    customerName,
  ].where((part) => part.trim().isNotEmpty).join('-');

  return readableDocumentId(label, prefix: 'booking', timestamp: timestamp);
}

String _slugify(String value) {
  final normalized = value.trim().toLowerCase().split('').map((char) {
    return _cyrillicToLatin[char] ?? char;
  }).join();
  final slug = normalized
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');

  if (slug.length <= 48) return slug;
  return slug.substring(0, 48).replaceAll(RegExp(r'-$'), '');
}

const _cyrillicToLatin = <String, String>{
  'а': 'a',
  'б': 'b',
  'в': 'v',
  'г': 'g',
  'д': 'd',
  'е': 'e',
  'ё': 'yo',
  'ж': 'j',
  'з': 'z',
  'и': 'i',
  'й': 'i',
  'к': 'k',
  'л': 'l',
  'м': 'm',
  'н': 'n',
  'о': 'o',
  'ө': 'u',
  'п': 'p',
  'р': 'r',
  'с': 's',
  'т': 't',
  'у': 'u',
  'ү': 'u',
  'ф': 'f',
  'х': 'h',
  'ц': 'ts',
  'ч': 'ch',
  'ш': 'sh',
  'щ': 'sh',
  'ъ': '',
  'ы': 'i',
  'ь': '',
  'э': 'e',
  'ю': 'yu',
  'я': 'ya',
};
