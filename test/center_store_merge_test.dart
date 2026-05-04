import 'package:flutter_test/flutter_test.dart';
import 'package:pc_app/data/center_store.dart';
import 'package:pc_app/models/center.dart';

void main() {
  EsportCenter buildCenter({
    required String id,
    String? profileImageBase64,
    List<String> imagesBase64 = const <String>[],
    String ownerEmail = 'owner@test.com',
  }) {
    return EsportCenter(
      id: id,
      name: 'Arena',
      address: 'UB',
      pcCount: 20,
      pcSpec: 'RTX',
      price: 5000,
      phone: '99999999',
      latitude: 47.9,
      longitude: 106.9,
      ownerEmail: ownerEmail,
      profileImageBase64: profileImageBase64,
      imagesBase64: imagesBase64,
    );
  }

  test('remote media overrides stale local media for synced centers', () {
    final local = buildCenter(
      id: 'center-1',
      profileImageBase64: 'centers/owner/center-1/profile-old.jpg',
      imagesBase64: const <String>[
        'centers/owner/center-1/gallery-old.jpg',
      ],
    );
    final remote = buildCenter(
      id: 'center-1',
      profileImageBase64: 'centers/owner/center-1/profile-new.jpg',
      imagesBase64: const <String>[
        'centers/owner/center-1/gallery-new.jpg',
      ],
    );

    final merged = CenterStore.mergeCentersForTesting(
      local: local,
      remote: remote,
    );

    expect(merged.profileImageBase64, remote.profileImageBase64);
    expect(merged.imagesBase64, remote.imagesBase64);
  });

  test('dirty local media is preserved until cloud sync finishes', () {
    final local = buildCenter(
      id: 'center-2',
      profileImageBase64: 'centers/owner/center-2/profile-local.jpg',
      imagesBase64: const <String>[
        'centers/owner/center-2/gallery-local.jpg',
      ],
    );
    final remote = buildCenter(
      id: 'center-2',
      profileImageBase64: 'centers/owner/center-2/profile-remote.jpg',
      imagesBase64: const <String>[
        'centers/owner/center-2/gallery-remote.jpg',
      ],
    );

    final merged = CenterStore.mergeCentersForTesting(
      local: local,
      remote: remote,
      localDirty: true,
    );

    expect(merged.profileImageBase64, local.profileImageBase64);
    expect(merged.imagesBase64, local.imagesBase64);
  });

  test('local media fills in when remote media is empty', () {
    final local = buildCenter(
      id: 'center-3',
      profileImageBase64: 'centers/owner/center-3/profile-local.jpg',
      imagesBase64: const <String>[
        'centers/owner/center-3/gallery-local.jpg',
      ],
    );
    final remote = buildCenter(id: 'center-3');

    final merged = CenterStore.mergeCentersForTesting(
      local: local,
      remote: remote,
    );

    expect(merged.profileImageBase64, local.profileImageBase64);
    expect(merged.imagesBase64, local.imagesBase64);
  });
}
