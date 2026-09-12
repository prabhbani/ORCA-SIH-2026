import 'package:dio/dio.dart';
import '../../../../core/cache/cache_service.dart';
import '../../../../core/result/app_failure.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/route_advisory.dart';
import '../../domain/entities/route_check.dart';
import '../../domain/repositories/navigate_repo.dart';
import '../datasources/navigate_remote.dart';
import '../dto/route_check_dto.dart';

/// Implementation of NavigateRepository (§10).
class NavigateRepositoryImpl implements NavigateRepository {
  final NavigateRemoteDataSource _remoteDataSource;
  final CacheService _cacheService;

  NavigateRepositoryImpl({
    required NavigateRemoteDataSource remoteDataSource,
    required CacheService cacheService,
  })  : _remoteDataSource = remoteDataSource,
        _cacheService = cacheService;

  @override
  Future<Result<RouteCheckEntity>> checkRoute({
    required double fromLat,
    required double fromLon,
    required double toLat,
    required double toLon,
  }) async {
    try {
      final dto = await _remoteDataSource.checkRoute(
        fromLat: fromLat,
        fromLon: fromLon,
        toLat: toLat,
        toLon: toLon,
      );
      await _cacheService.put('last_known_route_check', <String, dynamic>{
        'ok': dto.ok,
        'detour': dto.detour,
        'land_hit': dto.landHit,
        'reason': dto.reason,
        'distance_km': dto.distanceKm,
        'distance_nm': dto.distanceNm,
        'bearing_deg': dto.bearingDeg,
        'legs': dto.legsList,
        'detour_waypoint': dto.detourWpJson,
        'sources': dto.sources,
      });
      return Result.ok(dto.toEntity());
    } on DioException catch (dioErr) {
      final cached = _cacheService.get('last_known_route_check');
      if (cached != null) {
        return Result.ok(RouteCheckDto.fromJson(cached.data).toEntity());
      }
      if (dioErr.type == DioExceptionType.connectionTimeout) {
        return const Result.err(AppFailure.timeout());
      }
      return const Result.err(AppFailure.serverDown());
    } catch (e) {
      final cached = _cacheService.get('last_known_route_check');
      if (cached != null) {
        return Result.ok(RouteCheckDto.fromJson(cached.data).toEntity());
      }
      return Result.err(AppFailure.unknown(e.toString()));
    }
  }

  @override
  Future<Result<RouteAdvisoryEntity>> getRouteAdvisory({
    required double fromLat,
    required double fromLon,
    required double toLat,
    required double toLon,
  }) async {
    try {
      final dto = await _remoteDataSource.getRouteAdvisory(
        fromLat: fromLat,
        fromLon: fromLon,
        toLat: toLat,
        toLon: toLon,
      );
      await _cacheService.put('last_known_route_advisory', <String, dynamic>{
        'verdict': dto.verdictJson,
        'points': dto.pointsList,
        'safe_window_at_start': dto.safeWindowJson,
        'sources': dto.sources,
      });
      return Result.ok(dto.toEntity());
    } on DioException catch (dioErr) {
      final cached = _cacheService.get('last_known_route_advisory');
      if (cached != null) {
        return Result.ok(RouteAdvisoryDto.fromJson(cached.data).toEntity());
      }
      if (dioErr.type == DioExceptionType.connectionTimeout) {
        return const Result.err(AppFailure.timeout());
      }
      return const Result.err(AppFailure.serverDown());
    } catch (e) {
      final cached = _cacheService.get('last_known_route_advisory');
      if (cached != null) {
        return Result.ok(RouteAdvisoryDto.fromJson(cached.data).toEntity());
      }
      return Result.err(AppFailure.unknown(e.toString()));
    }
  }
}
