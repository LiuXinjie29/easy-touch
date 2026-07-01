# EasyTouch

Minimal macOS prototype: when the app window is active, touching the trackpad with exactly three fingers sends `Option+S`.

## Build

```sh
make
```

## Run

```sh
open build/EasyTouch.app
```

The app asks macOS for Accessibility permission because it posts a synthetic keyboard event. Grant permission in System Settings if prompted, then run it again.

## Test

```sh
make test
```

The automated tests cover the three-finger detection and ensure only the `Option+S` shortcut is emitted.
