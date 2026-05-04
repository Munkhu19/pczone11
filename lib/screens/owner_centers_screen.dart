import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/booking_store.dart';
import '../data/center_store.dart';
import '../data/firebase_state.dart';
import '../l10n/app_localizations.dart';
import '../models/center.dart';
import '../widgets/center_image.dart';
import '../widgets/language_toggle_button.dart';
import 'owner_center_editor_screen.dart';
import 'owner_seat_manager_screen.dart';

class OwnerCentersScreen extends StatelessWidget {
  const OwnerCentersScreen({super.key});

  Future<void> _openEditor(
    BuildContext context, {
    EsportCenter? center,
  }) async {
    final ownerEmail =
        firebaseAvailable ? FirebaseAuth.instance.currentUser?.email : null;
    if (ownerEmail == null || ownerEmail.isEmpty) {
      final isMn = Localizations.localeOf(context).languageCode == 'mn';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isMn
                ? 'Төв нэмэхийн тулд owner эрхээр нэвтэрнэ үү.'
                : 'Sign in as an owner to add a center.',
          ),
        ),
      );
      return;
    }

    final result = await Navigator.of(context).push<EsportCenter>(
      MaterialPageRoute(
        builder: (context) => OwnerCenterEditorScreen(
          center: center,
          ownerEmail: ownerEmail,
        ),
      ),
    );
    if (result == null) return;

    try {
      if (center == null) {
        await CenterStore.addCenter(result);
      } else {
        await CenterStore.updateCenter(result);
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            center == null
                ? '${result.name} төв нэмэгдлээ.'
                : '${result.name} төв шинэчлэгдлээ.',
          ),
          backgroundColor: const Color(0xFF15803D),
        ),
      );
    } on CenterCloudSyncException catch (error) {
      if (!context.mounted) return;
      final isMn = Localizations.localeOf(context).languageCode == 'mn';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.savedLocally
                ? (isMn
                    ? 'Төв нэмэгдсэн. Firestore sync дараа дахин оролдоно.'
                    : 'Center saved locally. Firestore sync will retry later.')
                : 'Firestore sync failed: ${error.message}',
          ),
          backgroundColor:
              error.savedLocally ? const Color(0xFFB45309) : null,
        ),
      );
    } on FirebaseException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Firestore error: ${error.code}${error.message == null ? '' : ' - ${error.message}'}',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Center save failed: $error')),
      );
    }
  }

  Future<void> _deleteCenter(BuildContext context, EsportCenter center) async {
    final l10n = AppLocalizations.of(context)!;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.ownerDeleteCenterTitle),
        content: Text(l10n.ownerDeleteCenterMessage(center.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.no),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.ownerDeleteCenterAction),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;

    await BookingStore.removeCenters(<String>{center.id});
    await CenterStore.deleteCenter(center.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.ownerCenterDeleted(center.name)),
        backgroundColor: const Color(0xFF15803D),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ownerEmail =
        firebaseAvailable ? FirebaseAuth.instance.currentUser?.email : null;

    return ValueListenableBuilder<List<EsportCenter>>(
      valueListenable: CenterStore.centersNotifier,
      builder: (context, value, child) {
        final items = CenterStore.ownedBy(ownerEmail);

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.ownerCentersTitle),
            actions: const [AppHeaderActions()],
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 92),
            child: FloatingActionButton(
              onPressed: () => _openEditor(context),
              child: const Icon(Icons.add),
            ),
          ),
          body: items.isEmpty
              ? Center(child: Text(l10n.ownerNoCenters))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final center = items[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: CenterImage(
                          imageBase64: center.primaryImage,
                          width: 72,
                          height: 72,
                          borderRadius: 14,
                        ),
                        title: Text(center.name),
                        subtitle: Text(
                          '${center.address}\n${l10n.pricePerHourLabel(center.price)}',
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chair_alt_outlined),
                              tooltip: l10n.ownerSeatManagerShort,
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        OwnerSeatManagerScreen(center: center),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () =>
                                  _openEditor(context, center: center),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _deleteCenter(context, center),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
