/// Flutter/Dart bindings for libserialport.
///
/// Exports the high-level serial port API, configuration types and constants.
library flutter_libserialport;

export 'src/config.dart' show SerialPortConfig;
export 'src/enums.dart';
export 'src/error.dart';
export 'src/port.dart' show SerialPort;
export 'src/reader.dart' show SerialPortReader;
