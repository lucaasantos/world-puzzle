import 'dart:io';

import 'package:flutter/services.dart';
import 'package:gal/gal.dart';

abstract interface class WallpaperService {
  Future<bool> save(String assetPath);
}

class GalleryWallpaperService implements WallpaperService {
  static const _androidChannel = MethodChannel('mosaico/wallpaper');

  @override
  Future<bool> save(String assetPath) async {
    File? temporaryFile;
    try {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      if (Platform.isAndroid) {
        final hasAccess = await Gal.requestAccess();
        if (!hasAccess) return false;
        return await _androidChannel.invokeMethod<bool>('saveWallpaper', {
              'bytes': bytes,
              'name': 'mosaico_${DateTime.now().millisecondsSinceEpoch}',
            }) ??
            false;
      }
      temporaryFile = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}'
        'mosaico_${DateTime.now().millisecondsSinceEpoch}.webp',
      );
      await temporaryFile.writeAsBytes(bytes, flush: true);
      await Gal.putImage(temporaryFile.path);
      return true;
    } catch (_) {
      return false;
    } finally {
      if (temporaryFile != null && await temporaryFile.exists()) {
        await temporaryFile.delete();
      }
    }
  }
}
