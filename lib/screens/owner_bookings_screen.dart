import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/booking_store.dart';
import '../data/center_store.dart';
import '../data/firebase_state.dart';
import '../l10n/app_localizations.dart';
import '../models/booking_record.dart';
import '../models/center.dart';
import '../utils/seat_labels.dart';
import '../widgets/language_toggle_button.dart';

enum _OwnerBookingFilter {
  all,
  active,
  canceled,
}

class OwnerBookingsScreen extends StatefulWidget {
  const OwnerBookingsScreen({super.key});

  @override
  State<OwnerBookingsScreen> createState() => _OwnerBookingsScreenState();
}

class _OwnerBookingsScreenState extends State<OwnerBookingsScreen> {
  _OwnerBookingFilter _filter = _OwnerBookingFilter.all;

  String _normalizeText(String value) {
    return value.trim().toLowerCase();
  }

  bool _isOwnedBooking(
    BookingRecord booking,
    Set<String> ownedCenterIds,
    Set<String> ownedCenterNames,
  ) {
    if (ownedCenterIds.contains(booking.centerId)) {
      return true;
    }
    return ownedCenterNames.contains(_normalizeText(booking.centerName));
  }

  String _formatDate(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  String _formatSchedule(BookingRecord booking) {
    return '${_formatDate(booking.startAt)} - ${_formatDate(booking.endAt)}';
  }

  String _statusLabel(BookingRecord booking, AppLocalizations l10n) {
    final isMn = Localizations.localeOf(context).languageCode == 'mn';
    switch (booking.statusCodeAt(DateTime.now())) {
      case 'upcoming':
        return isMn ? 'Удахгүй' : 'Upcoming';
      case 'checked_in':
        return isMn ? 'Ирсэн' : 'Checked in';
      case 'completed':
        return isMn ? 'Дууссан' : 'Completed';
      case 'no_show':
        return isMn ? 'Ирээгүй' : 'No-show';
      case 'canceled':
        return l10n.statusCanceled;
      default:
        return l10n.statusActive;
    }
  }

  Color _statusColor(BookingRecord booking) {
    switch (booking.statusCodeAt(DateTime.now())) {
      case 'upcoming':
        return const Color(0xFF1D4ED8);
      case 'checked_in':
        return const Color(0xFF16A34A);
      case 'completed':
        return const Color(0xFF475569);
      case 'no_show':
        return const Color(0xFFDC2626);
      case 'canceled':
        return const Color(0xFFB91C1C);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  bool _canCheckIn(BookingRecord booking) {
    final now = DateTime.now();
    return !booking.isCanceled && !booking.isCheckedIn && booking.endAt.isAfter(now);
  }

  EsportCenter? _centerFor(String centerId) {
    for (final center in CenterStore.all()) {
      if (center.id == centerId) {
        return center;
      }
    }
    return null;
  }

  String _graceDeadlineText(BookingRecord booking) {
    final isMn = Localizations.localeOf(context).languageCode == 'mn';
    final formatted = _formatDate(booking.noShowDeadline);
    return isMn
        ? 'Ирээгүй бол автоматаар цуцлах цаг: $formatted'
        : 'Auto-cancel if not arrived by: $formatted';
  }

  String _checkedInAtText(DateTime value) {
    final isMn = Localizations.localeOf(context).languageCode == 'mn';
    return isMn ? 'Ирсэн: ${_formatDate(value)}' : 'Checked in: ${_formatDate(value)}';
  }

  String _noShowAtText(DateTime value) {
    final isMn = Localizations.localeOf(context).languageCode == 'mn';
    return isMn
        ? 'Ирээгүй тул цуцлагдсан: ${_formatDate(value)}'
        : 'No-show canceled: ${_formatDate(value)}';
  }

  String _markArrivedLabel() {
    final isMn = Localizations.localeOf(context).languageCode == 'mn';
    return isMn ? 'Ирсэн гэж тэмдэглэх' : 'Mark arrived';
  }

  String _checkInSuccessText() {
    final isMn = Localizations.localeOf(context).languageCode == 'mn';
    return isMn ? 'Хэрэглэгчийг ирсэн гэж тэмдэглэлээ.' : 'Customer marked as arrived.';
  }

  String _checkInUnavailableText() {
    final isMn = Localizations.localeOf(context).languageCode == 'mn';
    return isMn
        ? 'Энэ захиалгыг одоо ирсэн гэж тэмдэглэх боломжгүй.'
        : 'This booking can no longer be checked in.';
  }

  List<BookingRecord> _sortBookings(List<BookingRecord> items) {
    final sorted = items.toList(growable: false);
    sorted.sort((a, b) => b.startAt.compareTo(a.startAt));
    return sorted;
  }

  Future<void> _checkInBooking(BookingRecord booking) async {
    final updated = await BookingStore.checkInBooking(booking.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(updated ? _checkInSuccessText() : _checkInUnavailableText()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ownerEmail = firebaseAvailable ? FirebaseAuth.instance.currentUser?.email : null;

    return ValueListenableBuilder(
      valueListenable: CenterStore.centersNotifier,
      builder: (context, value, child) {
        final ownedCenterIds = CenterStore.ownedBy(ownerEmail).map((e) => e.id).toSet();
        final ownedCenterNames = CenterStore.ownedBy(ownerEmail)
            .map((e) => _normalizeText(e.name))
            .toSet();

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.ownerBookingsTitle),
            actions: const [AppHeaderActions()],
          ),
          body: StreamBuilder<List<BookingRecord>>(
            stream: BookingStore.bookingHistoryStream(),
            initialData: BookingStore.bookingHistory(),
            builder: (context, snapshot) {
              final currentItems = BookingStore.bookingHistory();
              final allItems = currentItems
                  .where(
                    (booking) => _isOwnedBooking(
                      booking,
                      ownedCenterIds,
                      ownedCenterNames,
                    ),
                  )
                  .toList(growable: false);
              final sortedItems = _sortBookings(allItems);
              final items = sortedItems.where((booking) {
                switch (_filter) {
                  case _OwnerBookingFilter.active:
                    return !booking.isCanceled;
                  case _OwnerBookingFilter.canceled:
                    return booking.isCanceled;
                  case _OwnerBookingFilter.all:
                    return true;
                }
              }).toList(growable: false);

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: SegmentedButton<_OwnerBookingFilter>(
                      segments: [
                        ButtonSegment<_OwnerBookingFilter>(
                          value: _OwnerBookingFilter.all,
                          label: Text(l10n.ownerFilterAll),
                        ),
                        ButtonSegment<_OwnerBookingFilter>(
                          value: _OwnerBookingFilter.active,
                          label: Text(l10n.statusActive),
                        ),
                        ButtonSegment<_OwnerBookingFilter>(
                          value: _OwnerBookingFilter.canceled,
                          label: Text(l10n.statusCanceled),
                        ),
                      ],
                      selected: <_OwnerBookingFilter>{_filter},
                      onSelectionChanged: (selection) {
                        setState(() {
                          _filter = selection.first;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: items.isEmpty
                        ? Center(
                            child: Text(
                              sortedItems.isEmpty
                                  ? l10n.ownerNoBookings
                                  : l10n.ownerNoBookingsForFilter,
                              style: const TextStyle(fontSize: 16),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final booking = items[index];
                              final center = _centerFor(booking.centerId);
                              final seats = booking.seatIndexes
                                  .map(
                                    (e) => center == null
                                        ? 'PC ${e + 1}'
                                        : seatLabelFor(e, center: center),
                                  )
                                  .join(', ');
                              final statusColor = _statusColor(booking);

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              booking.centerName,
                                              style: const TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Chip(
                                            label: Text(_statusLabel(booking, l10n)),
                                            backgroundColor: statusColor.withValues(alpha: 0.2),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(l10n.customerLabel(booking.customerName)),
                                      Text(l10n.phoneLabel(booking.phone)),
                                      Text(l10n.bookingTimeLabel(_formatSchedule(booking))),
                                      Text(l10n.durationLabel(booking.durationHours)),
                                      Text(l10n.seatsLabel(seats)),
                                      Text(_graceDeadlineText(booking)),
                                      Text(
                                        l10n.totalPriceLabel(booking.totalPrice),
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(l10n.createdLabel(_formatDate(booking.createdAt))),
                                      if (booking.isCheckedIn && booking.checkedInAt != null)
                                        Text(_checkedInAtText(booking.checkedInAt!)),
                                      if (booking.isNoShow && booking.noShowAt != null)
                                        Text(_noShowAtText(booking.noShowAt!)),
                                      if (booking.isCanceled && booking.canceledAt != null)
                                        Text(l10n.canceledLabel(_formatDate(booking.canceledAt!))),
                                      if (_canCheckIn(booking)) ...[
                                        const SizedBox(height: 10),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: ElevatedButton(
                                            onPressed: () => _checkInBooking(booking),
                                            child: Text(_markArrivedLabel()),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
