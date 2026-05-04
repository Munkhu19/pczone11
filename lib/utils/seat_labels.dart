import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/center.dart';

class SeatZone {
  const SeatZone({
    required this.code,
    required this.title,
    required this.startIndex,
    required this.seatCount,
    required this.accentColor,
    required this.icon,
    required this.pricePerHour,
    required this.spec,
  });

  final String code;
  final String title;
  final int startIndex;
  final int seatCount;
  final Color accentColor;
  final IconData icon;
  final int pricePerHour;
  final String spec;

  int get endIndexExclusive => startIndex + seatCount;

  Iterable<int> get indexes sync* {
    for (var index = startIndex; index < endIndexExclusive; index++) {
      yield index;
    }
  }

  bool contains(int index) {
    return index >= startIndex && index < endIndexExclusive;
  }

  String labelFor(int seatIndex) {
    return '$title ${seatIndex - startIndex + 1}';
  }
}

List<SeatZone> buildSeatZonesForCenter(EsportCenter center) {
  if (center.pcCount <= 0) return const <SeatZone>[];

  final zones = <SeatZone>[];
  var nextStartIndex = 0;

  void addZone({
    required String code,
    required String title,
    required int count,
    required Color accentColor,
    required IconData icon,
    required int pricePerHour,
    required String spec,
  }) {
    if (count <= 0) return;
    zones.add(
      SeatZone(
        code: code,
        title: title,
        startIndex: nextStartIndex,
        seatCount: count,
        accentColor: accentColor,
        icon: icon,
        pricePerHour: pricePerHour,
        spec: spec,
      ),
    );
    nextStartIndex += count;
  }

  final vipCount = math.min(center.vipCount, center.pcCount);
  final remainingAfterVip = math.max(0, center.pcCount - vipCount);
  final stageCount = math.min(center.stageCount, remainingAfterVip);
  final standardCount = math.max(0, center.pcCount - vipCount - stageCount);

  addZone(
    code: 'VIP',
    title: 'VIP',
    count: vipCount,
    accentColor: const Color(0xFFC026D3),
    icon: Icons.workspace_premium_rounded,
    pricePerHour: center.vipPrice,
    spec: center.vipSpec,
  );
  addZone(
    code: 'STAGE',
    title: 'Stage',
    count: stageCount,
    accentColor: const Color(0xFF2563EB),
    icon: Icons.rocket_launch_rounded,
    pricePerHour: center.stagePrice,
    spec: center.stageSpec,
  );
  addZone(
    code: 'PC',
    title: 'PC',
    count: standardCount,
    accentColor: const Color(0xFF22C55E),
    icon: Icons.desktop_windows_rounded,
    pricePerHour: center.price,
    spec: center.pcSpec,
  );

  return List<SeatZone>.unmodifiable(zones);
}

SeatZone? seatZoneFor(int seatIndex, {required EsportCenter center}) {
  for (final zone in buildSeatZonesForCenter(center)) {
    if (zone.contains(seatIndex)) {
      return zone;
    }
  }
  return null;
}

String seatLabelFor(int seatIndex, {required EsportCenter center}) {
  return seatZoneFor(seatIndex, center: center)?.labelFor(seatIndex) ??
      'PC ${seatIndex + 1}';
}

int seatPriceFor(int seatIndex, {required EsportCenter center}) {
  return seatZoneFor(seatIndex, center: center)?.pricePerHour ?? center.price;
}

String seatSpecFor(int seatIndex, {required EsportCenter center}) {
  return seatZoneFor(seatIndex, center: center)?.spec ?? center.pcSpec;
}

int totalHourlyPriceForSeats(
  Iterable<int> seatIndexes, {
  required EsportCenter center,
}) {
  return seatIndexes.fold<int>(
    0,
    (sum, seatIndex) => sum + seatPriceFor(seatIndex, center: center),
  );
}
