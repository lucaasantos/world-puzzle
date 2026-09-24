import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/theme/app_theme.dart';
import '../../data/packs_data.dart';
import '../../models/card_pack.dart';
import '../../widgets/card_pack/pack_artwork.dart';
import 'debug_pack_sheet.dart';
import 'world_pack_preview_screen.dart';

class PacksScreen extends StatefulWidget {
  const PacksScreen({super.key});

  @override
  State<PacksScreen> createState() => _PacksScreenState();
}

class _PacksScreenState extends State<PacksScreen> {
  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pacotes'),
        actions: [
          if (AppScope.of(context).debugEconomyEnabled)
            IconButton(
              tooltip: 'Ferramentas de pacotes (debug)',
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const DebugPackSheet(),
              ),
              icon: const Icon(Icons.bug_report_outlined),
            ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        itemCount: PackCatalog.active.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _PackInventoryHeader(total: controller.totalUnopenedPacks);
          }
          final pack = PackCatalog.active[index - 1];
          final quantity = controller.packInventoryFor(pack.id).quantity;
          return _PackTile(
            pack: pack,
            quantity: quantity,
            onOpen: quantity > 0 ? () => _open(pack) : null,
          );
        },
      ),
    );
  }

  Future<void> _open(PackDefinition pack) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => PackPreviewScreen(pack: pack)),
    );
  }
}

class _PackInventoryHeader extends StatelessWidget {
  const _PackInventoryHeader({required this.total});
  final int total;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      children: [
        const Icon(Icons.inventory_2_rounded, color: AppTheme.primary),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Pacotes não abertos',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        Text(
          '$total',
          style: const TextStyle(
            color: AppTheme.primary,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _PackTile extends StatelessWidget {
  const _PackTile({
    required this.pack,
    required this.quantity,
    required this.onOpen,
  });

  final PackDefinition pack;
  final int quantity;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: packAccent(pack.id).withValues(alpha: .2)),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 108,
          child: AspectRatio(
            aspectRatio: 5 / 7,
            child: PackArtwork(pack: pack, quantity: quantity),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pack.name.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 5),
              Text(
                pack.description,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '×$quantity  •  ${pack.cardCount} cartas',
                style: TextStyle(
                  color: packAccent(pack.id),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: ValueKey('open-pack-list-${pack.id}'),
                  onPressed: onOpen,
                  child: const Text('ABRIR'),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
