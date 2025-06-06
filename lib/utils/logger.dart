import 'package:logging/logging.dart';

/// A utility class that provides standardized logging functionality
/// across the Schengen Tracker app
class AppLogger {
  /// Initialize the logger with the appropriate configuration
  static void init() {
    Logger.root.level = Level.INFO;
    Logger.root.onRecord.listen((record) {
      final message = record.message;
      final loggerName = record.loggerName;
      final level = record.level.name;
      final time = record.time.toIso8601String();
      final error = record.error != null ? ' ERROR: ${record.error}' : '';
      final stackTrace = record.stackTrace != null
          ? '\n${record.stackTrace}'
          : '';

      // We use print here since this is the base logger implementation
      // ignore: avoid_print
      print('$time [$level] $loggerName: $message$error$stackTrace');
    });
  }

  /// Get a logger instance for a specific class or component
  static Logger getLogger(String name) {
    return Logger(name);
  }
}
