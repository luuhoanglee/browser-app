import '../../../core/services/oxodb_service.dart';
import '../../../core/usecases/usecase.dart';
import '../../../core/usecases/no_params.dart';

class ClearOxodbCacheUseCase extends UseCase<void, NoParams> {
  @override
  Future<void> call(NoParams params) {
    return OxodbService.clearCache();
  }
}
