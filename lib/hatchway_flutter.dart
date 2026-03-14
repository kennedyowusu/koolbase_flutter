/// Hatchway Flutter SDK
///
/// Deployment control, feature flags, and remote config for Flutter apps.
///
/// Usage:
/// ```dart
/// import 'package:hatchway_flutter/hatchway_flutter.dart';
///
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///
///   await Hatchway.initialize(HatchwayConfig(
///     publicKey: 'pk_live_xxxx',
///     baseUrl: 'https://api.hatchway.dev',
///   ));
///
///   runApp(MyApp());
/// }
/// ```
library hatchway_flutter;

export 'src/hatchway.dart';
export 'src/payload.dart';
