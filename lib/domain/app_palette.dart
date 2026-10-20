/// Stable preference IDs shared with the backend; labels belong to the UI catalogue.
enum AppPalette {
  atelier('Atelier', 'Giấy kem · Mực trầm · Vàng đồng'),
  ocean('Đại dương', 'Xanh lam · Ngọc biển · San hô'),
  iris('Diên vĩ', 'Tím mực · Thạch nam · Xanh sương'),
  rose('Thạch anh hồng', 'Hồng mận · Tím khói · Vàng cát'),
  amber('Hổ phách', 'Nâu mật · Ô liu · Đất nung'),
  forest('Rừng ngọc', 'Lục bảo · Lá non · Đồng đỏ');

  const AppPalette(this.label, this.description);
  final String label, description;
  static AppPalette parse(Object? value) =>
      values.firstWhere((p) => p.name == value, orElse: () => atelier);
  static bool accepts(Object? value) => values.any((p) => p.name == value);
}
