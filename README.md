# Caffeine

<p align="center">
  <img src="Assets/icon.png" alt="Caffeine app logo" width="128" style="border-radius: 24px;">
</p>

Caffeine is a small macOS menu-bar app that keeps your Mac awake with Apple's built-in `/usr/bin/caffeinate` command. It has no network service, account, analytics, or background daemon beyond the running menu-bar app.

## Supported macOS versions

- macOS 11 Big Sur and newer
- Apple silicon and Intel Macs supported by the active macOS version

Start at Login uses `SMAppService` on macOS 13+ and a user LaunchAgent on macOS 11–12.

## Features

- Turn sleep prevention on or off from the menu bar.
- Run forever or for 15 minutes, 30 minutes, 1 hour, or 2 hours.
- Show remaining time in the menu bar while active.
- Optional Start at Login.
- Quit cleanly and stop the active `caffeinate` process.

## Install from release DMG

1. Download `Caffeine-1.0-arm64.dmg` for Apple silicon or `Caffeine-1.0-x86_64.dmg` for Intel.
2. Open the DMG.
3. Drag `Caffeine.app` to `Applications`.
4. Open Caffeine from `/Applications`.

The local build is ad-hoc signed by default. For public distribution, build with a Developer ID signing identity and notarize the DMG before publishing.

## Build

Requirements: macOS 11+, Xcode Command Line Tools, `swiftc`, `sips`, `iconutil`, `codesign`, and `hdiutil`.

```sh
./build.sh
open build/Caffeine.app
```

Release artifacts:

```sh
ARCH=arm64 ./build.sh
ARCH=x86_64 ./build.sh
ls build/Caffeine-1.0-arm64.dmg build/Caffeine-1.0-x86_64.dmg
```

Optional Developer ID signing:

```sh
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" ./build.sh
```

## Test

```sh
./test.sh
```

The test script type-checks the Swift source, builds the app, validates the bundle metadata, verifies codesigning, and checks the generated DMG.

## Privacy and security

Caffeine does not collect data, make network requests, or install privileged helpers. It launches `/usr/bin/caffeinate` with standard macOS power-management assertions. Start at Login can be disabled from the app menu.

## Troubleshooting

- **Gatekeeper warning:** local ad-hoc builds are not notarized. Use a notarized Developer ID release for external users.
- **Start at Login does not work:** move the app to `/Applications`, open it once, then toggle Start at Login off and on.
- **Uninstall:** turn off Start at Login, quit Caffeine, and delete `Caffeine.app`.

## Version

Current version: 1.0

## License

No open-source license is currently included. Contact the owner before redistribution.
