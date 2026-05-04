import 'package:flutter/material.dart';

import '../data/booking_store.dart';
import '../l10n/app_localizations.dart';
import '../models/booking_record.dart';
import '../models/center.dart';
import '../utils/seat_labels.dart';
import '../widgets/language_toggle_button.dart';

class OwnerSeatManagerScreen extends StatefulWidget {
  const OwnerSeatManagerScreen({super.key, required this.center});

  final EsportCenter center;

  @override
  State<OwnerSeatManagerScreen> createState() => _OwnerSeatManagerScreenState();
}

class _OwnerSeatManagerScreenState extends State<OwnerSeatManagerScreen> {
  late DateTime _previewStartAt;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _previewStartAt = DateTime(now.year, now.month, now.day, now.hour);
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
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
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

  List<BookingRecord> _bookingsAtPreviewTime(List<BookingRecord> history) {
    final previewEndAt = _previewStartAt.add(const Duration(hours: 1));
    final filtered = history.where((item) {
      if (item.isCanceled || item.centerId != widget.center.id) return false;
      return _previewStartAt.isBefore(item.endAt) &&
          item.startAt.isBefore(previewEndAt);
    }).toList();

    filtered.sort((a, b) => a.startAt.compareTo(b.startAt));
    return filtered;
  }

  String _seatText(List<int> seatIndexes) {
    final sorted = [...seatIndexes]..sort();
    return sorted
        .map((e) => seatLabelFor(e, center: widget.center))
        .join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.ownerSeatManagerTitle(widget.center.name)),
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
              final history = historySnapshot.data ?? const <BookingRecord>[];
              final blockedSeats = blockedSnapshot.data ?? const <int>{};
              final bookingsAtPreview = _bookingsAtPreviewTime(history);
              final bookedSeats = BookingStore.scheduledBookedSeats(
                centerId: widget.center.id,
                startAt: _previewStartAt,
                durationHours: 1,
              );

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: _pickPreviewStartAt,
                          borderRadius: BorderRadius.circular(15),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: l10n.ownerSeatPreviewTimeLabel,
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
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            l10n.ownerSeatPreviewHint,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _Legend(
                              color: Colors.green,
                              label: l10n.ownerSeatAvailable,
                            ),
                            _Legend(
                              color: Colors.orange,
                              label: l10n.ownerSeatBlocked,
                            ),
                            _Legend(
                              color: Colors.red,
                              label: l10n.ownerSeatBooked,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: widget.center.pcCount,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemBuilder: (context, index) {
                        final isBooked = bookedSeats.contains(index);
                        final isBlocked = blockedSeats.contains(index);
                        final color = isBooked
                            ? Colors.red
                            : isBlocked
                                ? Colors.orange
                                : Colors.green;

                        return GestureDetector(
                          onTap: isBooked
                              ? null
                              : () {
                                  BookingStore.toggleBlockedSeat(
                                    widget.center.id,
                                    index,
                                  );
                                  setState(() {});
                                },
                          child: Container(
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                seatLabelFor(index, center: widget.center),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.ownerSeatBookingsAtTimeTitle(
                            _formatDateTime(_previewStartAt),
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (bookingsAtPreview.isEmpty)
                          Text(
                            l10n.ownerSeatNoBookingsAtTime,
                            style: const TextStyle(color: Colors.white70),
                          )
                        else
                          ...bookingsAtPreview.map(
                            (booking) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                '${booking.customerName} • ${_seatText(booking.seatIndexes)} • '
                                '${_formatDateTime(booking.startAt)} - ${_formatDateTime(booking.endAt)}',
                              ),
                            ),
                          ),
                      ],
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
  const _Legend({required this.color, required this.label});

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
