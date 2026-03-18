## 1.2.0

- Added `Koolbase.storage` — file storage SDK
- `upload()` — upload files directly to Cloudflare R2 via presigned URLs
- `getDownloadUrl()` — get signed download URLs for private files
- `delete()` — delete files from storage
- `KoolbaseObject`, `KoolbaseBucket`, `UploadResult` models
- Automatic content type inference from file extension
- Three-step upload flow: get URL → upload → confirm

## 1.1.0

- Added `Koolbase.auth` — full authentication SDK
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
