/// Metadata describing a map layer toggle.
class MapLayerEntity {
  final String id;
  final String name;
  final String unit;
  final String source;
  final String tileUrl;
  final bool isEnabled;

  const MapLayerEntity({
    required this.id,
    required this.name,
    required this.unit,
    required this.source,
    required this.tileUrl,
    this.isEnabled = false,
  });

  MapLayerEntity copyWith({bool? isEnabled}) {
    return MapLayerEntity(
      id: id,
      name: name,
      unit: unit,
      source: source,
      tileUrl: tileUrl,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}