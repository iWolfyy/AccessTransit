/// Represents the current operational status of a live bus.
enum BusStatus {
  active('active'),
  stopped('stopped'),
  completed('completed'),
  offline('offline');

  const BusStatus(this.value);

  final String value;

  static BusStatus fromString(String? value) {
    if (value == null || value.trim().isEmpty) return BusStatus.offline;
    final normalized = value.trim().toLowerCase();
    return BusStatus.values.firstWhere(
      (status) => status.value == normalized,
      orElse: () => BusStatus.offline,
    );
  }

  @override
  String toString() => value;
}
