const Object _unset = Object();

List<String> _normalizeImageList(List<String>? images) {
  if (images == null || images.isEmpty) {
    return const <String>[];
  }

  final normalized = <String>[];
  final seen = <String>{};
  for (final image in images) {
    final trimmed = image.trim();
    if (trimmed.isEmpty || !seen.add(trimmed)) {
      continue;
    }
    normalized.add(trimmed);
  }
  return normalized;
}

class EsportCenter {
  final String id;
  final String name;
  final String address;
  final int pcCount;
  final String pcSpec;
  final int price;
  final int vipCount;
  final int stageCount;
  final String vipSpec;
  final String stageSpec;
  final int vipPrice;
  final int stagePrice;
  final String phone;
  final double latitude;
  final double longitude;
  final String? ownerEmail;
  final String? profileImageBase64;
  final List<String> imagesBase64;
  final int lateArrivalGraceMinutes;
  final double rating;
  final int reviewCount;
  final String reviewSnippet;

  String? get primaryImage {
    final profile = profileImageBase64;
    if (profile != null && profile.isNotEmpty) {
      return profile;
    }
    for (final image in imagesBase64) {
      if (image.isNotEmpty) {
        return image;
      }
    }
    return null;
  }

  List<String> get allImages {
    final merged = <String>[];
    final profile = profileImageBase64;
    if (profile != null && profile.isNotEmpty) {
      merged.add(profile);
    }
    for (final image in imagesBase64) {
      if (image.isNotEmpty && image != profile) {
        merged.add(image);
      }
    }
    return List<String>.unmodifiable(merged);
  }

  EsportCenter({
    required this.id,
    required this.name,
    required this.address,
    required this.pcCount,
    required this.pcSpec,
    required this.price,
    int? vipCount,
    int? stageCount,
    String? vipSpec,
    String? stageSpec,
    int? vipPrice,
    int? stagePrice,
    required this.phone,
    required this.latitude,
    required this.longitude,
    this.ownerEmail,
    this.profileImageBase64,
    List<String>? imagesBase64,
    this.lateArrivalGraceMinutes = 15,
    double? rating,
    int? reviewCount,
    String? reviewSnippet,
  })  : vipCount = vipCount ?? 5,
        stageCount = stageCount ?? 5,
        vipSpec = (vipSpec == null || vipSpec.isEmpty)
            ? '$pcSpec / VIP tier'
            : vipSpec,
        stageSpec = (stageSpec == null || stageSpec.isEmpty)
            ? '$pcSpec / Stage tier'
            : stageSpec,
        vipPrice = vipPrice ?? (price + 3000),
        stagePrice = stagePrice ?? (price + 1500),
        imagesBase64 = List<String>.unmodifiable(_normalizeImageList(imagesBase64)),
        rating = rating ?? 4.7,
        reviewCount = reviewCount ?? 24,
        reviewSnippet = (reviewSnippet == null || reviewSnippet.isEmpty)
            ? 'Players like the setup and atmosphere.'
            : reviewSnippet;

  EsportCenter copyWith({
    String? id,
    String? name,
    String? address,
    int? pcCount,
    String? pcSpec,
    int? price,
    int? vipCount,
    int? stageCount,
    String? vipSpec,
    String? stageSpec,
    int? vipPrice,
    int? stagePrice,
    String? phone,
    double? latitude,
    double? longitude,
    Object? ownerEmail = _unset,
    Object? profileImageBase64 = _unset,
    List<String>? imagesBase64,
    int? lateArrivalGraceMinutes,
    double? rating,
    int? reviewCount,
    String? reviewSnippet,
  }) {
    return EsportCenter(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      pcCount: pcCount ?? this.pcCount,
      pcSpec: pcSpec ?? this.pcSpec,
      price: price ?? this.price,
      vipCount: vipCount ?? this.vipCount,
      stageCount: stageCount ?? this.stageCount,
      vipSpec: vipSpec ?? this.vipSpec,
      stageSpec: stageSpec ?? this.stageSpec,
      vipPrice: vipPrice ?? this.vipPrice,
      stagePrice: stagePrice ?? this.stagePrice,
      phone: phone ?? this.phone,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      ownerEmail: identical(ownerEmail, _unset)
          ? this.ownerEmail
          : ownerEmail as String?,
      profileImageBase64: identical(profileImageBase64, _unset)
          ? this.profileImageBase64
          : profileImageBase64 as String?,
      imagesBase64: imagesBase64 ?? this.imagesBase64,
      lateArrivalGraceMinutes:
          lateArrivalGraceMinutes ?? this.lateArrivalGraceMinutes,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      reviewSnippet: reviewSnippet ?? this.reviewSnippet,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'address': address,
      'pcCount': pcCount,
      'pcSpec': pcSpec,
      'price': price,
      'vipCount': vipCount,
      'stageCount': stageCount,
      'vipSpec': vipSpec,
      'stageSpec': stageSpec,
      'vipPrice': vipPrice,
      'stagePrice': stagePrice,
      'phone': phone,
      'latitude': latitude,
      'longitude': longitude,
      'ownerEmail': ownerEmail,
      'profileImageBase64': profileImageBase64,
      'imagesBase64': imagesBase64,
      'lateArrivalGraceMinutes': lateArrivalGraceMinutes,
      'rating': rating,
      'reviewCount': reviewCount,
      'reviewSnippet': reviewSnippet,
    };
  }

  factory EsportCenter.fromMap(Map<String, dynamic> map) {
    final rawImages = map['imagesBase64'];
    List<String> parsedImages = const <String>[];
    if (rawImages is List) {
      parsedImages = rawImages
          .whereType<Object>()
          .map((e) => e.toString())
          .toList(growable: false);
    }
    final legacyImage = map['imageBase64']?.toString();
    final profileImage = map['profileImageBase64']?.toString();
    return EsportCenter(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      pcCount: int.tryParse(map['pcCount'].toString()) ?? 0,
      pcSpec: map['pcSpec']?.toString() ?? '',
      price: int.tryParse(map['price'].toString()) ?? 0,
      vipCount: int.tryParse(map['vipCount'].toString()) ?? 5,
      stageCount: int.tryParse(map['stageCount'].toString()) ?? 5,
      vipSpec: map['vipSpec']?.toString(),
      stageSpec: map['stageSpec']?.toString(),
      vipPrice: int.tryParse(map['vipPrice'].toString()),
      stagePrice: int.tryParse(map['stagePrice'].toString()),
      phone: map['phone']?.toString() ?? '',
      latitude: double.tryParse(map['latitude'].toString()) ?? 0,
      longitude: double.tryParse(map['longitude'].toString()) ?? 0,
      ownerEmail: map['ownerEmail']?.toString(),
      profileImageBase64: (profileImage != null && profileImage.isNotEmpty)
          ? profileImage
          : ((legacyImage != null && legacyImage.isNotEmpty) ? legacyImage : null),
      imagesBase64: parsedImages,
      lateArrivalGraceMinutes:
          int.tryParse(map['lateArrivalGraceMinutes'].toString()) ?? 15,
      rating: double.tryParse(map['rating'].toString()) ?? 4.7,
      reviewCount: int.tryParse(map['reviewCount'].toString()) ?? 24,
      reviewSnippet: map['reviewSnippet']?.toString(),
    );
  }
}
