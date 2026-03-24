# koolbase_flutter

Flutter SDK for [Koolbase](https://koolbase.com) — a Flutter-first Backend as a Service with authentication, database, storage, realtime, functions, feature flags, remote config, version enforcement, and OTA updates.

## Installation

```yaml
dependencies:
  koolbase_flutter: ^1.6.0
```

## Setup

Initialize the SDK before `runApp()`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Koolbase.initialize(const KoolbaseConfig(
    publicKey: 'pk_live_xxxx',  // From your Koolbase dashboard
    baseUrl: 'https://api.koolbase.com',
  ));

  runApp(MyApp());
}
```

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
// Insert a record
await Koolbase.db.collection('posts').insert({
  'title': 'Hello world',
  'body': 'My first post',
});

// Query records
final records = await Koolbase.db.collection('posts').get();

// Filter
final filtered = await Koolbase.db
    .collection('posts')
    .where('status', 'published')
    .get();

// Update
await Koolbase.db.collection('posts').doc('record-id').update({'title': 'Updated'});

// Delete
await Koolbase.db.collection('posts').doc('record-id').delete();
```

---

## Storage

```dart
// Upload a file
final file = File('/path/to/image.jpg');
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
  onCreated: (record) => print('New message: ${record.data}'),
  onUpdated: (record) => print('Updated: ${record.data}'),
  onDeleted: (record) => print('Deleted: ${record.id}'),
);

// Cancel when done
subscription.cancel();
```

---

## Functions

```dart
// Invoke a deployed function
final result = await Koolbase.functions.invoke(
  'send-welcome-email',
  body: {'userId': '123', 'email': 'user@example.com'},
);

if (result.success) {
  print(result.data);
}
```

---

## OTA Updates

```dart
// Auto-check and download on launch
final result = await Koolbase.ota.initialize(
  channel: 'production',
  onProgress: (p) => print('${p.state}'),
);

// Read a JSON file from the active bundle
final config = await Koolbase.ota.readJson('config.json');

// Get path to a bundled asset
final bannerPath = await Koolbase.ota.getFilePath('banner.png');

// Manual check
final check = await Koolbase.ota.check(channel: 'production');
if (check.hasUpdate) {
  await Koolbase.ota.download(check);
}
```

---

## Feature Flags

```dart
if (Koolbase.isEnabled('new_checkout')) {
  // show new checkout
}
```

---

## Remote Config

```dart
final timeout = Koolbase.configInt('swap_timeout_seconds', fallback: 30);
final url = Koolbase.configString('api_base_url', fallback: 'https://api.example.com');
final debugMode = Koolbase.configBool('debug_mode', fallback: false);
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
    // All good
    break;
}
```

---

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

---

## Documentation

Full documentation at [docs.koolbase.com](https://docs.koolbase.com)

## Dashboard

Manage your projects, environments, and features at [app.koolbase.com](https://app.koolbase.com)

## License

MIT
