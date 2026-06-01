// Derived from work in the libserialport project:
// https://sigrok.org/wiki/Libserialport
// See repository license files for redistribution terms.
// SPDX-License-Identifier: MIT

import 'dart:io';

// Preserve runtimeType in error strings so the concrete error class appears.
// ignore_for_file: no_runtimetype_tostring

/// Error reported by libserialport operations.
class SerialPortError extends OSError {
  /// Creates a serial-port-specific OS error.
  ///
  /// [message] and [errorCode] correspond to the underlying platform error.
  const SerialPortError([
    super.message = '',
    super.errorCode = OSError.noErrorCode,
  ]);

  @override
  String toString() {
    return super.toString().replaceFirst('OS Error', runtimeType.toString());
  }
}
