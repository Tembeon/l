import 'dart:async';
import 'dart:collection';

import 'package:meta/meta.dart';

import 'inner_logger.dart';
import 'log_level.dart';
import 'log_message.dart';
import 'log_options.dart';

/// Zone key storing the current [LogOptions] snapshot.
const Symbol _kOptionsKey = #l.logOptions;

/// Zone key holding the accumulated tag set for the current capture scope.
const Symbol _kTagsKey = #l.logTags;

/// Zone key for the mutable inline tag queue consumed on the next log call.
const Symbol _kInlineTagsKey = #l.inlineTags;

final _InlineTagState _rootInlineTagState = _InlineTagState._root();

/// Receive [LogOptions] from [Zone]
@internal
LogOptions? getCurrentLogOptions() => switch (Zone.current[_kOptionsKey]) {
      final LogOptions options => options,
      _ => null,
    };

/// Receive current log [Set] of tags from [Zone]
@internal
Set<String> getCurrentLogTags() => switch (Zone.current[_kTagsKey]) {
      final Set<String> tags => tags,
      final Iterable<String> tags => normalizeLogTags(tags),
      _ => const <String>{},
    };

_InlineTagState _getInlineTagState() => switch (Zone.current[_kInlineTagsKey]) {
      final _InlineTagState state => state,
      _ => _rootInlineTagState,
    };

@internal
void pushInlineTag(String tag) {
  if (tag.isEmpty) return;
  _getInlineTagState().push(tag);
}

@internal
Set<String> combineLogTags([Iterable<String>? additional]) {
  final current = getCurrentLogTags();
  final inline = normalizeLogTags(_getInlineTagState().consume());
  final normalizedAdditional =
      additional == null ? const <String>{} : normalizeLogTags(additional);

  if (current.isEmpty && inline.isEmpty && normalizedAdditional.isEmpty) {
    return const <String>{};
  }
  final merged = LinkedHashSet<String>.of(current)
    ..addAll(inline)
    ..addAll(normalizedAdditional);
  return Set<String>.unmodifiable(merged);
}

@internal
Set<String> normalizeLogTags(Iterable<String> tags) {
  if (tags.isEmpty) return const <String>{};
  final normalized = LinkedHashSet<String>.of(tags.whereType<String>());
  return normalized.isEmpty
      ? const <String>{}
      : Set<String>.unmodifiable(normalized);
}

Map<Symbol, Object?>? _buildZoneValues(LogOptions? logOptions) {
  final values = <Symbol, Object?>{};
  if (logOptions != null) values[_kOptionsKey] = logOptions;
  final normalizedTags = combineLogTags(logOptions?.tags);
  if (normalizedTags.isNotEmpty) {
    values[_kTagsKey] = normalizedTags;
  }
  values[_kInlineTagsKey] = _InlineTagState.child();
  return values.isEmpty ? null : values;
}

ZoneSpecification _buildZoneSpecification(
  InnerLogger logger,
  LogOptions? logOptions,
) =>
    ZoneSpecification(
      print: (self, parent, zone, line) {
        if (logOptions?.handlePrint ?? true) {
          self.run<void>(
            () => logger.log(
              LogMessage.create(
                line,
                const LogLevel.info(),
                tags: combineLogTags(),
              ),
            ),
          );
        } else {
          parent.print(zone, line);
        }
      },
    );

/// Internal mixin for [InnerLogger] to run in [Zone]
@internal
base mixin InnerZonedMixin on InnerLogger {
  @override
  R capture<R extends Object?>(R Function() body, [LogOptions? logOptions]) =>
      runZoned<R>(
        body,
        zoneValues: _buildZoneValues(logOptions),
        zoneSpecification: _buildZoneSpecification(this, logOptions),
      );
}

final class _InlineTagState {
  _InlineTagState._();

  factory _InlineTagState._root() => _InlineTagState._();

  factory _InlineTagState.child() => _InlineTagState._();
  final List<String> _pending = <String>[];

  void push(String tag) {
    _pending.add(tag);
  }

  Iterable<String> consume() {
    if (_pending.isEmpty) return const Iterable<String>.empty();
    final copy = List<String>.unmodifiable(_pending);
    _pending.clear();
    return copy;
  }
}
