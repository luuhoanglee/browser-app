import '../../../core/services/oxodb_service.dart';
import '../../../core/usecases/usecase.dart';

class GetCachedWebsiteInfoParams {
  final String url;

  const GetCachedWebsiteInfoParams({required this.url});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GetCachedWebsiteInfoParams &&
          runtimeType == other.runtimeType &&
          url == other.url;

  @override
  int get hashCode => url.hashCode;
}

class GetCachedWebsiteInfoUseCase extends UseCase<WebsiteInfo?, GetCachedWebsiteInfoParams> {
  @override
  Future<WebsiteInfo?> call(GetCachedWebsiteInfoParams params) {
    return OxodbService.getCachedInfo(params.url);
  }
}
