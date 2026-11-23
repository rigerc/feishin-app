import 'package:core/core/di/core_injection.dart';

import '../feature/home/data/artwork_http.dart';
import '../feature/home/data/feishin_repository.dart';
import '../feature/home/data/remote_configuration.dart';
import '../feature/home/domain/remote.dart';
import '../feature/home/presentation/widgets/artwork.dart';

export 'package:core/core/di/core_injection.dart' show sl;

Future<void> initDependencies() async {
  await initCoreDependencies();
  sl.registerLazySingleton<RemoteRepository>(FeishinRepository.new);
  sl.registerLazySingleton(() => ArtworkCache(fetchArtwork));
  sl.registerLazySingleton<RemoteConfiguration>(
    PreferenceRemoteConfiguration.new,
  );
}
