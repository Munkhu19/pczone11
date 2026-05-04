import 'package:flutter/material.dart';

import '../data/center_store.dart';
import '../l10n/app_localizations.dart';
import '../models/center.dart';
import '../widgets/language_toggle_button.dart';

class AdminCentersScreen extends StatelessWidget {
  const AdminCentersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ValueListenableBuilder<List<EsportCenter>>(
      valueListenable: CenterStore.centersNotifier,
      builder: (context, centers, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.adminCentersTitle),
            actions: const [AppHeaderActions()],
          ),
          body: centers.isEmpty
              ? Center(child: Text(l10n.noCentersFound))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: centers.length,
                  itemBuilder: (context, index) {
                    final center = centers[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(center.name),
                        subtitle: Text(
                          '${center.address}\n${l10n.pricePerHourLabel(center.price)}\nOwner: ${center.ownerEmail ?? '-'}',
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
