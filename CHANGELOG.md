## 1.9.0

- **Functions:** Added Dart runtime support
  - New `FunctionRuntime` enum — `FunctionRuntime.deno` and `FunctionRuntime.dart`
  - New `deploy()` method — deploy functions directly from Flutter
  - Fixed `invoke()` request body format

## 1.8.0

- **Database:** Offline-first support powered by Drift
  - Cache-first reads — instant UI, background network refresh
  - Optimistic writes — insert locally, sync when online
  - Auto-sync on network reconnect via connectivity_plus
  - Manual `Koolbase.db.syncPendingWrites()`
  - `QueryResult.isFromCache` flag
  - Write queue with max 3 retries before dropping
  - User-scoped cache — no cross-user data leakage

## 1.7.0

- **Database:** Added `.populate()` support on query builder for relational data
  - Fetch related records from other collections in a single query
  - Usage: `.populate(['author_id:users', 'category_id:categories'])`
  - Populated records are injected into `data` with the `_id` suffix removed (e.g. `author_id` → `author`)

## 1.6.0

- Full BaaS feature set — auth, database, storage, realtime, functions, feature flags, remote config, version enforcement, OTA updates

## 1.5.0

- **OTA Updates:** Added `Koolbase.ota` — over-the-air bundle updates for Flutter apps

## 1.4.0

- **Realtime:** Added `Koolbase.realtime` — WebSocket realtime SDK
  - `Koolbase.realtime.on(projectId, collection)` — stream of all events
  - `Koolbase.realtime.onRecordCreated(projectId, collection)` — stream of new records
  - `Koolbase.realtime.onRecordUpdated(projectId, collection)` — stream of updated records
  - `Koolbase.realtime.onRecordDeleted(projectId, collection)` — stream of deleted record IDs
  - `Koolbase.realtime.connectionState` — stream of connection status (true/false)
  - `Koolbase.realtime.setToken(token)` — set auth token for subscriptions
  - Auto-reconnect with 3 second backoff
  - Reference-counted subscriptions — safe for multiple listeners

## 1.3.0

- **Database:** Added `Koolbase.db` — database SDK
  - `Koolbase.db.collection('name').get()` — query records with fluent builder
  - `Koolbase.db.collection('name').where('field', isEqualTo: value).limit(20).get()`
  - `Koolbase.db.insert(collection: 'name', data: {...})` — insert records
  - `Koolbase.db.doc(id).get()` — fetch single record
  - `Koolbase.db.doc(id).update({...})` — patch record fields
  - `Koolbase.db.doc(id).delete()` — soft delete record
  - `KoolbaseRecord`, `KoolbaseCollection`, `QueryResult` models
  - Collection-level permission enforcement (public, authenticated, owner)

## 1.2.0

- **Storage:** Added `Koolbase.storage` — file storage SDK
  - `upload()` — upload files directly to Cloudflare R2 via presigned URLs
  - `getDownloadUrl()` — get signed download URLs for private files
  - `delete()` — delete files from storage
  - `KoolbaseObject`, `KoolbaseBucket`, `UploadResult` models
  - Three-step upload flow: get URL → upload → confirm

## 1.1.0

- **Auth:** Added `Koolbase.auth` — full authentication SDK
  - `signUp`, `login`, `logout`, `forgotPassword`, `resetPassword`, `verifyEmail`
  - `currentUser`, `isAuthenticated`, `authStateChanges` stream
  - Automatic session restoration on app start
  - Secure token storage via `flutter_secure_storage`
  - JWT access tokens with automatic refresh
  - `KoolbaseUser`, `AuthSession` models
  - `KoolbaseAuthException` and typed exceptions

## 1.0.0

- Initial release
- Feature flags with rollout percentages and kill switches
- Remote config (string, int, double, bool, map)
- Version enforcement with force/soft update policies
- Offline support with local cache
- Background polling
