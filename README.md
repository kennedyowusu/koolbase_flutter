# koolbase_flutter

[![pub.dev](https://img.shields.io/pub/v/koolbase_flutter.svg)](https://pub.dev/packages/koolbase_flutter)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Flutter SDK for [Koolbase](https://koolbase.com) — Backend as a Service built for mobile developers.

Auth, database, storage, realtime, functions, feature flags, remote config, version enforcement, OTA updates, code push, server-driven UI, logic engine, and analytics — one SDK, one `initialize()` call.

---

## Get started in 2 minutes

**1. Create a free account at [app.koolbase.com](https://app.koolbase.com)**

**2. Create a project and copy your public key from Environments**

**3. Add the SDK:**

```yaml
dependencies:
  koolbase_flutter: ^2.3.0
```

**4. Initialize before `runApp()`:**

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Koolbase.initialize(KoolbaseConfig(
    publicKey: 'pk_live_xxxx',
    baseUrl: 'https://api.koolbase.com',
  ));

  runApp(MyApp());
}
```

That's it. Every feature below is now available via `Koolbase.*`.

---

## Authentication

```dart
// Register
await Koolbase.auth.register(email: 'user@example.com', password: 'password');

// Login
await Koolbase.auth.login(email: 'user@example.com', password: 'password');

// Current user
final user = Koolbase.auth.currentUser;

// Logout
await Koolbase.auth.logout();

// Google OAuth
await Koolbase.auth.signInWithGoogle(idToken: googleIdToken);

// Password reset
await Koolbase.auth.forgotPassword(email: 'user@example.com');
```

---

## Database

```dart
// Insert
await Koolbase.db.collection('posts').insert({
  'title': 'Hello world',
  'body': 'My first post',
});

// Query
final records = await Koolbase.db.collection('posts').get();

// Filter
final filtered = await Koolbase.db
    .collection('posts')
    .where('status', 'published')
    .get();

// Relational data
final result = await Koolbase.db
    .collection('posts')
    .populate(['author_id:users'])
    .get();

// Update
await Koolbase.db.collection('posts').doc('record-id').update({'title': 'Updated'});

// Delete
await Koolbase.db.collection('posts').doc('record-id').delete();
```

### Offline-first

The SDK caches all reads locally using Drift. Queries return instantly from cache and refresh in the background. Writes are queued and synced automatically when online.

```dart
final result = await Koolbase.db.collection('posts').get();
print(result.isFromCache); // true if served from local cache

await Koolbase.db.syncPendingWrites();
```

---

## Storage

```dart
// Upload
await Koolbase.storage.upload(
  bucket: 'avatars',
  path: 'user-123.jpg',
  file: file,
  onProgress: (p) => print('${p.percentage}%'),
);

// Get download URL
final url = await Koolbase.storage.getDownloadUrl(
  bucket: 'avatars',
  path: 'user-123.jpg',
);

// Delete
await Koolbase.storage.delete(bucket: 'avatars', path: 'user-123.jpg');
```

---

## Realtime

```dart
final subscription = Koolbase.realtime.on(
  collection: 'messages',
  onCreated: (record) => print('New: ${record.data}'),
  onUpdated: (record) => print('Updated: ${record.data}'),
  onDeleted: (record) => print('Deleted: ${record.id}'),
);

subscription.cancel();
```

---

## Functions

```dart
// Invoke a deployed function
final result = await Koolbase.functions.invoke(
  'send-welcome-email',
  body: {'userId': '123'},
);

if (result.success) print(result.data);
```

---

## Feature Flags & Remote Config

```dart
// Feature flag
if (Koolbase.isEnabled('new_checkout')) {
  // show new checkout
}

// Remote config
final timeout = Koolbase.configInt('api_timeout_ms', fallback: 3000);
final url = Koolbase.configString('api_url', fallback: 'https://api.example.com');
final dark = Koolbase.configBool('force_dark_mode', fallback: false);
```

---

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
    break;
}
```

---

## OTA Updates

```dart
final result = await Koolbase.ota.initialize(channel: 'production');

// Read a JSON file from the active bundle
final config = await Koolbase.ota.readJson('config.json');

// Get path to a bundled asset
final path = await Koolbase.ota.getFilePath('banner.png');
```

---

## Code Push

Push config overrides, feature flag overrides, and UI updates to your app without a store release.

```dart
await Koolbase.initialize(KoolbaseConfig(
  publicKey: 'pk_live_xxxx',
  baseUrl: 'https://api.koolbase.com',
  codePushChannel: 'stable',
));

// Bundle values transparently override Remote Config + Feature Flags
final timeout = Koolbase.configInt('api_timeout_ms', fallback: 3000);
final enabled = Koolbase.isEnabled('new_checkout_flow');

// Directive handlers
Koolbase.codePush.onDirective('force_logout_all', (value) {
  if (value == true) Koolbase.auth.logout();
});
```

---

## Server-Driven UI

Push new screen layouts OTA using Flutter's official `rfw` package. Change your app UI without shipping a new binary.

```dart
// Wrap your app
KoolbaseCodePushScope(
  client: Koolbase.codePush,
  child: MaterialApp(...),
)

// Drop a dynamic screen anywhere
KoolbaseDynamicScreen(
  screenId: 'onboarding',
  data: { 'username': user.name },
  onEvent: (name, args) {
    if (name == 'get_started') Navigator.pushNamed(context, '/home');
  },
  fallback: const OnboardingScreen(),
)
```

---

## Logic Engine

Define conditional app behavior as data in your Runtime Bundle — no code changes required.

```dart
// flows.json in your bundle
// {
//   "on_checkout_tap": {
//     "type": "if",
//     "condition": { "op": "eq", "left": { "from": "context.plan" }, "right": "free" },
//     "then": { "type": "event", "name": "show_upgrade" },
//     "else": { "type": "event", "name": "go_checkout" }
//   }
// }

final result = Koolbase.executeFlow(
  flowId: 'on_checkout_tap',
  context: { 'plan': user.plan },
);

if (result.hasEvent) {
  Navigator.pushNamed(context, result.eventName!);
}
```

---

## Analytics

Track screen views, custom events, and user behaviour. View DAU, WAU, MAU, top events, and top screens in the Koolbase dashboard.

```dart
// Add to MaterialApp for automatic screen tracking
MaterialApp(
  navigatorObservers: [
    KoolbaseNavigatorObserver(client: Koolbase.analytics),
  ],
)

// Custom events
Koolbase.analytics.track('purchase', properties: {
  'value': 1200,
  'currency': 'GHS',
});

// User identity
Koolbase.analytics.identify(user.id);
Koolbase.analytics.setUserProperty('plan', 'pro');

// On logout
Koolbase.analytics.reset();
```

---

## What's included

| Feature | Koolbase | Firebase | Supabase |
| --- | --- | --- | --- |
| Flutter-first SDK | ✅ | ✅ | ❌ |
| Feature flags | ✅ | ❌ | ❌ |
| Remote config | ✅ | ✅ | ❌ |
| Version enforcement | ✅ | ❌ | ❌ |
| Dart functions runtime | ✅ | ❌ | ❌ |
| Offline-first database | ✅ | ✅ | ❌ |
| Code push (OTA) | ✅ | ❌ | ❌ |
| Server-driven UI | ✅ | ❌ | ❌ |
| Logic engine (flows OTA) | ✅ | ❌ | ❌ |
| Analytics | ✅ | ✅ | ❌ |
| Self-hostable | ✅ | ❌ | ✅ |

---

## Documentation

Full documentation at [docs.koolbase.com](https://docs.koolbase.com)

## Dashboard

Manage your projects at [app.koolbase.com](https://app.koolbase.com)

## Support

- [GitHub Issues](https://github.com/kennedyowusu/koolbase_flutter/issues)
- [docs.koolbase.com](https://docs.koolbase.com)
- Email: <hello@koolbase.com>

## License

MIT
