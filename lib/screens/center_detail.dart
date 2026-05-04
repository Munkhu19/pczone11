import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/center.dart';
import '../utils/seat_labels.dart';
import '../widgets/center_image.dart';
import '../widgets/language_toggle_button.dart';
import 'booking_screen.dart';
import 'seat_screen.dart';

class CenterDetail extends StatelessWidget {
  final EsportCenter center;

  const CenterDetail({super.key, required this.center});

  String _bookingNoShowPolicyText(BuildContext context) {
    final isMn = Localizations.localeOf(context).languageCode == 'mn';
    final minutes = center.lateArrivalGraceMinutes;
    if (isMn) {
      return 'Эхлэх цагаас хойш $minutes минутын дотор ирээгүй бол захиалга автоматаар цуцлагдана.';
    }
    return 'If you do not arrive within $minutes minutes after the start time, the booking will be canceled automatically.';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final zones = buildSeatZonesForCenter(center);
    final primaryImage = center.primaryImage;
    final previewImages = center.allImages;

    return Scaffold(
      appBar: AppBar(
        title: Text(center.name),
        actions: const [AppHeaderActions()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GestureDetector(
            onTap: primaryImage == null
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => _CenterDetailImageViewer(
                          imagesBase64: previewImages,
                          initialIndex: 0,
                        ),
                      ),
                    );
                  },
            child: Center(
              child: CenterImage(
                imageBase64: primaryImage,
                width: 170,
                height: 170,
                borderRadius: 24,
              ),
            ),
          ),
          if (previewImages.length > 1) ...[
            const SizedBox(height: 18),
            _CenterImageGallery(imagesBase64: previewImages),
          ],
          const SizedBox(height: 20),
          Text(l10n.addressLabel(center.address), style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 10),
          Text(l10n.pcCountLabel(center.pcCount), style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 10),
          ...zones.map(
            (zone) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: zone.accentColor.withValues(alpha: 0.42),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${zone.title} x ${zone.seatCount}',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: zone.accentColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(l10n.pcSpecLabel(zone.spec), style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                      l10n.pricePerHourLabel(zone.pricePerHour),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _bookingNoShowPolicyText(context),
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 10),
          Text(l10n.phoneLabel(center.phone), style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SeatScreen(center: center),
                  ),
                );
              },
              child: Text(l10n.selectPcSeats),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookingScreen(center: center),
                  ),
                );
              },
              child: Text(l10n.makeBooking),
            ),
          ),
        ],
      ),
    );
  }
}

class _CenterImageGallery extends StatefulWidget {
  const _CenterImageGallery({required this.imagesBase64});

  final List<String> imagesBase64;

  @override
  State<_CenterImageGallery> createState() => _CenterImageGalleryState();
}

class _CenterImageGalleryState extends State<_CenterImageGallery> {
  int _currentIndex = 0;

  void _openViewer(int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _CenterDetailImageViewer(
          imagesBase64: widget.imagesBase64,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.imagesBase64;
    if (images.isEmpty) {
      return const CenterImage(
        imageBase64: null,
        width: double.infinity,
        height: 220,
        borderRadius: 22,
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            itemCount: images.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _openViewer(index),
                child: CenterImage(
                  imageBase64: images[index],
                  width: double.infinity,
                  height: 220,
                  borderRadius: 22,
                ),
              );
            },
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: List<Widget>.generate(images.length, (index) {
              final isActive = index == _currentIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: isActive ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF22C55E)
                      : Colors.white.withValues(alpha: 0.38),
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

class _CenterDetailImageViewer extends StatefulWidget {
  const _CenterDetailImageViewer({
    required this.imagesBase64,
    required this.initialIndex,
  });

  final List<String> imagesBase64;
  final int initialIndex;

  @override
  State<_CenterDetailImageViewer> createState() =>
      _CenterDetailImageViewerState();
}

class _CenterDetailImageViewerState extends State<_CenterDetailImageViewer> {
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
