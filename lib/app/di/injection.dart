import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

final GetIt getIt = GetIt.instance;

/// Top-level DI bootstrap. The generated `injection.config.dart` file is
/// produced by running `dart run build_runner build`.
@InjectableInit(
  initializerName: r'$initGetIt',
  preferRelativeImports: true,
  asExtension: false,
)
Future<void> configureDependencies() async {
  // After running build_runner, uncomment the following line:
  // await $initGetIt(getIt);

  // Until codegen runs, manually register the most critical singletons here
  // so the app can boot without the generated file existing.
  await _manualBootstrap();
}

Future<void> _manualBootstrap() async {
  // Manual registration site for early-boot dependencies that should exist
  // even before build_runner has been executed for the first time.
}
