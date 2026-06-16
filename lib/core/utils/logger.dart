import 'package:logger/logger.dart';

/// Global logger instance.
final Logger log = Logger(
  level: Level.info,
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 8,
    colors: true,
    printEmojis: false,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
);
