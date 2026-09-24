class CollectionProgress {
  const CollectionProgress({required this.pasted, required this.total});

  final int pasted;
  final int total;

  double get fraction => total == 0 ? 0 : pasted / total;
  int get percent => (fraction * 100).round();
}
