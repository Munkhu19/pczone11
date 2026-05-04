import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart' as ll;

import '../data/center_store.dart';
import '../l10n/app_localizations.dart';
import '../models/center.dart';
import '../widgets/center_image.dart';
import '../widgets/language_toggle_button.dart';
import 'center_detail.dart';

class CenterMapScreen extends StatefulWidget {
  const CenterMapScreen({super.key});

  @override
  State<CenterMapScreen> createState() => _CenterMapScreenState();
}

class _CenterMapScreenState extends State<CenterMapScreen> {
  static const double _cardSpacing = 12;
  static const bool _useOpenStreetMapOnAndroid = false;
  static const double _bottomOverlayFocusOffsetMeters = 220;
  static const String _lightMapStyle = '''
[
  {
    "featureType": "poi",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "transit",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{"color": "#ffffff"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [{"color": "#dadce0"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#cfe8ff"}]
  },
  {
    "featureType": "landscape",
    "elementType": "geometry",
    "stylers": [{"color": "#f8fafc"}]
  }
]''';
  static const String _darkMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#0f172a"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#94a3b8"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#0f172a"}]
  },
  {
    "featureType": "poi",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "transit",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{"color": "#1e293b"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [{"color": "#334155"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#0b2948"}]
  }
]''';

  gmaps.GoogleMapController? _mapController;
  final fm.MapController _webMapController = fm.MapController();
  final ScrollController _cardsController = ScrollController();
  String? _selectedCenterId;
  StreamSubscription<Position>? _positionStreamSubscription;
  Position? _currentPosition;
  bool _isLocating = false;
  gmaps.BitmapDescriptor? _centerMarkerIcon;
  gmaps.BitmapDescriptor? _selectedCenterMarkerIcon;
  gmaps.BitmapDescriptor? _currentLocationMarkerIcon;

  bool get _useOpenStreetMap {
    if (kIsWeb) return true;
    return _useOpenStreetMapOnAndroid &&
        defaultTargetPlatform == TargetPlatform.android;
  }

  @override
  void initState() {
    super.initState();
    if (!_useOpenStreetMap) {
      _loadMarkerIcons();
    }
    _loadCurrentLocation();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _cardsController.dispose();
    _webMapController.dispose();
    super.dispose();
  }

  Future<void> _loadMarkerIcons() async {
    final centerMarkerIcon = await _createCenterMarkerDescriptor(
      fillColor: const Color(0xFFEA4335),
      borderColor: Colors.white,
      iconColor: Colors.white,
      size: 44,
    );
    final selectedCenterMarkerIcon = await _createCenterMarkerDescriptor(
      fillColor: const Color(0xFF2563EB),
      borderColor: Colors.white,
      iconColor: Colors.white,
      size: 50,
    );
    final currentLocationMarkerIcon = await _createCurrentLocationDescriptor();
    if (!mounted) return;
    setState(() {
      _centerMarkerIcon = centerMarkerIcon;
      _selectedCenterMarkerIcon = selectedCenterMarkerIcon;
      _currentLocationMarkerIcon = currentLocationMarkerIcon;
    });
  }

  Future<gmaps.BitmapDescriptor> _createCenterMarkerDescriptor({
    required Color fillColor,
    required Color borderColor,
    required Color iconColor,
    required double size,
  }) async {
    final pixelRatio = math.max(
      ui.PlatformDispatcher.instance.views.first.devicePixelRatio,
      2.0,
    );
    final scaledSize = size * pixelRatio;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final width = scaledSize;
    final height = scaledSize * 1.22;
    final circleRadius = scaledSize * 0.28;
    final center = Offset(width / 2, circleRadius + 6);

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    final fillPaint = Paint()..color = fillColor;
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = scaledSize * 0.055;

    final path = Path()
      ..moveTo(center.dx, height - 8)
      ..lineTo(center.dx - circleRadius * 0.78, center.dy + circleRadius * 0.64)
      ..arcToPoint(
        Offset(center.dx + circleRadius * 0.78, center.dy + circleRadius * 0.64),
        radius: Radius.circular(circleRadius * 1.3),
      )
      ..close();

    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.22), 10, false);
    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, fillPaint);
    canvas.drawCircle(center, circleRadius, fillPaint);
    canvas.drawCircle(center, circleRadius, borderPaint);
    canvas.drawPath(path, borderPaint);

    final iconPainter = TextPainter(textDirection: TextDirection.ltr);
    iconPainter.text = TextSpan(
      text: String.fromCharCode(Icons.storefront_rounded.codePoint),
      style: TextStyle(
        fontSize: scaledSize * 0.3,
        color: iconColor,
        fontFamily: Icons.storefront_rounded.fontFamily,
        package: Icons.storefront_rounded.fontPackage,
      ),
    );
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset(
        center.dx - iconPainter.width / 2,
        center.dy - iconPainter.height / 2,
      ),
    );

    final image = await recorder.endRecording().toImage(
          width.ceil(),
          height.ceil(),
        );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return gmaps.BitmapDescriptor.bytes(
      byteData!.buffer.asUint8List(),
      imagePixelRatio: pixelRatio,
    );
  }

  Future<gmaps.BitmapDescriptor> _createCurrentLocationDescriptor() async {
    final pixelRatio = math.max(
      ui.PlatformDispatcher.instance.views.first.devicePixelRatio,
      2.0,
    );
    const size = 46.0;
    final scaledSize = size * pixelRatio;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(scaledSize / 2, scaledSize / 2);

    final haloPaint =
        Paint()..color = const Color(0xFF4285F4).withValues(alpha: 0.16);
    final ringPaint = Paint()..color = Colors.white;
    final strokePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5 * pixelRatio;
    final dotPaint = Paint()..color = const Color(0xFF4285F4);

    canvas.drawCircle(center, 17 * pixelRatio, haloPaint);
    canvas.drawCircle(center, 9.5 * pixelRatio, ringPaint);
    canvas.drawCircle(center, 9.5 * pixelRatio, strokePaint);
    canvas.drawCircle(center, 4.8 * pixelRatio, dotPaint);

    final image = await recorder.endRecording().toImage(
          scaledSize.ceil(),
          scaledSize.ceil(),
        );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return gmaps.BitmapDescriptor.bytes(
      byteData!.buffer.asUint8List(),
      imagePixelRatio: pixelRatio,
    );
  }

  void _showLocationMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _startLocationStream() {
    if (_positionStreamSubscription != null) return;
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((position) {
      if (!mounted) return;
      setState(() {
        _currentPosition = position;
      });
    });
  }

  Future<void> _loadCurrentLocation({
    bool moveCamera = false,
    bool showErrors = false,
  }) async {
    if (_isLocating) return;
    setState(() {
      _isLocating = true;
    });
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (showErrors) {
          _showLocationMessage('Location service is off.');
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (showErrors) {
          _showLocationMessage('Location permission is required.');
        }
        return;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }
      if (position == null) {
        if (showErrors) {
          _showLocationMessage('Could not get your location.');
        }
        return;
      }

      if (!mounted) return;
      setState(() {
        _currentPosition = position;
      });
      _startLocationStream();
      if (moveCamera) {
        await _moveCamera(
          target: _offsetTargetAboveBottomOverlay(
            gmaps.LatLng(position.latitude, position.longitude),
          ),
          zoom: 15.8,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
  }

  Future<void> _moveCamera({
    required gmaps.LatLng target,
    double zoom = 15,
  }) async {
    if (_useOpenStreetMap) {
      _webMapController.move(
        ll.LatLng(target.latitude, target.longitude),
        zoom,
      );
      return;
    }

    final controller = _mapController;
    if (controller == null) return;
    await controller.animateCamera(
      gmaps.CameraUpdate.newCameraPosition(
        gmaps.CameraPosition(target: target, zoom: zoom),
      ),
    );
  }

  gmaps.LatLng _offsetTargetAboveBottomOverlay(gmaps.LatLng target) {
    final latitudeOffset =
        _bottomOverlayFocusOffsetMeters / 111320;
    return gmaps.LatLng(target.latitude - latitudeOffset, target.longitude);
  }

  void _moveToCurrentLocation() {
    final position = _currentPosition;
    if (position == null) {
      _loadCurrentLocation(moveCamera: true, showErrors: true);
      return;
    }
    _loadCurrentLocation();
    _moveCamera(
      target: _offsetTargetAboveBottomOverlay(
        gmaps.LatLng(position.latitude, position.longitude),
      ),
      zoom: 15.8,
    );
  }

  void _selectCenter(List<EsportCenter> centers, EsportCenter center) {
    setState(() {
      _selectedCenterId = center.id;
    });
    _moveCamera(
      target: _offsetTargetAboveBottomOverlay(
        gmaps.LatLng(center.latitude, center.longitude),
      ),
      zoom: 15,
    );

    final index = centers.indexWhere((item) => item.id == center.id);
    if (index >= 0 && _cardsController.hasClients) {
      final viewportWidth = MediaQuery.sizeOf(context).width;
      final cardWidth = math.min(viewportWidth - 32, 300.0);
      _cardsController.animateTo(
        index * (cardWidth + _cardSpacing),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Set<gmaps.Marker> _buildMarkers(
    BuildContext context,
    List<EsportCenter> centers,
    EsportCenter selectedCenter,
  ) {
    final markers = <gmaps.Marker>{};

    if (_currentPosition != null) {
      markers.add(
        gmaps.Marker(
          markerId: const gmaps.MarkerId('current_location'),
          position: gmaps.LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          infoWindow: const gmaps.InfoWindow(title: 'You'),
          icon: _currentLocationMarkerIcon ??
              gmaps.BitmapDescriptor.defaultMarkerWithHue(
                gmaps.BitmapDescriptor.hueAzure,
              ),
          anchor: const Offset(0.5, 0.5),
        ),
      );
    }

    for (final center in centers) {
      final isSelected = center.id == selectedCenter.id;
      markers.add(
        gmaps.Marker(
          markerId: gmaps.MarkerId(center.id),
          position: gmaps.LatLng(center.latitude, center.longitude),
          infoWindow: gmaps.InfoWindow(
            title: center.name,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CenterDetail(center: center),
                ),
              );
            },
          ),
          icon: isSelected
              ? (_selectedCenterMarkerIcon ??
                  gmaps.BitmapDescriptor.defaultMarkerWithHue(
                    gmaps.BitmapDescriptor.hueAzure,
                  ))
              : (_centerMarkerIcon ??
                  gmaps.BitmapDescriptor.defaultMarkerWithHue(
                    gmaps.BitmapDescriptor.hueRed,
                  )),
          anchor: const Offset(0.5, 0.92),
          zIndexInt: isSelected ? 2 : 1,
          onTap: () => _selectCenter(centers, center),
        ),
      );
    }

    return markers;
  }

  Set<gmaps.Circle> _buildCircles() {
    final position = _currentPosition;
    if (position == null) return const <gmaps.Circle>{};
    return <gmaps.Circle>{
      gmaps.Circle(
        circleId: const gmaps.CircleId('current_location_accuracy'),
        center: gmaps.LatLng(position.latitude, position.longitude),
        radius: math.max(position.accuracy, 32),
        fillColor: const Color(0xFF4285F4).withValues(alpha: 0.12),
        strokeColor: const Color(0xFF4285F4).withValues(alpha: 0.22),
        strokeWidth: 1,
      ),
    };
  }

  List<fm.Marker> _buildWebMarkers(
    BuildContext context,
    List<EsportCenter> centers,
    EsportCenter selectedCenter,
  ) {
    final markers = <fm.Marker>[];

    if (_currentPosition != null) {
      markers.add(
        fm.Marker(
          point: ll.LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          width: 46,
          height: 46,
          child: const _WebLocationMarker(),
        ),
      );
    }

    for (final center in centers) {
      final isSelected = center.id == selectedCenter.id;
      markers.add(
        fm.Marker(
          point: ll.LatLng(center.latitude, center.longitude),
          width: 58,
          height: 58,
          child: GestureDetector(
            onTap: () => _selectCenter(centers, center),
            onDoubleTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CenterDetail(center: center),
                ),
              );
            },
            child: _WebCenterMarker(
              isSelected: isSelected,
              label: center.name,
              imageSource: center.primaryImage,
            ),
          ),
        ),
      );
    }

    return markers;
  }

  String? _distanceLabelFor(EsportCenter center) {
    final position = _currentPosition;
    if (position == null) return null;

    final distanceInMeters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      center.latitude,
      center.longitude,
    );

    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    }

    final distanceInKm = distanceInMeters / 1000;
    final decimals = distanceInKm >= 10 ? 0 : 1;
    return '${distanceInKm.toStringAsFixed(decimals)} km';
  }

  List<EsportCenter> _sortCentersByDistance(List<EsportCenter> centers) {
    final position = _currentPosition;
    if (position == null) {
      return List<EsportCenter>.from(centers);
    }

    final sorted = List<EsportCenter>.from(centers);
    sorted.sort((a, b) {
      final distanceA = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        a.latitude,
        a.longitude,
      );
      final distanceB = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        b.latitude,
        b.longitude,
      );

      final comparison = distanceA.compareTo(distanceB);
      if (comparison != 0) {
        return comparison;
      }
      return a.name.compareTo(b.name);
    });
    return sorted;
  }

  String _reviewCountLabel(BuildContext context, int reviewCount) {
    final isMn = Localizations.localeOf(context).languageCode == 'mn';
    return isMn ? '$reviewCount үнэлгээ' : '$reviewCount reviews';
  }

  String _pcCountShortLabel(BuildContext context, int count) {
    final isMn = Localizations.localeOf(context).languageCode == 'mn';
    return isMn ? '$count PC' : '$count PCs';
  }

  String _priceShortLabel(BuildContext context, int price) {
    final isMn = Localizations.localeOf(context).languageCode == 'mn';
    return isMn ? '$price₮ / цаг' : '$price₮ / hour';
  }

  String _detailsLabel(BuildContext context) {
    final isMn = Localizations.localeOf(context).languageCode == 'mn';
    return isMn ? 'Дэлгэрэнгүй' : 'Details';
  }

  String _allCentersLabel(BuildContext context) {
    final isMn = Localizations.localeOf(context).languageCode == 'mn';
    return isMn ? 'Бүх төвүүд' : 'All centers';
  }

  String _centerCountLabel(BuildContext context, int count) {
    final isMn = Localizations.localeOf(context).languageCode == 'mn';
    return isMn ? '$count төв' : '$count total';
  }

  Widget _buildCenterCard(
    BuildContext context, {
    required EsportCenter center,
    required bool isSelected,
    required String? distanceLabel,
    required List<EsportCenter> centers,
    required double cardWidth,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF101826) : Colors.white;
    final borderColor = isSelected
        ? const Color(0xFF22C55E)
        : (isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.black.withValues(alpha: 0.06));
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark
        ? Colors.white.withValues(alpha: 0.76)
        : const Color(0xFF64748B);
    final imageSource = center.primaryImage;

    return SizedBox(
      width: cardWidth,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => _selectCenter(centers, center),
        onDoubleTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CenterDetail(center: center),
            ),
          );
        },
        child: AnimatedScale(
          duration: const Duration(milliseconds: 180),
          scale: isSelected ? 1 : 0.97,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isSelected ? 0.18 : 0.10),
                  blurRadius: isSelected ? 26 : 18,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 106,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(27),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CenterImage(
                          imageBase64: imageSource,
                          width: double.infinity,
                          height: double.infinity,
                          borderRadius: 0,
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.18),
                                Colors.black.withValues(alpha: 0.68),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _InfoPill(
                                    icon: Icons.star_rounded,
                                    label: center.rating.toStringAsFixed(1),
                                    backgroundColor: const Color(0xFFF59E0B)
                                        .withValues(alpha: 0.18),
                                    foregroundColor: const Color(0xFFFACC15),
                                  ),
                                  const Spacer(),
                                  if (distanceLabel != null)
                                    _InfoPill(
                                      icon: Icons.near_me_rounded,
                                      label: distanceLabel,
                                      backgroundColor: Colors.white.withValues(
                                        alpha: 0.12,
                                      ),
                                      foregroundColor: Colors.white,
                                    ),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                center.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _reviewCountLabel(context, center.reviewCount),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.86),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        center.address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 12.5,
                          height: 1.28,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _StatTile(
                              icon: Icons.desktop_windows_rounded,
                              label: _pcCountShortLabel(context, center.pcCount),
                              foregroundColor: textPrimary,
                              backgroundColor: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : const Color(0xFFF8FAFC),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatTile(
                              icon: Icons.payments_outlined,
                              label: _priceShortLabel(context, center.price),
                              foregroundColor: isDark
                                  ? const Color(0xFF5EEAD4)
                                  : const Color(0xFF0F766E),
                              backgroundColor: isDark
                                  ? const Color(0xFF0F766E).withValues(alpha: 0.14)
                                  : const Color(0xFFCCFBF1),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CenterDetail(center: center),
                              ),
                            );
                          },
                          icon: const Icon(Icons.open_in_new_rounded),
                          label: Text(_detailsLabel(context)),
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNativeMap(
    BuildContext context,
    List<EsportCenter> centers,
    EsportCenter selectedCenter,
  ) {
    final initialTarget = gmaps.LatLng(
      selectedCenter.latitude,
      selectedCenter.longitude,
    );

    return gmaps.GoogleMap(
      initialCameraPosition: gmaps.CameraPosition(
        target: initialTarget,
        zoom: 13.2,
      ),
      onMapCreated: (controller) {
        _mapController = controller;
      },
      style: Theme.of(context).brightness == Brightness.dark
          ? _darkMapStyle
          : _lightMapStyle,
      myLocationEnabled: _currentPosition != null,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: true,
      buildingsEnabled: true,
      indoorViewEnabled: true,
      trafficEnabled: false,
      mapType: gmaps.MapType.normal,
      markers: _buildMarkers(context, centers, selectedCenter),
      circles: _buildCircles(),
      onTap: (_) => FocusScope.of(context).unfocus(),
    );
  }

  Widget _buildWebMap(
    BuildContext context,
    List<EsportCenter> centers,
    EsportCenter selectedCenter,
  ) {
    final location = _currentPosition;
    return fm.FlutterMap(
      mapController: _webMapController,
      options: fm.MapOptions(
        initialCenter: ll.LatLng(
          selectedCenter.latitude,
          selectedCenter.longitude,
        ),
        initialZoom: 13.2,
        onTap: (tapPosition, point) => FocusScope.of(context).unfocus(),
      ),
      children: [
        fm.TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'pc_app',
        ),
        if (location != null)
          fm.CircleLayer(
            circles: [
              fm.CircleMarker(
                point: ll.LatLng(location.latitude, location.longitude),
                radius: math.max(location.accuracy, 32),
                useRadiusInMeter: true,
                color: const Color(0xFF4285F4).withValues(alpha: 0.12),
                borderColor: const Color(0xFF4285F4).withValues(alpha: 0.22),
                borderStrokeWidth: 1,
              ),
            ],
          ),
        fm.MarkerLayer(
          markers: _buildWebMarkers(context, centers, selectedCenter),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;
    final cardBottomOffset = bottomSafeArea + 10;
    final cardWidth = math.min(MediaQuery.sizeOf(context).width - 32, 300.0);

    return ValueListenableBuilder<List<EsportCenter>>(
      valueListenable: CenterStore.centersNotifier,
      builder: (context, centers, _) {
        final orderedCenters = _sortCentersByDistance(centers);

        if (orderedCenters.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: Text(l10n.mapTitle),
              actions: const [AppHeaderActions()],
            ),
            body: Center(
              child: Text(
                l10n.noCentersFound,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          );
        }

        final selectedCenter = orderedCenters.cast<EsportCenter?>().firstWhere(
              (center) => center?.id == _selectedCenterId,
              orElse: () => orderedCenters.first,
            )!;

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.mapTitle),
            actions: const [AppHeaderActions()],
          ),
          body: Stack(
            children: [
              Positioned.fill(
                child: _useOpenStreetMap
                    ? _buildWebMap(context, orderedCenters, selectedCenter)
                    : _buildNativeMap(context, orderedCenters, selectedCenter),
              ),
              Positioned(
                top: 14,
                right: 14,
                child: FloatingActionButton.small(
                  heroTag: 'map_focus_selected',
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1F2937),
                  onPressed: _moveToCurrentLocation,
                  child: _isLocating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF1F2937),
                          ),
                        )
                      : const Icon(Icons.my_location_rounded),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: cardBottomOffset,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xEE101826)
                            : Colors.white.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Text(
                            _allCentersLabel(context),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E).withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _centerCountLabel(context, orderedCenters.length),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 286,
                      child: ListView.separated(
                        controller: _cardsController,
                        scrollDirection: Axis.horizontal,
                        itemCount: orderedCenters.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: _cardSpacing),
                        itemBuilder: (context, index) {
                          final center = orderedCenters[index];
                          return _buildCenterCard(
                            context,
                            center: center,
                            isSelected: center.id == selectedCenter.id,
                            distanceLabel: _distanceLabelFor(center),
                            centers: orderedCenters,
                            cardWidth: cardWidth,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foregroundColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  final IconData icon;
  final String label;
  final Color foregroundColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: foregroundColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WebCenterMarker extends StatelessWidget {
  const _WebCenterMarker({
    required this.isSelected,
    required this.label,
    required this.imageSource,
  });

  final bool isSelected;
  final String label;
  final String? imageSource;

  @override
  Widget build(BuildContext context) {
    final ringColor =
        isSelected ? const Color(0xFF2563EB) : const Color(0xFFEA4335);
    return Tooltip(
      message: label,
      child: Container(
        decoration: BoxDecoration(
          color: ringColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: ClipOval(
            child: imageSource == null || imageSource!.isEmpty
                ? Container(
                    color: ringColor,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  )
                : CenterImage(
                    imageBase64: imageSource,
                    width: 48,
                    height: 48,
                    borderRadius: 999,
                    fit: BoxFit.cover,
                  ),
          ),
        ),
      ),
    );
  }
}

class _WebLocationMarker extends StatelessWidget {
  const _WebLocationMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF4285F4), width: 4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4285F4).withValues(alpha: 0.22),
            blurRadius: 14,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Color(0xFF4285F4),
            shape: BoxShape.circle,
          ),
          child: SizedBox(width: 12, height: 12),
        ),
      ),
    );
  }
}
