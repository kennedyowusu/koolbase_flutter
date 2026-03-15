import 'package:flutter/material.dart';
import 'package:koolbase_flutter/koolbase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hatchway.initialize(
    const HatchwayConfig(
      publicKey: 'pk_live_6e4abe2ffba691e8e44093d9',
      baseUrl: 'http://172.20.10.12:8080',
      refreshInterval: Duration(seconds: 30),
    ),
  );

  final versionCheck = Hatchway.checkVersion();
  if (versionCheck.status == VersionStatus.forceUpdate) {
    runApp(ForceUpdateApp(message: versionCheck.message));
    return;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(title: 'Koolbase Example', home: HomeScreen());
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final showNewAuthFlow = Hatchway.isEnabled('new_auth_flow');
    final swapTimeout = Hatchway.configInt('swap_timeout_config', fallback: 30);
    final versionCheck = Hatchway.checkVersion();

    return Scaffold(
      appBar: AppBar(title: const Text('Koolbase Example')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Device ID: ${Hatchway.deviceId}'),
            Text('Payload Version: ${Hatchway.payloadVersion}'),
            const SizedBox(height: 16),
            Text('new_auth_flow enabled: $showNewAuthFlow'),
            Text('swap_timeout_config: ${swapTimeout}s'),
            const SizedBox(height: 16),
            if (showNewAuthFlow)
              ElevatedButton(
                onPressed: () {},
                child: const Text('New Auth Flow'),
              )
            else
              ElevatedButton(
                onPressed: () {},
                child: const Text('Legacy Auth Flow'),
              ),
            if (versionCheck.status == VersionStatus.softUpdate)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                color: Colors.amber[100],
                child: Text(
                  versionCheck.message.isNotEmpty
                      ? versionCheck.message
                      : 'A new version is available!',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ForceUpdateApp extends StatelessWidget {
  final String message;
  const ForceUpdateApp({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.system_update, size: 64, color: Colors.blue),
                const SizedBox(height: 16),
                const Text(
                  'Update Required',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  message.isNotEmpty
                      ? message
                      : 'Please update the app to continue.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Update Now'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
