/// Koolbase Flutter SDK
///
/// Deployment control, feature flags, and remote config for Flutter apps.
///
/// Usage:
/// ```dart
/// import 'package:koolbase_flutter/koolbase_flutter.dart';
///
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///
///   await Koolbase.initialize(KoolbaseConfig(
///     publicKey: 'pk_live_xxxx',
///     baseUrl: 'https://api.koolbase.com',
///   ));
///
///   runApp(MyApp());
/// }
/// ```
library koolbase_flutter;

export 'src/koolbase.dart';
export 'src/payload.dart';
