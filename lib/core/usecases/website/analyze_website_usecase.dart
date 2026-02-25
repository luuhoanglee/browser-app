import '../../../../../core/services/oxodb_service.dart';
import '../../../../../core/usecases/usecase.dart';

class AnalyzeWebsiteParams {
  final String url;
  final String? description;

  const AnalyzeWebsiteParams({
    required this.url,
    this.description,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalyzeWebsiteParams &&
          runtimeType == other.runtimeType &&
          url == other.url &&
          description == other.description;

  @override
  int get hashCode => url.hashCode ^ description.hashCode;
}

class AnalyzeWebsiteUseCase extends UseCase<void, AnalyzeWebsiteParams> {
  @override
  Future<void> call(AnalyzeWebsiteParams params) {
    return OxodbService.analyzeWebsite(
      params.url,
      description: params.description,
    );
  }
}
