enum LoadingStatus { initial, loading, loaded, error }

enum SortOption {
  newest('createdAt', 'desc', 'Moi nhat'),
  oldest('createdAt', 'asc', 'Cu nhat'),
  priceAsc('price', 'asc', 'Gia tang dan'),
  priceDesc('price', 'desc', 'Gia giam dan'),
  nameAsc('name', 'asc', 'A - Z'),
  nameDesc('name', 'desc', 'Z - A'),
  rating('averageRating', 'desc', 'Danh gia cao');

  final String field;
  final String order;
  final String label;
  const SortOption(this.field, this.order, this.label);
}
