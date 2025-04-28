import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import '../config/config.dart';

class AppLogger {
  final String source;
  late final Logger _logger;
  static bool _isInitialized = false;
  static File? _logFile;
  static const String _logFileName = 'app.log';
  static final _logQueue = StreamController<String>.broadcast();
  static StreamSubscription? _logSubscription;
  static bool _isWriting = false;
  static final List<String> _logBuffer = [];
  static Timer? _flushTimer;

  AppLogger(this.source) {
    _logger = Logger(source);
  }

  static Future<void> initialize() async {
    if (!_isInitialized) {
      // Set the root logger level based on Config.debugLog
      Logger.root.level = Config.debugLog ? Level.ALL : Level.OFF;

      // Initialize log file if file logging is enabled
      if (Config.saveLogToFile) {
        try {
          final directory = await getApplicationDocumentsDirectory();
          _logFile = File('${directory.path}/$_logFileName');
          // Create the file if it doesn't exist
          if (!await _logFile!.exists()) {
            await _logFile!.create();
          }

          // Set up the log queue processor
          _logSubscription = _logQueue.stream.listen((logMessage) {
            _logBuffer.add(logMessage);

            // If buffer is full or timer is not running, flush the buffer
            if (_logBuffer.length >= Config.logBatchSize ||
                _flushTimer == null) {
              _flushLogBuffer();
            }
          });

          // Set up periodic flush timer
          _flushTimer = Timer.periodic(Config.logFlushInterval, (_) {
            if (_logBuffer.isNotEmpty) {
              _flushLogBuffer();
            }
          });
        } catch (e) {
          debugPrint('Failed to initialize log file: $e');
        }
      }

      // Configure the root logger to use a custom formatter
      Logger.root.onRecord.listen((record) {
        // Check if logging is enabled globally
        if (!Config.loggerOn) return;

        // Check specific log level flags
        bool shouldLog = false;
        switch (record.level) {
          case Level.FINE:
          case Level.FINER:
          case Level.FINEST:
            shouldLog = Config.debugLog;
            break;
          case Level.INFO:
            shouldLog = Config.infoLog;
            break;
          case Level.WARNING:
            shouldLog = Config.warningLog;
            break;
          case Level.SEVERE:
          case Level.SHOUT:
            shouldLog = Config.errorLog;
            break;
          default:
            shouldLog = false;
        }

        if (!shouldLog) return;

        final timestamp = record.time.toString().split('.').first;
        final level = record.level.name;
        final loggerName = record.loggerName;
        final message = record.message;

        // Format the log message
        final logMessage = '[$timestamp] [$level] [$loggerName] - $message';

        // Print to console
        debugPrint(logMessage);

        // Add to log queue if file logging is enabled
        if (Config.saveLogToFile && _logFile != null) {
          _logQueue.add(logMessage);
        }

        if (record.error != null) {
          final errorMessage = 'Error: ${record.error}';
          debugPrint(errorMessage);
          if (Config.saveLogToFile && _logFile != null) {
            _logQueue.add(errorMessage);
          }
        }

        if (record.stackTrace != null) {
          final stackTraceMessage = 'Stack trace: ${record.stackTrace}';
          debugPrint(stackTraceMessage);
          if (Config.saveLogToFile && _logFile != null) {
            _logQueue.add(stackTraceMessage);
          }
        }
      });

      _isInitialized = true;
    }
  }

  static Future<void> _flushLogBuffer() async {
    if (_isWriting || _logBuffer.isEmpty) return;

    _isWriting = true;
    try {
      final logsToWrite = '${_logBuffer.join('\n')}\n';
      await _logFile!.writeAsString(logsToWrite, mode: FileMode.append);
      _logBuffer.clear();
    } catch (e) {
      debugPrint('Failed to write to log file: $e');
    } finally {
      _isWriting = false;
    }
  }

  void _log(
    String level,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    // Check if logging is enabled globally
    if (!Config.loggerOn) return;

    // Check specific log level flags
    bool shouldLog = false;
    switch (level) {
      case 'DEBUG':
        shouldLog = Config.debugLog;
        break;
      case 'INFO':
        shouldLog = Config.infoLog;
        break;
      case 'WARNING':
        shouldLog = Config.warningLog;
        break;
      case 'ERROR':
        shouldLog = Config.errorLog;
        break;
    }

    if (!shouldLog) return;

    if (!_isInitialized) {
      // Fallback to debugPrint when logger is not initialized
      final timestamp = DateTime.now().toString().split('.').first;
      final logMessage = '[$timestamp] [$level] [$source] - $message';

      debugPrint(logMessage);

      if (Config.saveLogToFile && _logFile != null) {
        _logQueue.add(logMessage);
      }

      if (error != null) {
        final errorMessage = 'Error: $error';
        debugPrint(errorMessage);
        if (Config.saveLogToFile && _logFile != null) {
          _logQueue.add(errorMessage);
        }
      }

      if (stackTrace != null) {
        final stackTraceMessage = 'Stack trace: $stackTrace';
        debugPrint(stackTraceMessage);
        if (Config.saveLogToFile && _logFile != null) {
          _logQueue.add(stackTraceMessage);
        }
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
        _logger.warning(message, error, stackTrace);
        break;
      case 'ERROR':
        _logger.severe(message, error, stackTrace);
        break;
    }
  }

  void debug(String message) {
    _log('DEBUG', message);
  }

  void info(String message) {
    _log('INFO', message);
  }

  void warning(String message, [Object? error]) {
    _log('WARNING', message, error);
  }

  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log('ERROR', message, error, stackTrace);
  }

  static Future<void> dispose() async {
    // Flush any remaining logs
    if (_logBuffer.isNotEmpty) {
      await _flushLogBuffer();
    }

    // Clean up resources
    _flushTimer?.cancel();
    await _logSubscription?.cancel();
    await _logQueue.close();
  }
}
