// Derived from work in the libserialport project:
// https://sigrok.org/wiki/Libserialport
// See repository license files for redistribution terms.
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart' as ffi;
import 'package:flutter_libserialport/src/bindings.dart';
import 'package:flutter_libserialport/src/dylib.dart';
import 'package:flutter_libserialport/src/error.dart';
import 'package:flutter_libserialport/src/port.dart';
import 'package:flutter_libserialport/src/util.dart';

// Event mask used to listen for incoming data and native errors.
final int _kReadEvents =
    sp_event.SP_EVENT_RX_READY.value | sp_event.SP_EVENT_ERROR.value;

/// Asynchronous reader that exposes incoming port data as a [Stream].
///
/// Emits `Uint8List` chunks when data arrives; native errors are forwarded as
/// stream errors (e.g. [SerialPortError]). Call [close] when finished.
abstract class SerialPortReader {
  /// Create a reader for [port]. Optional [timeout] (ms) controls retry delay
  /// between attempts to open the port; defaults to 500 ms.
  factory SerialPortReader(SerialPort port, {int? timeout}) =>
      _SerialPortReaderImpl(port, timeout: timeout);

  /// Gets the port the reader operates on.
  SerialPort get port;

  /// Gets a stream of data.
  Stream<Uint8List> get stream;

  /// Closes the stream.
  void close();
}

class _SerialPortReaderArgs {
  final int address;
  final int timeout;
  final SendPort sendPort;
  _SerialPortReaderArgs({
    required this.address,
    required this.timeout,
    required this.sendPort,
  });
}

class _SerialPortReaderImpl implements SerialPortReader {
  final SerialPort _port;
  final int _timeout;
  Isolate? _isolate;
  ReceivePort? _receiver;
  SendPort? _sender;

  StreamController<Uint8List>? __controller;

  _SerialPortReaderImpl(SerialPort port, {int? timeout})
    : _port = port,
      _timeout = timeout ?? 500;

  @override
  SerialPort get port => _port;

  @override
  Stream<Uint8List> get stream => _controller.stream;

  @override
  void close() {
    __controller?.close();
    __controller = null;
  }

  StreamController<Uint8List> get _controller {
    return __controller ??= StreamController<Uint8List>(
      onListen: _startRead,
      onCancel: _cancelRead,
      onPause: _cancelRead,
      onResume: _startRead,
    );
  }

  void _startRead() {
    _receiver = ReceivePort();
    _receiver!.listen((data) {
      if (data is SerialPortError) {
        _controller.addError(data);
      } else if (data is Uint8List) {
        _controller.add(data);
      } else if (data is SendPort) {
        _sender = data;
      }
    });
    final args = _SerialPortReaderArgs(
      address: _port.address,
      timeout: _timeout,
      sendPort: _receiver!.sendPort,
    );
    Isolate.spawn(
      _waitRead,
      args,
      debugName: toString(),
    ).then((value) => _isolate = value);
  }

  void _cancelRead() {
    if (null != _sender) {
      _sender!.send(true);
      _sender = null;
    }
    _receiver?.close();
    _receiver = null;
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
  }

  static void _waitRead(_SerialPortReaderArgs args) {
    ReceivePort _mainToIsolateStream = ReceivePort();
    args.sendPort.send(_mainToIsolateStream.sendPort);

    bool _close = false;
    _mainToIsolateStream.listen((message) {
      if (message is bool) {
        _close = message;
      }
    });

    final port = ffi.Pointer<sp_port>.fromAddress(args.address);
    final events = _createEvents(port, _kReadEvents);
    var bytes = 0;
    while (bytes >= 0 && false == _close) {
      bytes = _waitEvents(port, events, args.timeout);
      if (bytes > 0) {
        final data = Util.read(bytes, (ffi.Pointer<ffi.Uint8> ptr) {
          return rawNonblockingRead(port, ptr.cast(), bytes);
        });
        args.sendPort.send(data);
      } else if (bytes < 0) {
        args.sendPort.send(SerialPort.lastError);
      }
    }
    _releaseEvents(events);
  }

  static ffi.Pointer<ffi.Pointer<sp_event_set>> _createEvents(
    ffi.Pointer<sp_port> port,
    int mask,
  ) {
    final events = ffi.calloc<ffi.Pointer<sp_event_set>>();
    dylib.sp_new_event_set(events);
    rawAddPortEvents(events.value, port, mask);
    return events;
  }

  static int _waitEvents(
    ffi.Pointer<sp_port> port,
    ffi.Pointer<ffi.Pointer<sp_event_set>> events,
    int timeout,
  ) {
    dylib.sp_wait(events.value, timeout);
    return rawInputWaiting(port);
  }

  static void _releaseEvents(ffi.Pointer<ffi.Pointer<sp_event_set>> events) {
    dylib.sp_free_event_set(events.value);
  }
}
