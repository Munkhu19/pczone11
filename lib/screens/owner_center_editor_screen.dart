import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/firebase_state.dart';
import '../l10n/app_localizations.dart';
import '../models/center.dart';
import '../utils/document_ids.dart';
import '../widgets/center_image.dart';
import '../widgets/language_toggle_button.dart';

class OwnerCenterEditorScreen extends StatefulWidget {
  const OwnerCenterEditorScreen({
    super.key,
    this.center,
    required this.ownerEmail,
  });

  final EsportCenter? center;
  final String ownerEmail;

  @override
  State<OwnerCenterEditorScreen> createState() =>
      _OwnerCenterEditorScreenState();
}

class _OwnerCenterEditorScreenState extends State<OwnerCenterEditorScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  static const double _defaultLatitude = 47.9184676;
  static const double _defaultLongitude = 106.9177016;
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _pcCountController;
  late final TextEditingController _pcSpecController;
  late final TextEditingController _priceController;
  late final TextEditingController _vipCountController;
  late final TextEditingController _stageCountController;
  late final TextEditingController _vipSpecController;
  late final TextEditingController _stageSpecController;
  late final TextEditingController _vipPriceController;
  late final TextEditingController _stagePriceController;
  late final TextEditingController _phoneController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;
  late final TextEditingController _graceMinutesController;
  String? _profileImageBase64;
  List<String> _imagesBase64 = <String>[];
  final Set<int> _selectedImageIndexes = <int>{};
  bool _isSubmitting = false;

  bool get _selectionMode => _selectedImageIndexes.isNotEmpty;

  void _showImageUploadWarning() {
    final isMn = Localizations.localeOf(context).languageCode == 'mn';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isMn
              ? 'Зураг cloud руу ороогүй ч төвийн мэдээллийг хадгална.'
              : 'Image upload failed, but the center details will still be saved.',
        ),
      ),
    );
  }

  String _graceMinutesLabel(BuildContext context) {
    final isMn = Localizations.localeOf(context).languageCode == 'mn';
    return isMn
        ? 'Хоцролт зөвшөөрөх хугацаа (минут)'
        : 'Late arrival limit (minutes)';
  }

  String _zoneCountLabel(BuildContext context, String zone) {
    final isMn = Localizations.localeOf(context).languageCode == 'mn';
    return isMn ? '$zone ширээний тоо' : '$zone seat count';
  }

  String _zoneSpecLabel(BuildContext context, String zone) {
    final isMn = Localizations.localeOf(context).languageCode == 'mn';
    return isMn ? '$zone PC үзүүлэлт' : '$zone PC spec';
  }

  String _zonePriceLabel(BuildContext context, String zone) {
    final isMn = Localizations.localeOf(context).languageCode == 'mn';
    return isMn ? '$zone үнэ / цаг' : '$zone price / hour';
  }

  @override
  void initState() {
    super.initState();
    final center = widget.center;
    _nameController = TextEditingController(text: center?.name ?? '');
    _addressController = TextEditingController(text: center?.address ?? '');
    _pcCountController = TextEditingController(
      text: center?.pcCount.toString() ?? '',
    );
    _pcSpecController = TextEditingController(text: center?.pcSpec ?? '');
    _priceController = TextEditingController(
      text: center?.price.toString() ?? '',
    );
    _vipCountController = TextEditingController(
      text: (center?.vipCount ?? 0).toString(),
    );
    _stageCountController = TextEditingController(
      text: (center?.stageCount ?? 0).toString(),
    );
    _vipSpecController = TextEditingController(
      text: center?.vipSpec ?? center?.pcSpec ?? '',
    );
    _stageSpecController = TextEditingController(
      text: center?.stageSpec ?? center?.pcSpec ?? '',
    );
    _vipPriceController = TextEditingController(
      text: (center?.vipPrice ?? center?.price ?? 0).toString(),
    );
    _stagePriceController = TextEditingController(
      text: (center?.stagePrice ?? center?.price ?? 0).toString(),
    );
    _phoneController = TextEditingController(text: center?.phone ?? '');
    _latitudeController = TextEditingController(
      text: center?.latitude.toString() ?? '',
    );
    _longitudeController = TextEditingController(
      text: center?.longitude.toString() ?? '',
    );
    _graceMinutesController = TextEditingController(
      text: (center?.lateArrivalGraceMinutes ?? 15).toString(),
    );
    _profileImageBase64 = center?.profileImageBase64;
    _imagesBase64 = List<String>.from(center?.imagesBase64 ?? const <String>[]);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _pcCountController.dispose();
    _pcSpecController.dispose();
    _priceController.dispose();
    _vipCountController.dispose();
    _stageCountController.dispose();
    _vipSpecController.dispose();
    _stageSpecController.dispose();
    _vipPriceController.dispose();
    _stagePriceController.dispose();
    _phoneController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _graceMinutesController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
        maxWidth: 1600,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _profileImageBase64 = base64Encode(bytes);
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.ownerCenterImageFailed)));
    }
  }

  void _removeProfileImage() {
    setState(() {
      _profileImageBase64 = null;
    });
  }

  Future<void> _pickImages() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final picked = await _imagePicker.pickMultiImage(
        imageQuality: 82,
        maxWidth: 1600,
      );
      if (picked.isEmpty) return;
      final nextImages = <String>[];
      for (final file in picked) {
        final bytes = await file.readAsBytes();
        nextImages.add(base64Encode(bytes));
      }
      if (!mounted) return;
      setState(() {
        _imagesBase64 = <String>[..._imagesBase64, ...nextImages];
        _selectedImageIndexes.clear();
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.ownerCenterImageFailed)));
    }
  }

  void _toggleImageSelection(int index) {
    setState(() {
      if (_selectedImageIndexes.contains(index)) {
        _selectedImageIndexes.remove(index);
      } else {
        _selectedImageIndexes.add(index);
      }
    });
  }

  void _enterSelectionMode(int index) {
    setState(() {
      _selectedImageIndexes.add(index);
    });
  }

  void _openImageViewer(int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _CenterImageViewer(
          imagesBase64: _imagesBase64,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  void _removeSelectedImages() {
    if (_selectedImageIndexes.isEmpty) return;
    final nextImages = <String>[];
    for (var i = 0; i < _imagesBase64.length; i++) {
      if (!_selectedImageIndexes.contains(i)) {
        nextImages.add(_imagesBase64[i]);
      }
    }
    setState(() {
      _imagesBase64 = nextImages;
      _selectedImageIndexes.clear();
    });
  }

  Future<String?> _uploadCenterImage({
    required String data,
    required String path,
  }) async {
    if (data.isEmpty) return null;
    if (data.startsWith('http://') || data.startsWith('https://')) {
      return data;
    }
    if (data.startsWith('gs://')) {
      return data;
    }
    if (data.startsWith('centers/')) {
      return data;
    }

    final bytes = base64Decode(data);
    final imageFormat = _detectImageFormat(bytes);
    final resolvedPath = _normalizeStoragePath(
      path: path,
      extension: imageFormat.extension,
    );
    final ref = FirebaseStorage.instance.ref().child(resolvedPath);
    await ref.putData(
      bytes,
      SettableMetadata(contentType: imageFormat.contentType),
    );
    return resolvedPath;
  }

  _StoredImageFormat _detectImageFormat(Uint8List bytes) {
    if (bytes.length >= 4 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return const _StoredImageFormat(
        extension: 'png',
        contentType: 'image/png',
      );
    }
    if (bytes.length >= 4 &&
        bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38) {
      return const _StoredImageFormat(
        extension: 'gif',
        contentType: 'image/gif',
      );
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return const _StoredImageFormat(
        extension: 'webp',
        contentType: 'image/webp',
      );
    }
    return const _StoredImageFormat(
      extension: 'jpg',
      contentType: 'image/jpeg',
    );
  }

  String _normalizeStoragePath({
    required String path,
    required String extension,
  }) {
    final dotIndex = path.lastIndexOf('.');
    final basePath = dotIndex == -1 ? path : path.substring(0, dotIndex);
    return '$basePath.$extension';
  }

  String _galleryUploadPath({
    required User user,
    required String centerId,
    required int index,
  }) {
    final uniqueSuffix = DateTime.now().microsecondsSinceEpoch;
    return 'centers/${user.uid}/$centerId/gallery_${uniqueSuffix}_$index.jpg';
  }

  List<String> _normalizedImageRefs(Iterable<String> images) {
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

  Future<void> _submit() async {
    final isMn = Localizations.localeOf(context).languageCode == 'mn';
    final pcCount = int.tryParse(_pcCountController.text.trim());
    final price = int.tryParse(_priceController.text.trim());
    final vipCount = int.tryParse(_vipCountController.text.trim());
    final stageCount = int.tryParse(_stageCountController.text.trim());
    final vipPrice = int.tryParse(_vipPriceController.text.trim());
    final stagePrice = int.tryParse(_stagePriceController.text.trim());
    final graceMinutes = int.tryParse(_graceMinutesController.text.trim());
    final latitude =
        double.tryParse(_latitudeController.text.trim()) ?? _defaultLatitude;
    final longitude =
        double.tryParse(_longitudeController.text.trim()) ?? _defaultLongitude;

    final validationMessage = _nameController.text.trim().isEmpty
        ? (isMn ? 'Төвийн нэрээ оруулна уу.' : 'Enter the center name.')
        : _addressController.text.trim().isEmpty
        ? (isMn ? 'Төвийн хаягаа оруулна уу.' : 'Enter the center address.')
        : _pcSpecController.text.trim().isEmpty
        ? (isMn ? 'PC үзүүлэлтээ оруулна уу.' : 'Enter the PC spec.')
        : pcCount == null || pcCount <= 0
        ? (isMn
              ? 'PC тоо 1-ээс их байх ёстой.'
              : 'PC count must be greater than 0.')
        : price == null || price < 0
        ? (isMn ? 'Цагийн үнэ зөв байх ёстой.' : 'Price must be valid.')
        : vipCount == null || vipCount < 0
        ? (isMn
              ? 'VIP ширээний тоо зөв байх ёстой.'
              : 'VIP seat count must be valid.')
        : stageCount == null || stageCount < 0
        ? (isMn
              ? 'Stage ширээний тоо зөв байх ёстой.'
              : 'Stage seat count must be valid.')
        : vipCount + stageCount > pcCount
        ? (isMn
              ? 'VIP + Stage ширээний тоо нийт PC тооноос их байж болохгүй.'
              : 'VIP + Stage seats cannot be greater than total PCs.')
        : vipPrice == null || vipPrice < 0
        ? (isMn ? 'VIP үнэ зөв байх ёстой.' : 'VIP price must be valid.')
        : stagePrice == null || stagePrice < 0
        ? (isMn ? 'Stage үнэ зөв байх ёстой.' : 'Stage price must be valid.')
        : graceMinutes == null || graceMinutes < 0
        ? (isMn
              ? 'Хоцролтын хугацаа зөв байх ёстой.'
              : 'Late arrival limit must be valid.')
        : null;

    if (validationMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validationMessage)));
      return;
    }

    final int resolvedPcCount = pcCount!;
    final int resolvedPrice = price!;
    final int resolvedVipCount = vipCount!;
    final int resolvedStageCount = stageCount!;
    final int resolvedVipPrice = vipPrice!;
    final int resolvedStagePrice = stagePrice!;
    final int resolvedGraceMinutes = graceMinutes!;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final centerId =
          widget.center?.id ?? readableDocumentId(_nameController.text.trim());
      var profileImage = _profileImageBase64;
      var galleryImages = List<String>.from(_imagesBase64);

      if (firebaseAvailable) {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception('Not signed in.');
        }

        if (profileImage != null && profileImage.isNotEmpty) {
          try {
            profileImage = await _uploadCenterImage(
              data: profileImage,
              path: 'centers/${user.uid}/$centerId/profile.jpg',
            );
          } on FirebaseException catch (_) {
            profileImage = null;
            if (mounted) _showImageUploadWarning();
          }
        }

        final uploadedGallery = <String>[];
        for (var i = 0; i < galleryImages.length; i++) {
          try {
            final uploaded = await _uploadCenterImage(
              data: galleryImages[i],
              path: _galleryUploadPath(
                user: user,
                centerId: centerId,
                index: i,
              ),
            );
            if (uploaded != null && uploaded.isNotEmpty) {
              uploadedGallery.add(uploaded);
            }
          } on FirebaseException catch (_) {
            if (mounted) _showImageUploadWarning();
          }
        }
        galleryImages = _normalizedImageRefs(uploadedGallery);
      }

      galleryImages = _normalizedImageRefs(galleryImages);

      final center = EsportCenter(
        id: centerId,
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        pcCount: resolvedPcCount,
        pcSpec: _pcSpecController.text.trim(),
        price: resolvedPrice,
        vipCount: resolvedVipCount,
        stageCount: resolvedStageCount,
        vipSpec: _vipSpecController.text.trim(),
        stageSpec: _stageSpecController.text.trim(),
        vipPrice: resolvedVipPrice,
        stagePrice: resolvedStagePrice,
        phone: _phoneController.text.trim(),
        latitude: latitude,
        longitude: longitude,
        ownerEmail: widget.ownerEmail.trim(),
        profileImageBase64: profileImage,
        imagesBase64: galleryImages,
        lateArrivalGraceMinutes: resolvedGraceMinutes,
      );

      if (!mounted) return;
      Navigator.of(context).pop(center);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Storage error: ${e.code}${e.message == null ? '' : ' - ${e.message}'}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final previewImages = <String>[
      if (_profileImageBase64 != null && _profileImageBase64!.isNotEmpty)
        _profileImageBase64!,
      ..._imagesBase64.where((image) => image != _profileImageBase64),
    ];
    InputDecoration decoration(String label) =>
        InputDecoration(labelText: label);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.center == null ? l10n.ownerAddCenter : l10n.ownerEditCenter,
        ),
        actions: [
          const AppHeaderActions(),
          if (_selectionMode)
            IconButton(
              onPressed: () {
                setState(() {
                  _selectedImageIndexes.clear();
                });
              },
              icon: const Icon(Icons.close),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.ownerCenterProfileImageLabel,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: previewImages.isEmpty
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => _CenterImageViewer(
                                imagesBase64: previewImages,
                                initialIndex: 0,
                              ),
                            ),
                          );
                        },
                  child: Center(
                    child: CenterImage(
                      imageBase64:
                          _profileImageBase64 ??
                          (_imagesBase64.isNotEmpty
                              ? _imagesBase64.first
                              : null),
                      width: 170,
                      height: 170,
                      borderRadius: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickProfileImage,
                      icon: const Icon(Icons.person_rounded),
                      label: Text(
                        previewImages.isEmpty
                            ? l10n.ownerCenterAddProfileImage
                            : l10n.ownerCenterChangeProfileImage,
                      ),
                    ),
                    if (_profileImageBase64 != null)
                      OutlinedButton.icon(
                        onPressed: _removeProfileImage,
                        icon: const Icon(Icons.delete_outline),
                        label: Text(l10n.ownerCenterRemoveProfileImage),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.ownerCenterGalleryLabel,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 10),
                if (_imagesBase64.isEmpty)
                  const CenterImage(
                    imageBase64: null,
                    width: double.infinity,
                    height: 180,
                    borderRadius: 20,
                  )
                else
                  SizedBox(
                    height: 180,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _imagesBase64.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final isSelected = _selectedImageIndexes.contains(
                          index,
                        );
                        return GestureDetector(
                          onTap: () {
                            if (_selectionMode) {
                              _toggleImageSelection(index);
                            } else {
                              _openImageViewer(index);
                            }
                          },
                          onLongPress: () => _enterSelectionMode(index),
                          child: Stack(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFEF4444)
                                        : Colors.white.withValues(alpha: 0.14),
                                    width: isSelected ? 3 : 1,
                                  ),
                                ),
                                child: CenterImage(
                                  imageBase64: _imagesBase64[index],
                                  width: 220,
                                  height: 180,
                                  borderRadius: 20,
                                ),
                              ),
                              if (_selectionMode)
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: CircleAvatar(
                                    radius: 14,
                                    backgroundColor: isSelected
                                        ? const Color(0xFFEF4444)
                                        : Colors.black.withValues(alpha: 0.42),
                                    child: Icon(
                                      isSelected
                                          ? Icons.check_rounded
                                          : Icons
                                                .radio_button_unchecked_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),
                if (_imagesBase64.isNotEmpty)
                  Text(
                    l10n.ownerCenterImageSelectionHint,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                if (_imagesBase64.isNotEmpty) const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(l10n.ownerCenterAddImages),
                    ),
                    if (_imagesBase64.isNotEmpty)
                      OutlinedButton.icon(
                        onPressed: _selectedImageIndexes.isEmpty
                            ? null
                            : _removeSelectedImages,
                        icon: const Icon(Icons.delete_outline),
                        label: Text(l10n.ownerCenterRemoveSelectedImages),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: decoration(l10n.name),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _addressController,
            decoration: decoration(l10n.ownerCenterAddress),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pcCountController,
            keyboardType: TextInputType.number,
            decoration: decoration(l10n.ownerCenterPcCount),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pcSpecController,
            decoration: decoration(l10n.ownerCenterPcSpec),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: decoration(l10n.ownerCenterPrice),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _vipCountController,
            keyboardType: TextInputType.number,
            decoration: decoration(_zoneCountLabel(context, 'VIP')),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _vipSpecController,
            decoration: decoration(_zoneSpecLabel(context, 'VIP')),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _vipPriceController,
            keyboardType: TextInputType.number,
            decoration: decoration(_zonePriceLabel(context, 'VIP')),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _stageCountController,
            keyboardType: TextInputType.number,
            decoration: decoration(_zoneCountLabel(context, 'Stage')),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _stageSpecController,
            decoration: decoration(_zoneSpecLabel(context, 'Stage')),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _stagePriceController,
            keyboardType: TextInputType.number,
            decoration: decoration(_zonePriceLabel(context, 'Stage')),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _graceMinutesController,
            keyboardType: TextInputType.number,
            decoration: decoration(_graceMinutesLabel(context)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            decoration: decoration(l10n.phone),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _latitudeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: decoration(l10n.ownerCenterLatitude),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _longitudeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: decoration(l10n.ownerCenterLongitude),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.ownerSaveCenter),
          ),
        ],
      ),
    );
  }
}

class _CenterImageViewer extends StatefulWidget {
  const _CenterImageViewer({
    required this.imagesBase64,
    required this.initialIndex,
  });

  final List<String> imagesBase64;
  final int initialIndex;

  @override
  State<_CenterImageViewer> createState() => _CenterImageViewerState();
}

class _CenterImageViewerState extends State<_CenterImageViewer> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_currentIndex + 1}/${widget.imagesBase64.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.imagesBase64.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Center(
              child: CenterImage(
                imageBase64: widget.imagesBase64[index],
                width: double.infinity,
                height: double.infinity,
                borderRadius: 0,
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StoredImageFormat {
  const _StoredImageFormat({
    required this.extension,
    required this.contentType,
  });

  final String extension;
  final String contentType;
}
