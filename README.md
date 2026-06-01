# Serial Port for Flutter

`flutter_libserialport` is a Flutter plugin that provides cross-platform access to serial ports,
utilizing Flutter's build system to build and deploy the
[libserialport](https://sigrok.org/wiki/Libserialport) C-library for the target platform.

The Dart API (FFI bindings, port management, configuration, etc.) from the
[`libserialport.dart`](https://github.com/jpnurmi/libserialport.dart) package has been merged
directly into this package to remove the external Git dependency and ensure full Dart 3
compatibility.

## Supported platforms

- Linux
- macOS
- Windows
- Android

## Usage

Add `flutter_libserialport` as a [dependency in your pubspec.yaml](https://dart.dev/tools/pub/dependencies):

```yaml
dependencies:
  flutter_libserialport: ^0.7.0
```

Then import the package:

```dart
import 'package:flutter_libserialport/flutter_libserialport.dart';
```

![screenshot](https://raw.githubusercontent.com/jpnurmi/flutter_libserialport/main/doc/images/flutter_libserialport.png)

## Architecture

The native C library (`libserialport`) is compiled from source via the platform build systems
(CMake for Linux/Windows/Android, CocoaPods + Swift Package Manager for macOS).

The Dart layer uses FFI to communicate with the C library. The FFI bindings are auto-generated
from the C header using [`ffigen`](https://pub.dev/packages/ffigen).

## Regenerating FFI bindings

The file `lib/src/bindings.dart` is **auto-generated** and must not be edited manually.
To regenerate it after updating the C library sources in `third_party/libserialport/`:

```bash
dart run ffigen --config ffigen.yaml
```

### ffigen configuration notes

The `ffigen.yaml` uses a carefully chosen `enums.include` list. Only enums that are
truly exclusive (non-bitmask, non-mixed-return) are mapped to Dart enums:
`sp_mode`, `sp_parity`, `sp_rts`, `sp_cts`, `sp_dtr`, `sp_dsr`, `sp_xonxoff`,
`sp_flowcontrol`, `sp_transport`.

Enums such as `sp_return`, `sp_event`, `sp_buffer`, and `sp_signal` are intentionally
**not** mapped as Dart enums because:
- `sp_return` is also used as a return type for functions that can return byte counts
  (e.g. `sp_input_waiting`, `sp_nonblocking_read`), making the Dart enum's `fromValue()`
  throw on positive values.
- `sp_event`, `sp_buffer`, and `sp_signal` are bitmask flags that can be OR-combined,
  which is incompatible with exclusive Dart enums.

For these types, raw `int`-returning native function lookups are provided in `lib/src/dylib.dart`.
