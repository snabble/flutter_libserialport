// Derived from work in the libserialport project:
// https://sigrok.org/wiki/Libserialport
// See repository license files for redistribution terms.
// SPDX-License-Identifier: MIT

import 'dart:ffi' as ffi;
import 'dart:typed_data';

import 'package:ffi/ffi.dart' as ffi;
import 'package:flutter_libserialport/src/bindings.dart';
import 'package:flutter_libserialport/src/config.dart';
import 'package:flutter_libserialport/src/dylib.dart';
import 'package:flutter_libserialport/src/enums.dart';
import 'package:flutter_libserialport/src/error.dart';
import 'package:flutter_libserialport/src/util.dart';

/// High-level wrapper for platform serial ports.
///
/// Provides discovery, open/close, configuration and read/write operations.
/// Errors from native code are surfaced as [SerialPortError].
abstract class SerialPort {
  /// Create a [SerialPort] instance for the given platform port name.
  ///
  /// Call [dispose] when finished to free native resources.
  factory SerialPort(String name) => _SerialPortImpl(name);

  /// @internal
  factory SerialPort.fromAddress(int address) =>
      _SerialPortImpl.fromAddress(address);

  /// @internal
  int get address;

  /// List available serial port names on the host system.
  static List<String> get availablePorts => _SerialPortImpl.availablePorts;

  /// Release native resources associated with the port.
  void dispose();

  /// Open the port with the given access [mode] (see [SerialPortMode]).
  bool open({required int mode});

  /// Opens the serial port for reading only.
  bool openRead();

  /// Opens the serial port for writing only.
  bool openWrite();

  /// Opens the serial port for reading and writing.
  bool openReadWrite();

  /// Closes the serial port.
  bool close();

  /// True if the port is currently open.
  bool get isOpen;

  /// Host-specific port name (e.g. "/dev/ttyUSB0" or "COM3").
  String? get name;

  /// Human-readable description for the port, if available.
  String? get description;

  /// Transport type of the port (see [SerialPortTransport]).
  int get transport;

  /// USB bus number for USB adapters, or null if not applicable.
  int? get busNumber;

  /// USB device address on the bus for USB adapters, or null if not applicable.
  int? get deviceNumber;

  /// USB vendor ID for USB adapters, or null if not applicable.
  int? get vendorId;

  /// USB product ID for USB adapters, or null if not applicable.
  int? get productId;

  /// USB manufacturer string, if available.
  String? get manufacturer;

  /// USB product name, if available.
  String? get productName;

  /// USB serial number string, if available.
  String? get serialNumber;

  /// MAC address for Bluetooth adapters, if available.
  String? get macAddress;

  /// Current configuration snapshot for the open port.
  SerialPortConfig get config;

  /// Apply a configuration to the port. Use `-1` for fields that should be
  /// left unchanged.
  set config(SerialPortConfig config);

  /// Read up to [bytes] from the port. If [timeout] >= 0 the call is blocking
  /// and the timeout is in milliseconds (0 = wait indefinitely). Returns the
  /// read bytes as a [Uint8List].
  Uint8List read(int bytes, {int timeout = -1});

  /// Write [bytes] to the port. If [timeout] >= 0 the call is blocking and the
  /// timeout is in milliseconds. Returns the number of bytes written.
  int write(Uint8List bytes, {int timeout = -1});

  /// Number of bytes currently available for reading.
  int get bytesAvailable;

  /// Number of bytes pending in the output buffer.
  int get bytesToWrite;

  /// Flush selected buffers. [buffers] is one of [SerialPortBuffer].
  void flush([int buffers = SerialPortBuffer.both]);

  /// Block until all buffered output has been transmitted.
  void drain();

  /// Current control signal bitmask for the port.
  int get signals;

  /// Put the transmit line into break state.
  bool startBreak();

  /// Clear the transmit break state.
  bool endBreak();

  /// Gets the error for a failed operation.
  static SerialPortError? get lastError => _SerialPortImpl.lastError;
}

class _SerialPortImpl implements SerialPort {
  final ffi.Pointer<sp_port> _port;
  SerialPortConfig? _config;

  _SerialPortImpl(String name) : _port = _init(name);

  _SerialPortImpl.fromAddress(int address)
    : _port = ffi.Pointer<sp_port>.fromAddress(address);

  @override
  int get address => _port.address;

  static ffi.Pointer<sp_port> _init(String name) {
    final out = ffi.calloc<ffi.Pointer<sp_port>>();
    final cstr = Util.toUtf8(name);
    Util.call(() => dylib.sp_get_port_by_name(cstr, out).value);
    final port = out[0];
    ffi.calloc.free(out);
    ffi.calloc.free(cstr);
    return port;
  }

  static List<String> get availablePorts {
    final out = ffi.calloc<ffi.Pointer<ffi.Pointer<sp_port>>>();
    final rv = Util.call(() => dylib.sp_list_ports(out).value);
    if (rv != sp_return.SP_OK.value) {
      ffi.calloc.free(out);
      return <String>[];
    }
    var i = -1;
    final ports = <String>[];
    final array = out.value;
    while (array[++i] != ffi.nullptr) {
      final port = Util.fromUtf8(dylib.sp_get_port_name(array[i]));
      if (port != null) ports.add(port);
    }
    dylib.sp_free_port_list(array);
    return ports;
  }

