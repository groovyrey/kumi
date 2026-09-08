# Kumi

A Flutter streaming app for movies and TV, built and released by GitHub
Actions. Content comes from TMDb; playback runs inside an embed player with a
built-in ad-layer guard.

## Features

- Browse movies (popular, now playing, upcoming, top rated) and series
  (popular, on the air, trending), search, and genre filters
- Detail pages with poster, backdrop, cast, and runtime; series pages with
  season/episode lists
- Streaming via configurable embed sources (`lib/config.dart`); the player
  strips known ad layers and resumes where you left off
- My List favourites, watch history with progress, and a schedule screen
- Version checker that compares the installed build against the latest GitHub
  release (stable releases only; never warns about pre-releases)
- Light/dark/system theme with an accent-color picker (crimson by default)
- About screen with GitHub / Facebook / Email links

## Stack

- Flutter (stable) on upstream `ubuntu-latest` runners, pinned to
  `3.41.0` (`IconData` became final in 3.44, which breaks `phosphor_flutter` 2.1.0)
- Gradle 8.14.1, AGP 8.11.1, Kotlin 2.2.20, Java 17
- Android package: `com.groovyrey.kumi`, minSdk 24
- State: `provider`; theme: `google_fonts`; icons: `phosphor_flutter`
- Data: TMDb API (`lib/services/tmdb_service.dart`); embeds: WebView
  (`webview_flutter`)

## Layout

```
lib/
  main.dart                  entry + splash gate
  config.dart                TMDb keys and embed source templates
  theme/app_theme.dart       palette and typography
  state/app_state.dart       theme mode + accent persistence
  models/                   media item, genre, series details
  services/                 TMDb, favorites, watch history, version checker, screen time
  screens/                  app shell, home, browse, detail, my list, player,
                            schedule, settings, about
  widgets/                  embed ad guard, poster rails, media grid, web controls, kumi mark
test/app_test.dart
```

## CI / release flow

The workflow in `.github/workflows/build.yml` runs on every push to `main`,
pull request, and tag `v*`. It installs Flutter (pinned), analyzes, runs tests,
builds the release APK, and:

- On `main` pushes, publishes a rolling pre-release to the `beta` tag
  (`Kumi-<version>-beta.apk`)
- On `v*` tags, attaches `Kumi-<version>.apk` to a stable GitHub release

To publish a stable release:

```sh
git tag v1.4.8
git push origin v1.4.8
```