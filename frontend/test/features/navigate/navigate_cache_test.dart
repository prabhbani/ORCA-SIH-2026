import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:orca_app/core/cache/cache_service.dart';
import 'package:orca_app/features/navigate/data/datasources/navigate_remote.dart';
import 'package:orca_app/features/navigate/data/dto/route_check_dto.dart';
import 'package:orca_app/features/navigate/data/repositories/navigate_repo_impl.dart';

class MockNavigateRemote extends Mock implements NavigateRemoteDataSource {}

class MockCacheService extends Mock implements CacheService {}

void main() {
  late MockNavigateRemote remote;
  late MockCacheService cache;
  late NavigateRepositoryImpl repository;

  setUp(() {
    remote = MockNavigateRemote();
    cache = MockCacheService();
    repository = NavigateRepositoryImpl(
      remoteDataSource: remote,
      cacheService: cache,
    );
  });

  test('stores a successful route check for offline recovery', () async {
    when(() => cache.put(any(), any())).thenAnswer((_) async {});
    when(
      () => remote.checkRoute(
        fromLat: any(named: 'fromLat'),
        fromLon: any(named: 'fromLon'),
        toLat: any(named: 'toLat'),
        toLon: any(named: 'toLon'),
      ),
    ).thenAnswer(
      (_) async => RouteCheckDto.fromJson({
        'ok': true,
        'detour': false,
        'land_hit': false,
        'reason': 'Clear passage.',
        'distance_km': 10.0,
        'legs': [
          [18.92, 72.83],
          [18.75, 72.55],
        ],
        'sources': ['GLOBE 1km Landmask'],
      }),
    );

    final result = await repository.checkRoute(
      fromLat: 18.92,
      fromLon: 72.83,
      toLat: 18.75,
      toLon: 72.55,
    );

    expect(result.isOk, isTrue);
    verify(() => cache.put('last_known_route_check', any())).called(1);
  });

  test('uses cached route check when the backend is unavailable', () async {
    final cached = CachedRecord(
      data: {
        'ok': true,
        'land_hit': false,
        'legs': [
          [18.92, 72.83],
          [18.75, 72.55],
        ],
      },
      fetchedAt: DateTime.now().subtract(const Duration(hours: 4)),
      ttl: const Duration(minutes: 30),
    );
    when(() => cache.get('last_known_route_check')).thenReturn(cached);
    when(
      () => remote.checkRoute(
        fromLat: any(named: 'fromLat'),
        fromLon: any(named: 'fromLon'),
        toLat: any(named: 'toLat'),
        toLon: any(named: 'toLon'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/api/v1/route-check'),
        type: DioExceptionType.connectionError,
      ),
    );

    final result = await repository.checkRoute(
      fromLat: 18.92,
      fromLon: 72.83,
      toLat: 18.75,
      toLon: 72.55,
    );

    expect(result.isOk, isTrue);
    expect(result.valueOrNull?.legs.length, equals(2));
  });
}