import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CenterImage extends StatefulWidget {
  const CenterImage({
    super.key,
    required this.imageBase64,
    this.width,
    this.height,
    this.borderRadius = 16,
    this.fit = BoxFit.cover,
  });

  final String? imageBase64;
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxFit fit;

  @override
  State<CenterImage> createState() => _CenterImageState();
}

class _CenterImageState extends State<CenterImage> {
  Uint8List? _memoryBytes;
  String? _networkUrl;
  bool _isLoading = false;
  bool _hasError = false;
  int _requestToken = 0;

  @override
  void initState() {
    super.initState();
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant CenterImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageBase64 != widget.imageBase64) {
      _resolveImage();
    }
  }

  Future<void> _resolveImage() async {
    final raw = widget.imageBase64?.trim();
    final requestToken = ++_requestToken;

    if (raw == null || raw.isEmpty) {
      if (!mounted) return;
      setState(() {
        _memoryBytes = null;
        _networkUrl = null;
        _isLoading = false;
        _hasError = false;
      });
      return;
    }

    try {
      final bytes = base64Decode(raw);
      if (!mounted || requestToken != _requestToken) return;
      setState(() {
        _memoryBytes = bytes;
        _networkUrl = null;
        _isLoading = false;
        _hasError = false;
      });
      return;
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _memoryBytes = null;
      _networkUrl = null;
      _isLoading = true;
      _hasError = false;
    });

    try {
      if (!kIsWeb) {
        final resolvedBytes = await _resolveStorageBytes(raw);
        if (!mounted || requestToken != _requestToken) return;
        if (resolvedBytes != null) {
          setState(() {
            _memoryBytes = resolvedBytes;
            _networkUrl = null;
            _isLoading = false;
            _hasError = false;
          });
          return;
        }
      }

      final resolved = await _resolveStorageUrl(raw);
      if (!mounted || requestToken != _requestToken) return;
      setState(() {
        _memoryBytes = null;
        _networkUrl = resolved;
        _isLoading = false;
        _hasError = resolved == null || resolved.isEmpty;
      });
    } catch (_) {
      if (!mounted || requestToken != _requestToken) return;
      setState(() {
        _memoryBytes = null;
        _networkUrl = null;
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<String?> _resolveStorageUrl(String raw) async {
    final storagePath = _extractFirebaseStoragePath(raw);
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      if (storagePath == null) {
        return raw;
      }
      for (final candidate in _candidateStoragePaths(storagePath)) {
        try {
          return await FirebaseStorage.instance
              .ref()
              .child(candidate)
              .getDownloadURL();
        } on FirebaseException {
          continue;
        }
      }
      return _publicStorageUrl(storagePath) ?? raw;
    }

    if (raw.startsWith('gs://')) {
      try {
        return await FirebaseStorage.instance.refFromURL(raw).getDownloadURL();
      } on FirebaseException {
        return _publicStorageUrl(raw);
      }
    }

    for (final candidate in _candidateStoragePaths(raw)) {
      try {
        return await FirebaseStorage.instance
            .ref()
            .child(candidate)
            .getDownloadURL();
      } on FirebaseException {
        continue;
      }
    }
    return _publicStorageUrl(raw);
  }

  Future<Uint8List?> _resolveStorageBytes(String raw) async {
    final storagePath = _extractFirebaseStoragePath(raw);
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      if (storagePath == null) {
        return null;
      }
      for (final candidate in _candidateStoragePaths(storagePath)) {
        try {
          return await FirebaseStorage.instance
              .ref()
              .child(candidate)
              .getData();
        } on FirebaseException {
          continue;
        }
      }
      return null;
    }

    if (raw.startsWith('gs://')) {
      try {
        return await FirebaseStorage.instance.refFromURL(raw).getData();
      } on FirebaseException {
        return null;
      }
    }

    for (final candidate in _candidateStoragePaths(raw)) {
      try {
        return await FirebaseStorage.instance.ref().child(candidate).getData();
      } on FirebaseException {
        continue;
      }
    }
    return null;
  }

  String? _extractFirebaseStoragePath(String raw) {
    final uri = Uri.tryParse(raw);
    if (uri == null) return null;

    if (uri.scheme == 'gs') {
      final bucketAndPath = '${uri.host}${uri.path}';
      final slashIndex = bucketAndPath.indexOf('/');
      if (slashIndex == -1 || slashIndex == bucketAndPath.length - 1) {
        return null;
      }
      return bucketAndPath.substring(slashIndex + 1);
    }

    if (!raw.startsWith('http://') && !raw.startsWith('https://')) {
      return null;
    }

    final segments = uri.pathSegments;
    final objectIndex = segments.indexOf('o');
    if (objectIndex == -1 || objectIndex + 1 >= segments.length) {
      return null;
    }

    return Uri.decodeComponent(segments[objectIndex + 1]);
  }

  String? _publicStorageUrl(String raw) {
    final storagePath = _extractFirebaseStoragePath(raw) ?? raw.trim();
    if (storagePath.isEmpty) return null;

    var bucket = Firebase.app().options.storageBucket;
    if (raw.startsWith('gs://')) {
      final uri = Uri.tryParse(raw);
      if (uri != null && uri.host.isNotEmpty) {
        bucket = uri.host;
      }
    }
    if (bucket == null || bucket.isEmpty) return null;

    return Uri.https(
      'firebasestorage.googleapis.com',
      '/v0/b/$bucket/o/${Uri.encodeComponent(storagePath)}',
      const <String, String>{'alt': 'media'},
    ).toString();
  }

  Iterable<String> _candidateStoragePaths(String rawPath) sync* {
    final normalized = rawPath.trim();
    if (normalized.isEmpty) {
      return;
    }

    final dotIndex = normalized.lastIndexOf('.');
    final hasExtension =
        dotIndex > normalized.lastIndexOf('/') &&
        dotIndex != normalized.length - 1;
    final basePath = hasExtension
        ? normalized.substring(0, dotIndex)
        : normalized;
    final currentExtension = hasExtension
        ? normalized.substring(dotIndex + 1).toLowerCase()
        : null;
    final candidates = <String>[
      if (hasExtension) normalized,
      if (currentExtension != 'png') '$basePath.png',
      if (currentExtension != 'jpg') '$basePath.jpg',
      if (currentExtension != 'jpeg') '$basePath.jpeg',
      if (currentExtension != 'webp') '$basePath.webp',
      if (currentExtension != 'gif') '$basePath.gif',
      if (!hasExtension) normalized,
    ];

    final seen = <String>{};
    for (final candidate in candidates) {
      if (seen.add(candidate)) {
        yield candidate;
      }
    }
  }

  Widget _placeholder({required IconData icon}) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1D4ED8).withValues(alpha: 0.55),
            const Color(0xFF7C3AED).withValues(alpha: 0.45),
          ],
        ),
      ),
      child: Icon(icon, color: Colors.white, size: 34),
    );
  }

  @override
  Widget build(BuildContext context) {
    final raw = widget.imageBase64?.trim();
    if (raw == null || raw.isEmpty) {
      return _placeholder(icon: Icons.storefront_rounded);
    }

    if (_isLoading) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          color: const Color(0xFF172033),
        ),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_memoryBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Image.memory(
          _memoryBytes!,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
        ),
      );
    }

    if (_networkUrl != null && _networkUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Image.network(
          _networkUrl!,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                color: const Color(0xFF172033),
              ),
              child: const Icon(
                Icons.broken_image_outlined,
                color: Colors.white70,
              ),
            );
          },
        ),
      );
    }

    if (_hasError) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          color: const Color(0xFF172033),
        ),
        child: const Icon(Icons.broken_image_outlined, color: Colors.white70),
      );
    }

    return _placeholder(icon: Icons.storefront_rounded);
  }
}
