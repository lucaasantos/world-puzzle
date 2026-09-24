import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../data/packs_data.dart';

class DebugPackSheet extends StatefulWidget {
  const DebugPackSheet({super.key});

  @override
  State<DebugPackSheet> createState() => _DebugPackSheetState();
}

class _DebugPackSheetState extends State<DebugPackSheet> {
  bool working = false;

  @override
  Widget build(BuildContext context) {
    if (!AppScope.of(context).debugEconomyEnabled) {
      return const SizedBox.shrink();
    }
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ferramentas de pacotes',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 5),
            const Text(
              'Disponível somente em builds de debug.',
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 16),
            for (final pack in PackCatalog.active)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(child: Text(pack.name)),
                    FilledButton.tonal(
                      onPressed: working ? null : () => _grant(pack.id, 1),
                      child: const Text('+1'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonal(
                      onPressed: working ? null : () => _grant(pack.id, 10),
                      child: const Text('+10'),
                    ),
                  ],
                ),
              ),
            const Divider(height: 26),
            OutlinedButton.icon(
              onPressed: working ? null : _openMany,
              icon: const Icon(Icons.science_outlined),
              label: const Text('Abrir 20 World Packs rapidamente'),
            ),
            TextButton.icon(
              onPressed: working ? null : _reset,
              icon: const Icon(Icons.delete_sweep_outlined),
              label: const Text('Zerar inventário de pacotes'),
            ),
            if (working) ...[
              const SizedBox(height: 10),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _grant(String packId, int quantity) => _run(
    () => AppScope.of(
      context,
      listen: false,
    ).debugGrantPack(packId, quantity: quantity),
    '$quantity pacote${quantity == 1 ? '' : 's'} concedido${quantity == 1 ? '' : 's'}.',
  );

  Future<void> _openMany() => _run(
    () => AppScope.of(
      context,
      listen: false,
    ).debugOpenPacks(PackIds.world, quantity: 20),
    '20 World Packs abertos e adicionados à Coleção.',
  );

  Future<void> _reset() => _run(
    () => AppScope.of(context, listen: false).debugResetPackInventory(),
    'Inventário de pacotes zerado.',
  );

  Future<void> _run(Future<Object?> Function() action, String message) async {
    setState(() => working = true);
    await action();
    if (!mounted) return;
    setState(() => working = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
