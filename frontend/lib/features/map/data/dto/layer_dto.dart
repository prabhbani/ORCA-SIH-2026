import '../../domain/entities/map_layer.dart';

/// DTO for /api/v1/layers.
class LayerDto {
  final String id;
  final String name;
  final String? unit;
  final String? source;
  final String? tileUrl;
  final bool? enabled;

  LayerDto({
    required this.id,
    required this.name,
    this.unit,
    this.source,
    this.tileUrl,
    this.enabled,
  });

  factory LayerDto.fromJson(Map<String, dynamic> json) {
    return LayerDto(
      id: json['id'] as String? ?? 'layer',
      name: json['name'] as String? ?? 'Layer',
      unit: json['unit'] as String?,
      source: json['source'] as String?,
      tileUrl: json['tile_url'] as String?,
      enabled: json['enabled'] as bool?,
    );
  }

  MapLayerEntity toEntity() {
    return MapLayerEntity(
      id: id,
      name: name,
      unit: unit ?? '',
      source: source ?? 'Backend Map Tile',
      tileUrl: tileUrl ?? '/api/v1/tiles/$id/{z}/{x}/{y}.png',
      isEnabled: enabled ?? false,
    );
  }
}