  @override
  void dispose() {
    _config?.dispose();
    dylib.sp_free_port(_port);
  }

  @override
  bool open({required int mode}) =>
      dylib.sp_open(_port, sp_mode.fromValue(mode)) == sp_return.SP_OK;

  @override
  bool openRead() => open(mode: SerialPortMode.read);

  @override
  bool openWrite() => open(mode: SerialPortMode.write);

  @override
  bool openReadWrite() => open(mode: SerialPortMode.readWrite);

  @override
  bool close() => dylib.sp_close(_port) == sp_return.SP_OK;

  @override
  bool get isOpen {
    final handle = Util.getInt((ptr) {
      return dylib.sp_get_port_handle(_port, ptr.cast()).value;
    })!;
    return handle > 0;
  }

  @override
  String? get name => Util.fromUtf8(dylib.sp_get_port_name(_port));

  @override
  String? get description {
    return Util.fromUtf8(dylib.sp_get_port_description(_port));
  }

  @override
  int get transport => dylib.sp_get_port_transport(_port).value;

  @override
  int? get busNumber {
    return Util.getInt((ptr) {
      return dylib.sp_get_port_usb_bus_address(_port, ptr, ffi.nullptr).value;
    });
  }

  @override
  int? get deviceNumber {
    return Util.getInt((ptr) {
      return dylib.sp_get_port_usb_bus_address(_port, ffi.nullptr, ptr).value;
    });
  }

  @override
  int? get vendorId {
    return Util.getInt((ptr) {
      return dylib.sp_get_port_usb_vid_pid(_port, ptr, ffi.nullptr).value;
    });
  }

  @override
  int? get productId {
    return Util.getInt((ptr) {
      return dylib.sp_get_port_usb_vid_pid(_port, ffi.nullptr, ptr).value;
    });
  }

  @override
  String? get manufacturer {
    return Util.fromUtf8(dylib.sp_get_port_usb_manufacturer(_port));
  }

  @override
  String? get productName {
    return Util.fromUtf8(dylib.sp_get_port_usb_product(_port));
  }

  @override
  String? get serialNumber {
    return Util.fromUtf8(dylib.sp_get_port_usb_serial(_port));
  }

  @override
  String? get macAddress {
    return Util.fromUtf8(dylib.sp_get_port_bluetooth_address(_port));
  }

  @override
  SerialPortConfig get config {
    if (_config == null) {
      _config = SerialPortConfig();
      final ptr = ffi.Pointer<sp_port_config>.fromAddress(_config!.address);
      Util.call(() => dylib.sp_get_config(_port, ptr).value);
    }
    return _config!;
  }

  @override
  set config(SerialPortConfig config) {
    if (_config != config) {
      _config?.dispose();
    }
    _config = config;
    final ptr = ffi.Pointer<sp_port_config>.fromAddress(config.address);
    Util.call(() => dylib.sp_set_config(_port, ptr).value);
  }

  @override
  Uint8List read(int bytes, {int timeout = -1}) {
    return Util.read(bytes, (ffi.Pointer<ffi.Uint8> ptr) {
      return timeout < 0
          ? rawNonblockingRead(_port, ptr.cast(), bytes)
          : rawBlockingRead(_port, ptr.cast(), bytes, timeout);
    });
  }

  @override
  int write(Uint8List bytes, {int timeout = -1}) {
    return Util.write(bytes, (ffi.Pointer<ffi.Uint8> ptr) {
      return timeout < 0
          ? rawNonblockingWrite(_port, ptr.cast(), bytes.length)
          : rawBlockingWrite(_port, ptr.cast(), bytes.length, timeout);
    });
  }

  @override
  int get bytesAvailable => rawInputWaiting(_port);

  @override
  int get bytesToWrite => rawOutputWaiting(_port);

  @override
  void flush([int buffers = SerialPortBuffer.both]) {
    dylib.sp_flush(_port, sp_buffer.fromValue(buffers));
  }

  @override
  void drain() => dylib.sp_drain(_port);

  @override
  int get signals {
    final ptr = ffi.calloc<ffi.UnsignedInt>();
    Util.call(() => dylib.sp_get_signals(_port, ptr).value);
    final value = ptr.value;
    ffi.calloc.free(ptr);
    return value;
  }

  @override
  bool startBreak() => dylib.sp_start_break(_port) == sp_return.SP_OK;

  @override
  bool endBreak() => dylib.sp_end_break(_port) == sp_return.SP_OK;

  static SerialPortError? get lastError {
    final ptr = dylib.sp_last_error_message();
    final str = Util.fromUtf8(ptr);
    if (str == null) return null;
    dylib.sp_free_error_message(ptr);
    return SerialPortError(str, dylib.sp_last_error_code());
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _SerialPortImpl && _port == other._port;
  }

  @override
  int get hashCode => _port.hashCode;

  @override
  String toString() => 'SerialPort($_port)';
}
