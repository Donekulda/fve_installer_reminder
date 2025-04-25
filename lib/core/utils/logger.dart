import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart';
import '../config/config.dart';

class AppLogger {
  static final Logger _logger = Logger('AppLogger');
  static bool _isInitialized = false;

  static void initialize() {
    if (!_isInitialized) {
      Logger.root.level = Config.debugLog ? Level.ALL : Level.OFF;

      // Configure the root logger to use a custom formatter
      Logger.root.onRecord.listen((record) {
        final timestamp = record.time.toString().split('.').first;
        final level = record.level.name;
        final loggerName = record.loggerName;
        final message = record.message;

        // Use the logging package's built-in output handling
        debugPrint('[$timestamp] [$level] [$loggerName] - $message');

        if (record.error != null) {
          debugPrint('Error: ${record.error}');
        }
        if (record.stackTrace != null) {
          debugPrint('Stack trace: ${record.stackTrace}');
        }
      });

      _isInitialized = true;
    }
  }

  static void _log(
    String level,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    if (!_isInitialized) {
      // Fallback to debugPrint when logger is not initialized
      final timestamp = DateTime.now().toString().split('.').first;
      debugPrint('[$timestamp] [$level] [AppLogger] - $message');
      if (error != null) {
        debugPrint('Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
      return;
    }

    switch (level) {
      case 'DEBUG':
        _logger.fine(message);
        break;
      case 'INFO':
        _logger.info(message);
        break;
      case 'WARNING':
        _logger.warning(message);
        break;
      case 'ERROR':
        _logger.severe(message, error, stackTrace);
        break;
    }
  }

  static void debug(String message) {
    _log('DEBUG', message);
  }

  static void info(String message) {
    _log('INFO', message);
  }

  static void warning(String message) {
    _log('WARNING', message);
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log('ERROR', message, error, stackTrace);
  }
}
