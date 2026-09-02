# Kumi

A fresh Flutter starter app, built and released by GitHub Actions.

## Stack

- Flutter (stable channel) on upstream `ubuntu-latest` runners
- Gradle 8.14.1, AGP 8.11.1, Kotlin 2.2.20, Java 17
- Android package: `com.groovyrey.kumi`, minSdk 24
- State: `provider`, theme via `google_fonts`, icons via `phosphor_flutter`

## Layout

```
lib/
  main.dart            entry + splash gate
  theme/app_theme.dart palette and typography
  state/app_state.dart theme mode persistence
  screens/home_screen.dart
  widgets/kumi_mark.dart, theme_toggle.dart
test/app_test.dart
```

## CI / release flow

The workflow in `.github/workflows/build.yml` runs on every push to `main`,
pull request, and tag `v*`. It installs Flutter, analyzes, runs tests, builds
the release APK, and uploads it as an action artifact.

To publish a downloadable release, create a `v*` tag:

```sh
git tag v1.0.0
git push origin v1.0.0
```

The workflow then attaches `app-release.apk` to the GitHub release for that
tag, ready to download and install on a device.