import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../data/cards_data.dart';
import '../../models/album_country.dart';
import '../../models/collection_progress.dart';
import '../collection/collection_screen.dart';
import 'book_album_screen.dart';
import 'country_album_screen.dart';

class AlbumScreen extends StatelessWidget {
  const AlbumScreen({super.key});

  static const _ink = Color(0xFF3C2B20);
  static const _paper = Color(0xFFF4E4BF);

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final global = controller.globalAlbumProgress();
    final countries = albumCountries
        .where((country) => country.isActive)
        .toList(growable: false);

    return Scaffold(
      backgroundColor: const Color(0xFF17100D),
      appBar: AppBar(
        title: const Text('Álbum de viagem'),
        actions: [
          IconButton(
            tooltip: 'Coleção',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const CollectionScreen()),
            ),
            icon: const Icon(Icons.style_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          _AlbumViewSelector(
            onBook: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) =>
                    BookAlbumScreen(initialCountry: countries.first),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _AlbumCover(progress: global, countryCount: countries.length),
          const SizedBox(height: 18),
          _AlbumIndexPage(
            countries: countries,
            progressFor: controller.countryAlbumProgress,
            onCountry: (country) => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => CountryAlbumScreen(country: country),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlbumViewSelector extends StatelessWidget {
  const _AlbumViewSelector({required this.onBook});

  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: const Color(0xFF2B1C16),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF6E4935)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Container(
            key: const Key('album-view-catalog'),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF8B4F35),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.grid_view_rounded, size: 18),
                SizedBox(width: 7),
                Text(
                  'CATÁLOGO',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: const Key('album-view-book'),
              onTap: onBook,
              borderRadius: BorderRadius.circular(9),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      size: 18,
                      color: Color(0xFFE6C996),
                    ),
                    SizedBox(width: 7),
                    Text(
                      'LIVRO',
                      style: TextStyle(
                        color: Color(0xFFE6C996),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _AlbumCover extends StatelessWidget {
  const _AlbumCover({required this.progress, required this.countryCount});

  final CollectionProgress progress;
  final int countryCount;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('album-cover'),
    constraints: const BoxConstraints(minHeight: 270),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF74412C), Color(0xFF3A1E18), Color(0xFF251311)],
        stops: [0, .58, 1],
      ),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFB8824F), width: 2),
      boxShadow: const [
        BoxShadow(color: Colors.black54, blurRadius: 22, offset: Offset(0, 12)),
      ],
    ),
    child: Stack(
      children: [
        Positioned.fill(
          left: 25,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0x557E4E33)),
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(10),
              ),
            ),
          ),
        ),
        Positioned(
          left: 17,
          top: 0,
          bottom: 0,
          child: Container(width: 2, color: const Color(0x55301510)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(38, 27, 24, 24),
          child: Column(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0x22170B08),
                  border: Border.all(color: const Color(0xFFE0B66F), width: 2),
                ),
                child: const Icon(
                  Icons.public_rounded,
                  size: 47,
                  color: Color(0xFFE8C886),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'PUZZLE WORLD',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFFFE3A9),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3.2,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'ÁLBUM DE VIAGEM',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFFFF0CB),
                  fontFamily: 'serif',
                  fontSize: 27,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'EDIÇÃO 01  •  $countryCount DESTINOS',
                style: const TextStyle(
                  color: Color(0xFFDCB983),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 21),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: progress.fraction,
                        minHeight: 7,
                        backgroundColor: Colors.black26,
                        color: const Color(0xFFE8C886),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${progress.percent}%',
                    style: const TextStyle(
                      color: Color(0xFFFFE3A9),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${progress.pasted} de ${progress.total} figurinhas coladas',
                  style: const TextStyle(
                    color: Color(0xFFD7BA8C),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _AlbumIndexPage extends StatelessWidget {
  const _AlbumIndexPage({
    required this.countries,
    required this.progressFor,
    required this.onCountry,
  });

  final List<AlbumCountry> countries;
  final CollectionProgress Function(String countryId) progressFor;
  final ValueChanged<AlbumCountry> onCountry;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('album-country-index'),
    padding: const EdgeInsets.fromLTRB(23, 25, 23, 24),
    decoration: BoxDecoration(
      color: AlbumScreen._paper,
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: const Color(0xFFD0B77F)),
      boxShadow: const [
        BoxShadow(color: Colors.black45, blurRadius: 18, offset: Offset(0, 9)),
      ],
    ),
    child: CustomPaint(
      painter: _PaperDetailsPainter(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.menu_book_rounded, color: AlbumScreen._ink),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'ÍNDICE DE DESTINOS',
                  style: TextStyle(
                    color: AlbumScreen._ink,
                    fontFamily: 'serif',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          const Text(
            'Abra um capítulo e complete os espaços de cada país.',
            style: TextStyle(color: Color(0xFF806A58), fontSize: 12),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: countries.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: .92,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              final country = countries[index];
              return _CountryIndexCard(
                chapter: index + 1,
                country: country,
                progress: progressFor(country.id),
                onTap: () => onCountry(country),
              );
            },
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.center,
            child: Text(
              '—  ${countries.length} capítulos para descobrir o mundo  —',
              style: const TextStyle(
                color: Color(0xFF927B65),
                fontFamily: 'serif',
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _CountryIndexCard extends StatelessWidget {
  const _CountryIndexCard({
    required this.chapter,
    required this.country,
    required this.progress,
    required this.onTap,
  });

  final int chapter;
  final AlbumCountry country;
  final CollectionProgress progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Ink(
        decoration: BoxDecoration(
          color: const Color(0xFFF9EDCE),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFB99C6B)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22866A43),
              blurRadius: 4,
              offset: Offset(2, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: 7,
              top: 7,
              child: Text(
                chapter.toString().padLeft(2, '0'),
                style: const TextStyle(
                  color: Color(0xFF9A8061),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(country.flag, style: const TextStyle(fontSize: 34)),
                  const SizedBox(height: 3),
                  Text(
                    country.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AlbumScreen._ink,
                      fontFamily: 'serif',
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Expanded(
                    child: Text(
                      country.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF796452),
                        fontSize: 9.5,
                        height: 1.25,
                      ),
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: progress.fraction,
                      minHeight: 4,
                      backgroundColor: const Color(0xFFE0CDA5),
                      color: const Color(0xFF8B4F35),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${progress.pasted}/${progress.total} coladas',
                          style: const TextStyle(
                            color: Color(0xFF806A58),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: Color(0xFF8B4F35),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PaperDetailsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = const Color(0x129A7B4F)
      ..strokeWidth = 1;
    for (double y = 58; y < size.height; y += 36) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    final speck = Paint()..color = const Color(0x14705A40);
    for (var index = 0; index < 26; index++) {
      final x = ((index * 73) % 251) / 251 * size.width;
      final y = ((index * 47) % 311) / 311 * size.height;
      canvas.drawCircle(Offset(x, y), index.isEven ? .8 : .45, speck);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
