// Derived from work in the libserialport project:
// https://sigrok.org/wiki/Libserialport
// See repository license files for redistribution terms.
// SPDX-License-Identifier: MIT

import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:flutter_libserialport/src/bindings.dart';
import 'package:flutter_libserialport/src/dylib.dart';
import 'package:flutter_libserialport/src/util.dart';

/// Holds configuration values for a serial port.
///
/// This object mirrors libserialport's configuration model. Settings are
/// represented as integers; use `-1` to indicate "leave unchanged" when
/// applying a configuration to a port. Call [dispose] to free native resources
/// when finished.
///
/// See [SerialPort.config].
abstract class SerialPortConfig {
  /// Create a new, empty serial port configuration.
  ///
  /// Note: the returned instance must be released with [dispose].
  factory SerialPortConfig() => _SerialPortConfigImpl();

  /// @internal
  factory SerialPortConfig.fromAddress(int address) =>
      _SerialPortConfigImpl.fromAddress(address);

  /// @internal
  int get address;

  /// Release native resources held by this configuration.
  void dispose();

  /// Baud rate in bits per second, or `-1` if unset.
  int get baudRate;

  /// Set the baud rate in bits per second, or `-1` to leave unchanged.
  set baudRate(int value);

  /// Number of data bits (e.g. 7 or 8), or `-1` if unset.
  int get bits;

  /// Set the number of data bits, or `-1` to leave unchanged.
  set bits(int value);

  /// Parity setting (see [SerialPortParity]), or `-1` if unset.
  int get parity;

  /// Set parity, or `-1` to leave unchanged.
  set parity(int value);

  /// Number of stop bits, or `-1` if unset.
  int get stopBits;

  /// Set stop bits, or `-1` to leave unchanged.
  set stopBits(int value);

  /// RTS pin behaviour (see [SerialPortRts]), or `-1` if unset.
  int get rts;

  /// Set RTS behaviour, or `-1` to leave unchanged.
  set rts(int value);

  /// CTS pin behaviour (see [SerialPortCts]), or `-1` if unset.
  int get cts;

  /// Set CTS behaviour, or `-1` to leave unchanged.
  set cts(int value);

  /// DTR pin behaviour (see [SerialPortDtr]), or `-1` if unset.
  int get dtr;

  /// Set DTR behaviour, or `-1` to leave unchanged.
  set dtr(int value);

  /// DSR pin behaviour (see [SerialPortDsr]), or `-1` if unset.
  int get dsr;

  /// Set DSR behaviour, or `-1` to leave unchanged.
  set dsr(int value);

  /// XON/XOFF configuration (see [SerialPortXonXoff]), or `-1` if unset.
  int get xonXoff;

  /// Set XON/XOFF behaviour, or `-1` to leave unchanged.
  set xonXoff(int value);

  /// Set a preset flow control mode (see [SerialPortFlowControl]). This will
  /// adjust RTS/CTS/DTR/DSR and XON/XOFF settings as appropriate.
  void setFlowControl(int value);
}

// Internal signatures used to bridge config getters/setters to FFI calls.
// ignore_for_file: avoid_private_typedef_functions
typedef _SerialPortConfigGet =
    sp_return Function(
      ffi.Pointer<sp_port_config> config,
      ffi.Pointer<ffi.Int> out,
    );
typedef _SerialPortConfigSet =
    sp_return Function(ffi.Pointer<sp_port_config> config, int value);

class _SerialPortConfigImpl implements SerialPortConfig {
  final ffi.Pointer<sp_port_config> _config;

  _SerialPortConfigImpl() : _config = _init();
  _SerialPortConfigImpl.fromAddress(int address)
    : _config = ffi.Pointer<sp_port_config>.fromAddress(address);

  @override
  int get address => _config.address;

  static ffi.Pointer<sp_port_config> _init() {
    final out = ffi.calloc<ffi.Pointer<sp_port_config>>();
    Util.call(() => dylib.sp_new_config(out).value);
    final config = out[0];
    ffi.calloc.free(out);
    return config;
  }

  @override
  void dispose() => dylib.sp_free_config(_config);

  @override
  int get baudRate => _get(dylib.sp_get_config_baudrate);
  @override
  set baudRate(int value) => _set(dylib.sp_set_config_baudrate, value);

  @override
  int get bits => _get(dylib.sp_get_config_bits);
  @override
  set bits(int value) => _set(dylib.sp_set_config_bits, value);

  @override
  int get parity => _get(dylib.sp_get_config_parity);
  @override
  set parity(int value) => Util.call(
    () => dylib.sp_set_config_parity(_config, sp_parity.fromValue(value)).value,
  );

  @override
  int get stopBits => _get(dylib.sp_get_config_stopbits);
  @override
  set stopBits(int value) => _set(dylib.sp_set_config_stopbits, value);

  @override
  int get rts => _get(dylib.sp_get_config_rts);
  @override
  set rts(int value) => Util.call(
    () => dylib.sp_set_config_rts(_config, sp_rts.fromValue(value)).value,
  );

  @override
  int get cts => _get(dylib.sp_get_config_cts);
  @override
  set cts(int value) => Util.call(
    () => dylib.sp_set_config_cts(_config, sp_cts.fromValue(value)).value,
  );

  @override
  int get dtr => _get(dylib.sp_get_config_dtr);
  @override
  set dtr(int value) => Util.call(
    () => dylib.sp_set_config_dtr(_config, sp_dtr.fromValue(value)).value,
  );

  @override
  int get dsr => _get(dylib.sp_get_config_dsr);
  @override
  set dsr(int value) => Util.call(
    () => dylib.sp_set_config_dsr(_config, sp_dsr.fromValue(value)).value,
  );

  @override
  int get xonXoff => _get(dylib.sp_get_config_xon_xoff);
  @override
  set xonXoff(int value) => Util.call(
    () => dylib
        .sp_set_config_xon_xoff(_config, sp_xonxoff.fromValue(value))
        .value,
  );

  @override
  void setFlowControl(int value) => Util.call(
    () => dylib
        .sp_set_config_flowcontrol(_config, sp_flowcontrol.fromValue(value))
        .value,
  );

  int _get(_SerialPortConfigGet getFunc) {
    return Util.getInt((ptr) {
      return getFunc(_config, ptr).value;
    })!;
  }

  void _set(_SerialPortConfigSet setFunc, int value) {
    Util.call(() => setFunc(_config, value).value);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _SerialPortConfigImpl && _config == other._config;
  }

  @override
  int get hashCode => _config.hashCode;

  @override
  String toString() => 'SerialPortConfig($_config)';
}
