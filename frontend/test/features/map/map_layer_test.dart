import 'package:flutter_test/flutter_test.dart';
import 'package:orca_app/features/map/data/dto/layer_dto.dart';
import 'package:orca_app/features/map/domain/entities/map_layer.dart';

void main() {
  group('Map layer contracts', () {
    test('parses fixture-shaped layer data into a domain entity', () {
      final dto = LayerDto.fromJson({
        'id': 'wave_height',
        'name': 'Wave Height & Direction',
        'unit': 'm',
        'source': 'Open-Meteo Marine',
        'tile_url': '/api/v1/tiles/waves/{z}/{x}/{y}.png',
        'enabled': true,
      });

      final entity = dto.toEntity();

      expect(entity.id, equals('wave_height'));
      expect(entity.name, equals('Wave Height & Direction'));
      expect(entity.tileUrl, contains('{z}'));
      expect(entity.isEnabled, isTrue);
    });

    test('copyWith changes only the presentation toggle', () {
      const layer = MapLayerEntity(
        id: 'sst',
        name: 'Sea Surface Temperature',
        unit: 'C',
        source: 'Open-Meteo Marine',
        tileUrl: '/api/v1/tiles/sst/{z}/{x}/{y}.png',
      );

      final enabled = layer.copyWith(isEnabled: true);

      expect(enabled.isEnabled, isTrue);
      expect(enabled.id, equals(layer.id));
      expect(enabled.tileUrl, equals(layer.tileUrl));
    });
  });
}