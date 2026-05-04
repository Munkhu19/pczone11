import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/booking_store.dart';
import '../data/center_store.dart';
import '../data/firebase_state.dart';
import '../l10n/app_localizations.dart';
import '../models/booking_record.dart';
import '../models/center.dart';
import '../widgets/language_toggle_button.dart';

class OwnerDashboardScreen extends StatelessWidget {
  const OwnerDashboardScreen({super.key});

  String _normalizeText(String value) {
    return value.trim().toLowerCase();
  }

  bool _isOwnedBooking(
    BookingRecord booking,
    Set<String> ownedIds,
    Set<String> ownedNames,
  ) {
    if (ownedIds.contains(booking.centerId)) {
      return true;
    }
    return ownedNames.contains(_normalizeText(booking.centerName));
  }

  String _formatDate(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  List<BookingRecord> _sortRecentBookings(List<BookingRecord> bookings) {
    final sorted = bookings.toList(growable: false);
    sorted.sort((a, b) {
      final aDate = a.canceledAt ?? a.createdAt;
      final bDate = b.canceledAt ?? b.createdAt;
      return bDate.compareTo(aDate);
    });
    return sorted;
  }

  Future<void> _clearCanceledBookings(
    BuildContext context,
    Set<String> ownedIds,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.ownerClearBookingsTitle),
        content: Text(l10n.ownerClearBookingsMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.no),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.ownerClearBookingsAction),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    await BookingStore.clearCanceledBookingsForCenters(ownedIds);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.ownerBookingsCleared)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ownerEmail = firebaseAvailable
        ? FirebaseAuth.instance.currentUser?.email
        : null;

    return ValueListenableBuilder<List<EsportCenter>>(
      valueListenable: CenterStore.centersNotifier,
        builder: (context, value, child) {
          final ownedCenters = CenterStore.ownedBy(ownerEmail);
          final ownedIds = ownedCenters.map((center) => center.id).toSet();
          final ownedNames = ownedCenters
              .map((center) => _normalizeText(center.name))
              .toSet();
          return StreamBuilder<List<BookingRecord>>(
            stream: BookingStore.bookingHistoryStream(),
            initialData: BookingStore.bookingHistory(),
            builder: (context, snapshot) {
              final currentItems = BookingStore.bookingHistory();
              final bookings = currentItems
                  .where((booking) => _isOwnedBooking(booking, ownedIds, ownedNames))
                  .toList(growable: false);
            final recentBookings = _sortRecentBookings(bookings);
            final hasCanceledBookings = bookings.any(
              (booking) => booking.isCanceled,
            );
            final activeBookings = bookings
                .where((booking) => !booking.isCanceled)
                .toList(growable: false);
            final totalRevenue = activeBookings.fold<int>(
              0,
              (sum, booking) => sum + booking.totalPrice,
            );
            final totalSeats = activeBookings.fold<int>(
              0,
              (sum, booking) => sum + booking.seatIndexes.length,
            );

            return Scaffold(
              appBar: AppBar(
                title: Text(l10n.ownerDashboardTitle),
                actions: const [AppHeaderActions()],
              ),
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (ownerEmail != null)
                    Text(
                      ownerEmail,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  const SizedBox(height: 12),
                  _StatCard(
                    title: l10n.ownerCentersCount,
                    value: ownedCenters.length.toString(),
                    color: const Color(0xFF0F766E),
                  ),
                  _StatCard(
                    title: l10n.ownerBookingsCount,
                    value: bookings.length.toString(),
                    color: const Color(0xFF1D4ED8),
                  ),
                  _StatCard(
                    title: l10n.ownerRevenueTotal,
                    value: '$totalRevenue₮',
                    color: const Color(0xFF7C3AED),
                  ),
                  _StatCard(
                    title: l10n.ownerOccupiedSeats,
                    value: totalSeats.toString(),
                    color: const Color(0xFFF97316),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.ownerRecentBookings,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (hasCanceledBookings)
                        TextButton(
                          onPressed: () =>
                              _clearCanceledBookings(context, ownedIds),
                          child: Text(l10n.ownerClearBookingsAction),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (recentBookings.isEmpty)
                    Text(l10n.ownerNoBookings)
                  else
                    ...recentBookings.take(5).map((booking) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: Text(booking.centerName),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${booking.customerName} | ${booking.seatIndexes.length} PC | ${booking.durationHours}h',
                              ),
                              Text(
                                booking.isCanceled
                                    ? '${l10n.statusCanceled} | ${booking.canceledAt == null ? '-' : _formatDate(booking.canceledAt!)}'
                                    : '${l10n.statusActive} | ${_formatDate(booking.createdAt)}',
                                style: TextStyle(
                                  color: booking.isCanceled
                                      ? Colors.redAccent.shade100
                                      : Colors.white70,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          trailing: Chip(
                            label: Text(
                              booking.isCanceled
                                  ? l10n.statusCanceled
                                  : l10n.statusActive,
                            ),
                            backgroundColor: booking.isCanceled
                                ? Colors.red.withValues(alpha: 0.2)
                                : Colors.green.withValues(alpha: 0.2),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.9),
              color.withValues(alpha: 0.6),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
