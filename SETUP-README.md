# Image Bank - build & release fix pack

Copy these files into the ROOT of your Digital-Banking repo (same folder layout), overwriting the old ones.

| File | What changed |
|---|---|
| `.github/workflows/android-release.yml` | Flutter 3.35.7, installs SDK 36 + NDK 27.0.12077973, signs with your keystore, publishes a GitHub Release on `v*` tags |
| `frontend/.gitignore` | No longer ignores `android/ ios/ web/ linux/ macos/ windows/` |
| `frontend/android/settings.gradle` | AGP 8.9.1, Kotlin 2.1.0 |
| `frontend/android/gradle/wrapper/gradle-wrapper.properties` | Gradle 8.11.1 |
| `frontend/android/gradle.properties` | JVM args |
| `frontend/android/app/build.gradle` | `ndkVersion flutter.ndkVersion`, `minSdk flutter.minSdkVersion`, release signing from `key.properties` |
| `frontend/android/key.properties.example` | Template for local signed builds |

`pubspec.yaml` / `pubspec.lock` are NOT included - keep your current ones.

## 1. Fix the broken NDK on your PC ("did not have a source.properties file")
1. Close Android Studio and any running Gradle: `cd frontend\android` then `gradlew --stop`
2. Delete the folder `C:\Users\Image\AppData\Local\Android\sdk\ndk\27.0.12077973`
3. Reinstall it: Android Studio > SDK Manager > SDK Tools > tick "Show Package Details" under
   "NDK (Side by side)" > tick 27.0.12077973 > Apply. (Or run `sdkmanager "ndk;27.0.12077973"`.)
4. In `frontend`: `flutter clean`, `flutter pub get`, `flutter build apk --release`

## 2. Make a permanent signing key (once)
```
keytool -genkey -v -keystore release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
BACK UP `release.jks` and its passwords somewhere safe. If you lose it you can never ship an update
that installs over the old app. Do not commit it.

PowerShell, copy the key as base64:
```
[Convert]::ToBase64String([IO.File]::ReadAllBytes("release.jks")) | Set-Clipboard
```
GitHub repo > Settings > Secrets and variables > Actions > New repository secret:
- `ANDROID_KEYSTORE_BASE64` = the base64 text
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS` = `upload`
- `ANDROID_KEY_PASSWORD`

(For local signed builds copy `key.properties.example` to `frontend/android/key.properties` and fill it in.)

## 3. Push and release
```
git add .
git commit -m "Fix Android build and add release workflow"
git push origin main
git tag v1.0.1
git push origin v1.0.1
```
Check the Actions tab; when it is green the APK is under Releases.
Make sure `frontend/android`, `frontend/ios`, `frontend/web` etc. are committed
(`git status` after removing them from .gitignore), but NOT `frontend/build`.
