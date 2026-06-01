// Derived from work in the libserialport project:
// https://sigrok.org/wiki/Libserialport
// See repository license files for redistribution terms.
// SPDX-License-Identifier: MIT

/// Buffer selection flags used by flush operations.
abstract class SerialPortBuffer {
  const SerialPortBuffer._();

  /// Input buffer flag.
  static const int input = 1;

  /// Output buffer flag.
  static const int output = 2;

  /// Both buffers flag.
  static const int both = 3;
}

/// CTS pin behaviour constants.
abstract class SerialPortCts {
  const SerialPortCts._();

  /// Value indicating the setting should be left unchanged.
  static const int invalid = -1;

  /// CTS ignored.
  static const int ignore = 0;

  /// CTS used for hardware flow control.
  static const int flowControl = 1;
}

/// DSR pin behaviour constants.
abstract class SerialPortDsr {
  const SerialPortDsr._();

  /// Value indicating the setting should be left unchanged.
  static const int invalid = -1;

  /// DSR ignored.
  static const int ignore = 0;

  /// DSR used for hardware flow control.
  static const int flowControl = 1;
}

/// DTR pin behaviour constants.
abstract class SerialPortDtr {
  const SerialPortDtr._();

  /// Value indicating the setting should be left unchanged.
  static const int invalid = -1;

  /// DTR set to off.
  static const int off = 0;

  /// DTR set to on.
  static const int on = 1;

  /// DTR used for hardware flow control.
  static const int flowControl = 2;
}

/// Event bitmask values used by the event APIs.
abstract class SerialPortEvent {
  const SerialPortEvent._();

  /// Data received and ready to read.
  static const int rxReady = 1;

  /// Ready to transmit new data.
  static const int txReady = 2;

  /// Error event.
  static const int error = 4;
}

/// Common flow control presets.
abstract class SerialPortFlowControl {
  const SerialPortFlowControl._();

  /// No flow control.
  static const int none = 0;

  /// Software (XON/XOFF) flow control.
  static const int xonXoff = 1;

  /// Hardware RTS/CTS flow control.
  static const int rtsCts = 2;

  /// Hardware DTR/DSR flow control.
  static const int dtrDsr = 3;
}

/// Access modes for opening a port.
abstract class SerialPortMode {
  const SerialPortMode._();

  /// Open for read-only access.
  static const int read = 1;

  /// Open for write-only access.
  static const int write = 2;

  /// Open for both read and write access.
  static const int readWrite = 3;
}

/// Parity mode values.
abstract class SerialPortParity {
  const SerialPortParity._();

  /// Value indicating the setting should be left unchanged.
  static const int invalid = -1;

  /// No parity.
  static const int none = 0;

  /// Odd parity.
  static const int odd = 1;

  /// Even parity.
  static const int even = 2;

  /// Mark parity.
  static const int mark = 3;

  /// Space parity.
  static const int space = 4;
}

/// RTS pin behaviour constants.
abstract class SerialPortRts {
  const SerialPortRts._();

  /// Value indicating the setting should be left unchanged.
  static const int invalid = -1;

  /// RTS off.
  static const int off = 0;

  /// RTS on.
  static const int on = 1;

  /// RTS used for hardware flow control.
  static const int flowControl = 2;
}

/// Input signal bitmask values.
abstract class SerialPortSignal {
  const SerialPortSignal._();

  /// Clear to send (CTS).
  static const int cts = 1;

  /// Data set ready (DSR).
  static const int dsr = 2;

  /// Data carrier detect (DCD).
  static const int dcd = 4;

  /// Ring indicator (RI).
  static const int ri = 8;
}

/// Transport type identifiers.
abstract class SerialPortTransport {
  const SerialPortTransport._();

  /// Native platform serial port.
  static const int native = 0;

  /// USB serial adapter.
  static const int usb = 1;

  /// Bluetooth serial adapter.
  static const int bluetooth = 2;
}

/// XON/XOFF flow-control modes.
abstract class SerialPortXonXoff {
  const SerialPortXonXoff._();

  /// Value indicating the setting should be left unchanged.
  static const int invalid = -1;

  /// Disabled.
  static const int disabled = 0;

  /// Enabled for input only.
  static const int input = 1;

  /// Enabled for output only.
  static const int output = 2;

  /// Enabled for both input and output.
  static const int inOut = 3;
}
