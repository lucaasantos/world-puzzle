import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/card_labels.dart';
import '../../data/cards_data.dart';
import '../../models/album_country.dart';
import 'country_album_screen.dart';

class ContinentScreen extends StatelessWidget {
  const ContinentScreen({required this.continent, super.key});

  final String continent;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final countries = CardCatalog.countriesForContinent(continent);
    return Scaffold(
      appBar: AppBar(title: Text(continentLabel(continent))),
      body: countries.isEmpty
          ? const _EmptyContinent()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              itemCount: countries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final country = countries[index];
                final progress = controller.countryAlbumProgress(country.id);
                return _CountryTile(
                  country: country,
                  pasted: progress.pasted,
                  total: progress.total,
                  percent: progress.percent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => CountryAlbumScreen(country: country),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _CountryTile extends StatelessWidget {
  const _CountryTile({
    required this.country,
    required this.pasted,
    required this.total,
    required this.percent,
    required this.onTap,
  });

  final AlbumCountry country;
  final int pasted;
  final int total;
  final int percent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Text(country.flag, style: const TextStyle(fontSize: 38)),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    country.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$pasted / $total cartas',
                    style: const TextStyle(color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            Text(
              '$percent%',
              style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white38),
          ],
        ),
      ),
    ),
  );
}

class _EmptyContinent extends StatelessWidget {
  const _EmptyContinent();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.map_outlined, size: 54, color: Colors.white24),
          SizedBox(height: 16),
          Text(
            'Novos países chegarão aqui.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54),
          ),
        ],
      ),
    ),
  );
}
