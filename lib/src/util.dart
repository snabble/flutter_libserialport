// Derived from work in the libserialport project:
// https://sigrok.org/wiki/Libserialport
// See repository license files for redistribution terms.
// SPDX-License-Identifier: MIT

import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:typed_data';

import 'package:ffi/ffi.dart' as ffi;
import 'package:flutter_libserialport/src/bindings.dart';
import 'package:flutter_libserialport/src/port.dart';

typedef UtilFunc<T extends ffi.NativeType> = int Function(ffi.Pointer<T> ptr);

// Utility helpers used by the FFI bridge.
// ignore: avoid_classes_with_only_static_members
class Util {
  static int call(int Function() func) {
    final ret = func();
    if (ret < sp_return.SP_OK.value && SerialPort.lastError!.errorCode != 0) {
      throw SerialPort.lastError!;
    }
    return ret;
  }

  static Uint8List read(int bytes, UtilFunc<ffi.Uint8> readFunc) {
    return ffi.using((arena) {
      final ptr = arena<ffi.Uint8>(bytes);
      final len = call(() => readFunc(ptr));
      return Uint8List.fromList(ptr.asTypedList(len));
    });
  }

  static int write(Uint8List bytes, UtilFunc<ffi.Uint8> writeFunc) {
    return ffi.using((arena) {
      final len = bytes.length;
      final ptr = arena<ffi.Uint8>(len);
      ptr.asTypedList(len).setAll(0, bytes);
      return call(() => writeFunc(ptr));
    });
  }

  static String? fromUtf8(ffi.Pointer<ffi.Char> str) {
    if (str == ffi.nullptr) return null;
    final length = str.cast<ffi.Utf8>().length;
    try {
      return utf8.decode(str.cast<ffi.Uint8>().asTypedList(length));
    } catch (_) {
      return latin1.decode(str.cast<ffi.Uint8>().asTypedList(length));
    }
  }

  static ffi.Pointer<ffi.Char> toUtf8(String str) {
    return str.toNativeUtf8().cast<ffi.Char>();
  }

  static int? getInt(UtilFunc<ffi.Int> getFunc) {
    return ffi.using((arena) {
      final ptr = arena<ffi.Int>();
      final rv = call(() => getFunc(ptr));
      if (rv != sp_return.SP_OK.value) return null;
      return ptr.value;
    });
  }
}
