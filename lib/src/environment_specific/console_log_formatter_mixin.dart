import 'package:meta/meta.dart';

import '../inner_zoned_mixin.dart';
import '../log_message.dart';
import 'message_formatting_pipeline.dart';

extension on StringBuffer {
  void writeEsc(String value) {
    this
      ..write(_esc)
      ..write(value);
  }

  String completeMessage(Object message, Set<String> tags) {
    write(']');
    if (tags.isNotEmpty) {
      write(' [');
      writeAll(tags, ',');
      write(']');
    }
    write(' ');
    write(message);
    return toString();
  }
}

@internal
base mixin ConsoleLogFormatterMixin on MessageFormattingPipeline {
  @override
  String? format(LogMessage event) {
    final prefix = event.level.prefix;
    final printColors = getCurrentLogOptions()?.printColors ?? true;
    final message = event.message;
    final tags = event.tags;
    final formattedMessage = printColors
        ? event.level.when<String>(
            shout: () => _shout(message, prefix, tags),
            v: () => _v(message, prefix, tags),
            error: () => _error(message, prefix, tags),
            vv: () => _vv(message, prefix, tags),
            warning: () => _warning(message, prefix, tags),
            vvv: () => _vvv(message, prefix, tags),
            info: () => _info(message, prefix, tags),
            vvvv: () => _vvvv(message, prefix, tags),
            debug: () => _debug(message, prefix, tags),
            vvvvv: () => _vvvvv(message, prefix, tags),
            vvvvvv: () => _vvvvvv(message, prefix, tags),
          )
        : _formatPlain(message, prefix, tags);
    return super.format(event.copyWith(message: formattedMessage));
  }

  static String _formatPlain(Object message, String prefix, Set<String> tags) =>
      (StringBuffer('[')..write(prefix)).completeMessage(message, tags);

  static String _formatStyled(
    Object message,
    String prefix, {
    required Set<String> tags,
    String? font,
    String? foreground,
    String? background,
  }) {
    final buffer = StringBuffer('[');
    for (final value in [font, foreground, background]) {
      if (value != null) buffer.writeEsc(value);
    }
    buffer
      ..write(prefix)
      ..writeEsc(_reset);

    return buffer.completeMessage(message, tags);
  }

  String _shout(Object message, String prefix, Set<String> tags) =>
      _formatStyled(
        message,
        prefix,
        tags: tags,
        font: _ConsoleFont.underline.value,
        foreground: _ConsoleColor.black.foregroundValue,
        background: _ConsoleColor.white.backgroundValue,
      );

  String _v(Object message, String prefix, Set<String> tags) => _formatStyled(
        message,
        prefix,
        tags: tags,
        font: _ConsoleFont.bold.value,
        foreground: _ConsoleColor.magenta.foregroundValue,
      );

  String _error(Object message, String prefix, Set<String> tags) =>
      _formatStyled(
        message,
        prefix,
        tags: tags,
        font: _ConsoleFont.bold.value,
        foreground: _ConsoleColor.red.foregroundValue,
      );

  String _vv(Object message, String prefix, Set<String> tags) =>
      _formatPlain(message, prefix, tags);

  String _warning(Object message, String prefix, Set<String> tags) =>
      _formatStyled(
        message,
        prefix,
        tags: tags,
        foreground: _ConsoleColor.yellow.foregroundValue,
      );

  String _vvv(Object message, String prefix, Set<String> tags) =>
      _formatPlain(message, prefix, tags);

  String _info(Object message, String prefix, Set<String> tags) =>
      _formatStyled(
        message,
        prefix,
        tags: tags,
        foreground: _ConsoleColor.green.foregroundValue,
      );

  String _vvvv(Object message, String prefix, Set<String> tags) =>
      _formatPlain(message, prefix, tags);

  String _debug(Object message, String prefix, Set<String> tags) =>
      _formatStyled(
        message,
        prefix,
        tags: tags,
        foreground: _ConsoleColor.cyan.foregroundValue,
      );

  String _vvvvv(Object message, String prefix, Set<String> tags) =>
      _formatPlain(message, prefix, tags);

  String _vvvvvv(Object message, String prefix, Set<String> tags) =>
      _formatPlain(message, prefix, tags);
}

/// Ansi escape
const String _esc = '\x1B[';

/// Ansi reset
const String _reset = '0m';

/// Available console colors
enum _ConsoleColor {
  black,
  red,
  green,
  yellow,
  blue,
  magenta,
  cyan,
  white,
  byDefault,
}

extension _ConsoleColorX on _ConsoleColor {
  /// Ansi foreground colors for terminal
  String get foregroundValue {
    switch (this) {
      case _ConsoleColor.black:
        return '30m';
      case _ConsoleColor.red:
        return '31m';
      case _ConsoleColor.green:
        return '32m';
      case _ConsoleColor.yellow:
        return '33m';
      case _ConsoleColor.blue:
        return '34m';
      case _ConsoleColor.magenta:
        return '35m';
      case _ConsoleColor.cyan:
        return '36m';
      //case _ConsoleColor.white:
      // return '37m';
      case _ConsoleColor.byDefault:
      default:
        return '';
    }
  }

  /// Ansi background colors for terminal
  String get backgroundValue {
    switch (this) {
      case _ConsoleColor.black:
        return '40m';
      case _ConsoleColor.red:
        return '41m';
      case _ConsoleColor.green:
        return '42m';
      case _ConsoleColor.yellow:
        return '43m';
      case _ConsoleColor.blue:
        return '44m';
      case _ConsoleColor.magenta:
        return '45m';
      case _ConsoleColor.cyan:
        return '46m';
      case _ConsoleColor.white:
        return '47m';
      case _ConsoleColor.byDefault:
        return '';
    }
  }
}

/// Available console fonts
enum _ConsoleFont {
  bold,
  underline,
  //reversed,
  byDefault,
}

extension _ConsoleFontX on _ConsoleFont {
  /// Ansi decorations for terminal
  String get value {
    switch (this) {
      case _ConsoleFont.bold:
        return '1m';
      case _ConsoleFont.underline:
        return '4m';
      //case _ConsoleFont.reversed:
      // return '7m';
      case _ConsoleFont.byDefault:
        return '';
    }
  }
}
