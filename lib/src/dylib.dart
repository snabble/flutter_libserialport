// Derived from work in the libserialport project:
// https://sigrok.org/wiki/Libserialport
// See repository license files for redistribution terms.
// SPDX-License-Identifier: MIT

import 'dart:ffi' as ffi;

import 'package:dylib/dylib.dart';
import 'package:flutter_libserialport/src/bindings.dart';

ffi.DynamicLibrary? _lib;
ffi.DynamicLibrary get _serialPortLib => _lib ??= ffi.DynamicLibrary.open(
  resolveDylibPath(
    'serialport',
    dartDefine: 'LIBSERIALPORT_PATH',
    environmentVariable: 'LIBSERIALPORT_PATH',
  ),
);

LibSerialPort? _dylib;
LibSerialPort get dylib => _dylib ??= LibSerialPort(_serialPortLib);

// Low-level direct lookups for functions that return raw integer counts or
// error codes. These bypass the generated `sp_return` wrappers.
final int Function(ffi.Pointer<sp_port>) rawInputWaiting = _serialPortLib
    .lookup<ffi.NativeFunction<ffi.Int Function(ffi.Pointer<sp_port>)>>(
      'sp_input_waiting',
    )
    .asFunction();

final int Function(ffi.Pointer<sp_port>) rawOutputWaiting = _serialPortLib
    .lookup<ffi.NativeFunction<ffi.Int Function(ffi.Pointer<sp_port>)>>(
      'sp_output_waiting',
    )
    .asFunction();

final int Function(ffi.Pointer<sp_port>, ffi.Pointer<ffi.Void>, int)
rawNonblockingRead = _serialPortLib
    .lookup<
      ffi.NativeFunction<
        ffi.Int Function(ffi.Pointer<sp_port>, ffi.Pointer<ffi.Void>, ffi.Size)
      >
    >('sp_nonblocking_read')
    .asFunction();

final int Function(ffi.Pointer<sp_port>, ffi.Pointer<ffi.Void>, int, int)
rawBlockingRead = _serialPortLib
    .lookup<
      ffi.NativeFunction<
        ffi.Int Function(
          ffi.Pointer<sp_port>,
          ffi.Pointer<ffi.Void>,
          ffi.Size,
          ffi.UnsignedInt,
        )
      >
    >('sp_blocking_read')
    .asFunction();

final int Function(ffi.Pointer<sp_port>, ffi.Pointer<ffi.Void>, int)
rawNonblockingWrite = _serialPortLib
    .lookup<
      ffi.NativeFunction<
        ffi.Int Function(ffi.Pointer<sp_port>, ffi.Pointer<ffi.Void>, ffi.Size)
      >
    >('sp_nonblocking_write')
    .asFunction();

final int Function(ffi.Pointer<sp_port>, ffi.Pointer<ffi.Void>, int, int)
rawBlockingWrite = _serialPortLib
    .lookup<
      ffi.NativeFunction<
        ffi.Int Function(
          ffi.Pointer<sp_port>,
          ffi.Pointer<ffi.Void>,
          ffi.Size,
          ffi.UnsignedInt,
        )
      >
    >('sp_blocking_write')
    .asFunction();

final int Function(ffi.Pointer<sp_event_set>, ffi.Pointer<sp_port>, int)
rawAddPortEvents = _serialPortLib
    .lookup<
      ffi.NativeFunction<
        ffi.Int Function(
          ffi.Pointer<sp_event_set>,
          ffi.Pointer<sp_port>,
          ffi.Int,
        )
      >
    >('sp_add_port_events')
    .asFunction();
