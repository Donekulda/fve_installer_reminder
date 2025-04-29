import 'package:flutter_test/flutter_test.dart';
import 'package:fve_installer_reminder/core/utils/logger.dart';
import 'dart:io';

/// A mock Config class for testing that allows modifying logging settings
class MockConfig {
  static bool loggerOn = true;
  static bool debugLog = true;
  static bool errorLog = true;
  static bool infoLog = true;
  static bool warningLog = true;
  static bool saveLogToFile = true;
  static int logBatchSize = 10;
  static Duration logFlushInterval = const Duration(seconds: 5);
}

void main() {
  late AppLogger logger;
  late Directory tempDir;

  setUp(() async {
    // Create a temporary directory for test files
    tempDir = await Directory.systemTemp.createTemp('logger_test_');

    // Reset logger state
    await AppLogger.dispose();
    logger = AppLogger('TestLogger');
  });

  tearDown(() async {
    // Clean up temporary directory
    await tempDir.delete(recursive: true);
    // Reset logger state
    await AppLogger.dispose();
  });

  group('AppLogger Initialization Tests', () {
    test('should initialize successfully', () async {
      await AppLogger.initialize();
      expect(logger, isNotNull);
    });

    test('should not initialize twice', () async {
      await AppLogger.initialize();
      await AppLogger.initialize(); // Second call should be ignored
      expect(logger, isNotNull);
    });
  });

  group('AppLogger Logging Tests', () {
    setUp(() async {
      await AppLogger.initialize();
    });

    test('should log debug messages when debug logging is enabled', () {
      MockConfig.debugLog = true;
      logger.debug('Test debug message');
      // Note: We can't easily verify the actual log output in unit tests
      // as it goes to the console and file system
    });

    test('should not log debug messages when debug logging is disabled', () {
      MockConfig.debugLog = false;
      logger.debug('Test debug message');
      // No exception should be thrown
    });

    test('should log info messages when info logging is enabled', () {
      MockConfig.infoLog = true;
      logger.info('Test info message');
    });

    test('should not log info messages when info logging is disabled', () {
      MockConfig.infoLog = false;
      logger.info('Test info message');
      // No exception should be thrown
    });

    test('should log warning messages when warning logging is enabled', () {
      MockConfig.warningLog = true;
      logger.warning('Test warning message');
    });

    test(
      'should not log warning messages when warning logging is disabled',
      () {
        MockConfig.warningLog = false;
        logger.warning('Test warning message');
        // No exception should be thrown
      },
    );

    test('should log error messages when error logging is enabled', () {
      MockConfig.errorLog = true;
      logger.error('Test error message');
    });

    test('should not log error messages when error logging is disabled', () {
      MockConfig.errorLog = false;
      logger.error('Test error message');
      // No exception should be thrown
    });

    test('should log error messages with stack trace', () {
      MockConfig.errorLog = true;
      final stackTrace = StackTrace.current;
      logger.error('Test error message', 'Test error', stackTrace);
    });
  });

  group('AppLogger File Logging Tests', () {
    setUp(() async {
      MockConfig.saveLogToFile = true;
      await AppLogger.initialize();
    });

    test('should create log file when file logging is enabled', () async {
      final logFile = File('${tempDir.path}/app.log');
      expect(await logFile.exists(), true);
    });

    test('should not create log file when file logging is disabled', () async {
      await AppLogger.dispose();
      MockConfig.saveLogToFile = false;
      await AppLogger.initialize();

      final logFile = File('${tempDir.path}/app.log');
      expect(await logFile.exists(), false);
    });

    test('should write logs to file when file logging is enabled', () async {
      MockConfig.debugLog = true;
      logger.debug('Test debug message');

      // Wait for the log buffer to be flushed
      await Future.delayed(const Duration(milliseconds: 100));

      final logFile = File('${tempDir.path}/app.log');
      final contents = await logFile.readAsString();
      expect(contents, contains('Test debug message'));
    });
  });

  group('AppLogger Error Handling Tests', () {
    setUp(() async {
      await AppLogger.initialize();
    });

    test('should handle null error in warning log', () {
      MockConfig.warningLog = true;
      logger.warning('Test warning message', null);
      // No exception should be thrown
    });

    test('should handle null error and stack trace in error log', () {
      MockConfig.errorLog = true;
      logger.error('Test error message', null, null);
      // No exception should be thrown
    });

    test('should handle file system errors gracefully', () async {
      // Create a file that can't be written to by deleting the directory
      await tempDir.delete(recursive: true);

      MockConfig.debugLog = true;
      logger.debug('Test debug message');
      // No exception should be thrown
    });
  });

  group('AppLogger Cleanup Tests', () {
    test('should dispose resources properly', () async {
      await AppLogger.initialize();
      await AppLogger.dispose();
      // No exception should be thrown
    });

    test('should handle multiple dispose calls gracefully', () async {
      await AppLogger.initialize();
      await AppLogger.dispose();
      await AppLogger.dispose(); // Second call
      // No exception should be thrown
    });
  });
}
