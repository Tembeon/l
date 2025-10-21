library;

import 'dart:async';

import 'l.dart' show L, l;
import 'src/inner_zoned_mixin.dart'
    show buildZoneValues, getCurrentLogOptions, pushInlineTag;
import 'src/log_message.dart' show LogMessage;
import 'src/log_options.dart';
import 'src/logger.dart' show LogMessageContext;

final Expando<Zone> _boundZone = Expando<Zone>('l.boundZone');
final Expando<String> _boundTag = Expando<String>('l.boundTag');

LogOptions? _resolveOptions(Set<String> tags) {
  final current = getCurrentLogOptions();
  final merged = <String>{...?current?.tags, ...tags};
  if (current == null) {
    if (merged.isEmpty) return null;
    return LogOptions(tags: Set<String>.unmodifiable(merged));
  }
  return LogOptions(
    handlePrint: current.handlePrint,
    printColors: current.printColors,
    outputInRelease: current.outputInRelease,
    output: current.output,
    messageFormatting: current.messageFormatting,
    overrideOutput: current.overrideOutput,
    tags: Set<String>.unmodifiable(merged),
  );
}

Zone _forkBoundZone(Set<String> tags) {
  final options = _resolveOptions(tags);
  return Zone.current.fork(zoneValues: buildZoneValues(options));
}

/// Bind [obj] to the current logging zone with optional [tags] and
/// a custom inline [tag].
///
/// The object retains a weak reference to the derived zone, so GC is not
/// prevented.
T bindLog<T extends Object>(
  T obj, {
  Set<String> tags = const <String>{},
  String? tag,
}) {
  final zone = _forkBoundZone(tags);
  _boundZone[obj] = zone;
  if (tag != null) _boundTag[obj] = tag;
  return obj;
}

/// Remove previously attached logging metadata from [obj].
void unbindLog(Object obj) {
  _boundZone[obj] = null;
  _boundTag[obj] = null;
}

class _ZLogger extends StreamView<LogMessage> implements L {
  _ZLogger(this._owner) : super(l);

  final Object _owner;

  Zone? get _zone => _boundZone[_owner];
  String get _tag => _boundTag[_owner] ?? _owner.runtimeType.toString();

  T _run<T>(T Function(L logger) operation) {
    final zone = _zone;
    if (zone == null) return operation(l[_tag]);
    return zone.run(() => operation(l[_tag]));
  }

  @override
  void s(Object message, [LogMessageContext? context]) =>
      _run((logger) => logger.s(message, context));

  @override
  void v(Object message, [LogMessageContext? context]) =>
      _run((logger) => logger.v(message, context));

  @override
  void v1(Object message, [LogMessageContext? context]) =>
      _run((logger) => logger.v1(message, context));

  @override
  void vv(Object message, [LogMessageContext? context]) =>
      _run((logger) => logger.vv(message, context));

  @override
  void v2(Object message, [LogMessageContext? context]) =>
      _run((logger) => logger.v2(message, context));

  @override
  void vvv(Object message, [LogMessageContext? context]) =>
      _run((logger) => logger.vvv(message, context));

  @override
  void v3(Object message, [LogMessageContext? context]) =>
      _run((logger) => logger.v3(message, context));

  @override
  void vvvv(Object message, [LogMessageContext? context]) =>
      _run((logger) => logger.vvvv(message, context));

  @override
  void v4(Object message, [LogMessageContext? context]) =>
      _run((logger) => logger.v4(message, context));

  @override
  void vvvvv(Object message, [LogMessageContext? context]) =>
      _run((logger) => logger.vvvvv(message, context));

  @override
  void v5(Object message, [LogMessageContext? context]) =>
      _run((logger) => logger.v5(message, context));

  @override
  void vvvvvv(Object message, [LogMessageContext? context]) =>
      _run((logger) => logger.vvvvvv(message, context));

  @override
  void v6(Object message, [LogMessageContext? context]) =>
      _run((logger) => logger.v6(message, context));

  @override
  void i(Object message, [LogMessageContext? context]) =>
      _run((logger) => logger.i(message, context));

  @override
  void w(
    Object message, [
    StackTrace? stackTrace,
    LogMessageContext? context,
  ]) =>
      _run((logger) => logger.w(message, stackTrace, context));

  @override
  void e(
    Object message, [
    StackTrace? stackTrace,
    LogMessageContext? context,
  ]) =>
      _run((logger) => logger.e(message, stackTrace, context));

  @override
  void d(Object message, [LogMessageContext? context]) =>
      _run((logger) => logger.d(message, context));

  @override
  void log(LogMessage event) => _run((logger) => logger.log(event));

  @override
  R capture<R extends Object?>(R Function() body, [LogOptions? logOptions]) =>
      _run((logger) => logger.capture(body, logOptions));

  @override
  void operator <(Object info) => _run((logger) => logger < info);

  @override
  void operator <<(Object debug) => _run((logger) => logger << debug);

  @override
  L operator [](String tag) {
    final zone = _zone;
    if (zone == null) {
      pushInlineTag(tag);
    } else {
      zone.run(() => pushInlineTag(tag));
    }
    return this;
  }
}

/// Extension that exposes the zone-aware logger bound to an object.
extension LogBoundX on Object {
  /// Logger that executes within the object's bound logging zone.
  L get zl => _ZLogger(this);
}
