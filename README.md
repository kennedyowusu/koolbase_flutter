# koolbase_flutter

Flutter SDK for [Koolbase](https://koolbase.com) — feature flags, remote config, and version enforcement for mobile apps.

## Installation

```yaml
dependencies:
  koolbase_flutter: ^1.0.0
```

## Setup

Initialize the SDK before `runApp()`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Koolbase.initialize(KoolbaseConfig(
    publicKey: 'pk_live_xxxx',  // From your Koolbase dashboard
    baseUrl: 'https://api.koolbase.com',
  ));

  runApp(MyApp());
}
```

## Feature Flags

```dart
if (Koolbase.isEnabled('new_checkout')) {
  // show new checkout
}
```

## Remote Config

```dart
final timeout = Koolbase.configInt('swap_timeout_seconds', fallback: 30);
final url = Koolbase.configString('api_base_url', fallback: 'https://api.example.com');
final debugMode = Koolbase.configBool('debug_mode', fallback: false);
```

## Version Enforcement

```dart
final result = Koolbase.checkVersion();

switch (result.status) {
  case VersionStatus.forceUpdate:
    // Block the app — show update screen
    break;
  case VersionStatus.softUpdate:
    // Show a banner
    break;
  case VersionStatus.upToDate:
    // All good
    break;
}
```

## How It Works

1. On first launch, the SDK generates a stable anonymous device UUID stored in secure storage
2. On init, the cached payload loads instantly — no network wait
3. A fresh bootstrap payload is fetched in the background
4. Flag evaluation happens locally using `stableHash(deviceId + ":" + flagKey) % 100`
5. The payload refreshes on a configurable interval (default 60s)
6. If the network is unavailable, the last cached payload is used

## Rollout Bucketing

Rollout decisions are made locally by the SDK, not the server. This means:

- The bootstrap response is identical for all devices (CDN cacheable)
- The same device always gets the same flag result (stable)
- Evaluation works offline

```dart
// This is what happens internally
final bucket = stableHash('$deviceId:$flagKey') % 100;
final enabled = bucket < flag.rolloutPercentage;
```
