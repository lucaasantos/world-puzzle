class CardInventoryEntry {
  const CardInventoryEntry({
    required this.cardId,
    this.quantity = 0,
    this.pastedInAlbum = false,
  }) : assert(quantity >= 0);

  final String cardId;

  /// Copies still available for packs, rewards, sale, or trade.
  final int quantity;

  /// Whether one copy was permanently consumed by the album.
  final bool pastedInAlbum;

  CardInventoryEntry copyWith({int? quantity, bool? pastedInAlbum}) =>
      CardInventoryEntry(
        cardId: cardId,
        quantity: quantity ?? this.quantity,
        pastedInAlbum: pastedInAlbum ?? this.pastedInAlbum,
      );

  Map<String, Object> toJson() => {
    'cardId': cardId,
    'quantity': quantity,
    'pastedInAlbum': pastedInAlbum,
  };

  factory CardInventoryEntry.fromJson(Map<String, dynamic> json) {
    final rawQuantity = json['quantity'] as int? ?? 0;
    return CardInventoryEntry(
      cardId: json['cardId'] as String,
      quantity: rawQuantity < 0 ? 0 : rawQuantity,
      pastedInAlbum: json['pastedInAlbum'] as bool? ?? false,
    );
  }
}
