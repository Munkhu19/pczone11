import 'package:flutter/material.dart';

import '../data/booking_store.dart';
import '../l10n/app_localizations.dart';
import '../models/booking_record.dart';
import '../models/center.dart';
import '../utils/seat_labels.dart';
import '../widgets/language_toggle_button.dart';
import 'booking_screen.dart';

class SeatScreen extends StatefulWidget {
  final EsportCenter center;

  const SeatScreen({super.key, required this.center});

  @override
  State<SeatScreen> createState() => _SeatScreenState();
}

class _SeatScreenState extends State<SeatScreen> {
  final TextEditingController _durationController = TextEditingController(
    text: '1',
  );
  late DateTime _previewStartAt;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().add(const Duration(hours: 1));
    _previewStartAt = DateTime(now.year, now.month, now.day, now.hour);
  }

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  Future<void> _pickPreviewStartAt() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      initialDate: _previewStartAt,
    );
    if (!mounted || date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_previewStartAt),
    );
    if (!mounted || time == null) return;

    setState(() {
      _previewStartAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.selectSeatsTitle(widget.center.name)),
        actions: const [AppHeaderActions()],
      ),
      body: StreamBuilder<List<BookingRecord>>(
        stream: BookingStore.bookingHistoryStream(),
        initialData: BookingStore.bookingHistory(centerId: widget.center.id),
        builder: (context, historySnapshot) {
          return StreamBuilder<Set<int>>(
            stream: BookingStore.blockedSeatsStream(widget.center.id),
            initialData: BookingStore.blockedSeats(widget.center.id),
            builder: (context, blockedSnapshot) {
              final blockedSeats = blockedSnapshot.data ?? <int>{};
              final selectedSeats = BookingStore.selectedSeats(widget.center.id);
              final durationHours =
                  int.tryParse(_durationController.text.trim()) ?? 1;
              final seatZones = buildSeatZonesForCenter(widget.center);
              final scheduledBookedSeats = durationHours <= 0
                  ? <int>{}
                  : BookingStore.scheduledBookedSeats(
                      centerId: widget.center.id,
                      startAt: _previewStartAt,
                      durationHours: durationHours,
                    );

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: _pickPreviewStartAt,
                          borderRadius: BorderRadius.circular(15),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: l10n.bookingStartTime,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_formatDateTime(_previewStartAt)),
                                const Icon(Icons.schedule),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _durationController,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: l10n.playDurationHours,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            _Legend(
                              color: Colors.grey.shade300,
                              label: l10n.ownerSeatAvailable,
                            ),
                            _Legend(
                              color: Colors.green,
                              label: l10n.seatSelectedLabel,
                            ),
                            _Legend(
                              color: Colors.red,
                              label: l10n.seatUnavailableForTime,
                            ),
                            _Legend(
                              color: Colors.orange,
                              label: l10n.ownerSeatBlocked,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      itemCount: seatZones.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final zone = seatZones[index];
                        return _SeatZoneSection(
                          zone: zone,
                          blockedSeats: blockedSeats,
                          scheduledBookedSeats: scheduledBookedSeats,
                          selectedSeats: selectedSeats,
                          enabled: durationHours > 0,
                          l10n: l10n,
                          onSeatTap: (seatIndex) {
                            if (durationHours <= 0) return;
                            setState(() {
                              BookingStore.toggleSeat(widget.center.id, seatIndex);
                            });
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: durationHours <= 0
                            ? null
                            : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => BookingScreen(
                                      center: widget.center,
                                      initialStartAt: _previewStartAt,
                                      initialDurationHours: durationHours,
                                    ),
                                  ),
                                );
                              },
                        child: Text(l10n.confirmBooking),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

class _SeatZoneSection extends StatelessWidget {
  const _SeatZoneSection({
    required this.zone,
    required this.blockedSeats,
    required this.scheduledBookedSeats,
    required this.selectedSeats,
    required this.enabled,
    required this.l10n,
    required this.onSeatTap,
  });

  final SeatZone zone;
  final Set<int> blockedSeats;
  final Set<int> scheduledBookedSeats;
  final Set<int> selectedSeats;
  final bool enabled;
  final AppLocalizations l10n;
  final ValueChanged<int> onSeatTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sectionBackground =
        isDark ? const Color(0xAA101826) : Colors.white.withValues(alpha: 0.96);
    final sectionBorder = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.08);
    final sectionShadow = isDark
        ? Colors.black.withValues(alpha: 0.18)
        : Colors.black.withValues(alpha: 0.08);
    final secondaryText = isDark
        ? Colors.white.withValues(alpha: 0.68)
        : const Color(0xFF64748B);
    final specText = isDark
        ? Colors.white.withValues(alpha: 0.72)
        : const Color(0xFF475569);
    final badgeBackground = isDark
        ? const Color(0xFF182033)
        : zone.accentColor.withValues(alpha: 0.12);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: sectionBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: sectionBorder),
        boxShadow: [
          BoxShadow(
            color: sectionShadow,
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: zone.accentColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(zone.icon, color: zone.accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      zone.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${zone.seatCount} stations',
                      style: TextStyle(
                        color: secondaryText,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${zone.pricePerHour} MNT / hour',
                      style: TextStyle(
                        color: zone.accentColor.withValues(alpha: 0.92),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeBackground,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  zone.code,
                  style: TextStyle(
                    color: zone.accentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            zone.spec,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: specText,
              fontSize: 12,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 880
                  ? 6
                  : constraints.maxWidth >= 680
                      ? 5
                      : constraints.maxWidth >= 500
                          ? 4
                          : 3;
              const spacing = 12.0;
              final itemWidth =
                  (constraints.maxWidth - (columns - 1) * spacing) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final seatIndex in zone.indexes)
                    SizedBox(
                      width: itemWidth,
                      child: _SeatTile(
                        label: zone.labelFor(seatIndex),
                        pricePerHour: zone.pricePerHour,
                        accentColor: zone.accentColor,
                        isBlocked: blockedSeats.contains(seatIndex),
                        isBookedForSchedule:
                            scheduledBookedSeats.contains(seatIndex),
                        isSelected: selectedSeats.contains(seatIndex),
                        enabled: enabled,
                        l10n: l10n,
                        onTap: () => onSeatTap(seatIndex),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SeatTile extends StatelessWidget {
  const _SeatTile({
    required this.label,
    required this.pricePerHour,
    required this.accentColor,
    required this.isBlocked,
    required this.isBookedForSchedule,
    required this.isSelected,
    required this.enabled,
    required this.l10n,
    required this.onTap,
  });

  final String label;
  final int pricePerHour;
  final Color accentColor;
  final bool isBlocked;
  final bool isBookedForSchedule;
  final bool isSelected;
  final bool enabled;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDisabled = !enabled || isBlocked || isBookedForSchedule;
    final availabilityColor = isBlocked
        ? Colors.orange
        : isBookedForSchedule
            ? const Color(0xFFEF4444)
            : isSelected
                ? const Color(0xFF22C55E)
                : Colors.grey.shade300;
    final borderColor = isSelected || isBlocked || isBookedForSchedule
        ? availabilityColor
        : accentColor.withValues(alpha: 0.48);
    final accentLineColor = isSelected || isBlocked || isBookedForSchedule
        ? availabilityColor
        : accentColor;
    final tileBackground =
        isDark ? const Color(0xFF171F31) : const Color(0xFFF8FAFC);
    final labelColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final statusColor = isDark
        ? Colors.white.withValues(alpha: 0.7)
        : const Color(0xFF64748B);
    final progressBackground = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);
    final statusLabel = isBlocked
        ? l10n.ownerSeatBlocked
        : isBookedForSchedule
            ? l10n.seatUnavailableForTime
            : isSelected
                ? l10n.seatSelectedLabel
                : l10n.ownerSeatAvailable;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 118,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            decoration: BoxDecoration(
              color: tileBackground,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: borderColor.withValues(alpha: isSelected ? 0.95 : 0.72),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: availabilityColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const Spacer(),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: Color(0xFF22C55E),
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: labelColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$pricePerHour MNT / hour',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: accentLineColor,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: 1,
                    minHeight: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(accentLineColor),
                    backgroundColor: progressBackground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
