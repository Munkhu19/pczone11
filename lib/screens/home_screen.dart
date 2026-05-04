import 'package:flutter/material.dart';

import '../data/center_store.dart';
import '../l10n/app_localizations.dart';
import '../models/center.dart';
import '../widgets/center_image.dart';
import '../widgets/language_toggle_button.dart';
import 'center_detail.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<EsportCenter> filteredCenters = CenterStore.all();

  @override
  void initState() {
    super.initState();
    CenterStore.centersNotifier.addListener(_syncCenters);
  }

  @override
  void dispose() {
    CenterStore.centersNotifier.removeListener(_syncCenters);
    super.dispose();
  }

  void _syncCenters() {
    if (!mounted) return;
    setState(() {
      filteredCenters = CenterStore.all();
    });
  }

  void searchCenter(String query) {
    final q = query.toLowerCase().trim();
    final results = CenterStore.all().where((center) {
      return center.name.toLowerCase().contains(q) ||
          center.address.toLowerCase().contains(q);
    }).toList();

    setState(() {
      filteredCenters = results;
    });
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

  Widget _buildCenterCard(BuildContext context, EsportCenter center) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imageSource = center.primaryImage;
    final textSecondary = isDark
        ? Colors.white.withValues(alpha: 0.74)
        : const Color(0xFF64748B);

    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CenterDetail(center: center),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF101826) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 136,
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
                            Colors.black.withValues(alpha: 0.72),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _HomeInfoPill(
                                icon: Icons.star_rounded,
                                label: center.rating.toStringAsFixed(1),
                                backgroundColor: const Color(0xFFF59E0B)
                                    .withValues(alpha: 0.20),
                                foregroundColor: const Color(0xFFFACC15),
                              ),
                              const Spacer(),
                              _HomeInfoPill(
                                icon: Icons.payments_outlined,
                                label: _priceShortLabel(context, center.price),
                                backgroundColor: const Color(0xFF14B8A6)
                                    .withValues(alpha: 0.18),
                                foregroundColor: const Color(0xFF99F6E4),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            center.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _reviewCountLabel(context, center.reviewCount),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.84),
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
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    center.address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _HomeStatTile(
                    icon: Icons.desktop_windows_rounded,
                    label: _pcCountShortLabel(context, center.pcCount),
                  ),
                  const SizedBox(height: 12),
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
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final listBottomPadding = bottomInset + 112;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.centersTitle),
        actions: const [
          AppHeaderActions(),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: TextField(
              onChanged: searchCenter,
              decoration: InputDecoration(
                hintText: l10n.searchCenterHint,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          Expanded(
            child: filteredCenters.isEmpty
                ? Center(
                    child: Text(
                      l10n.noCentersFound,
                      style: const TextStyle(fontSize: 18),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      15,
                      2,
                      15,
                      listBottomPadding,
                    ),
                    itemCount: filteredCenters.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 14),
                    itemBuilder: (context, index) =>
                        _buildCenterCard(context, filteredCenters[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _HomeInfoPill extends StatelessWidget {
  const _HomeInfoPill({
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
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeStatTile extends StatelessWidget {
  const _HomeStatTile({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foregroundColor =
        isDark ? Colors.white : const Color(0xFF0F172A);
    final backgroundColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : const Color(0xFFF8FAFC);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
