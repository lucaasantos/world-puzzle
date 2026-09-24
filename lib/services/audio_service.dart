class AudioService {
  bool soundEnabled = true;
  bool musicEnabled = true;

  // Audio hooks are intentionally silent until licensed files are added.
  Future<void> move() async {}
  Future<void> victory() async {}
  Future<void> reward() async {}
  Future<void> button() async {}
  Future<void> dispose() async {}
}
