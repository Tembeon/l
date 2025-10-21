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
      final Iterable<String> tags => _normalizeLogTags(tags),
      _ => const <String>{},
    };

@internal
Set<String> combineLogTags([Iterable<String>? additional]) {
  final current = getCurrentLogTags();
  final normalizedAdditional =
      additional == null ? const <String>{} : _normalizeLogTags(additional);
  if (current.isEmpty && normalizedAdditional.isEmpty) {
    return current;
  }
  if (current.isEmpty) return normalizedAdditional;
  if (normalizedAdditional.isEmpty) return current;
  final merged = LinkedHashSet<String>.of(current)
    ..addAll(normalizedAdditional);
  return Set<String>.unmodifiable(merged);
}

Set<String> _normalizeLogTags(Iterable<String> tags) {
  if (tags.isEmpty) return const <String>{};
  final normalized = LinkedHashSet<String>.of(
    tags.whereType<String>().where((tag) => tag.isNotEmpty),
  );
  return normalized.isEmpty
      ? const <String>{}
      : Set<String>.unmodifiable(normalized);
}

@internal
Map<Symbol, Object?> buildZoneValues(
  LogOptions? logOptions, [
  Iterable<String>? tags,
]) {
  final values = <Symbol, Object?>{};
  if (logOptions != null) values[_kOptionsKey] = logOptions;
  final normalizedTags = tags == null ? null : _normalizeLogTags(tags);
  if (normalizedTags != null && normalizedTags.isNotEmpty) {
    values[_kTagsKey] = normalizedTags;
  }
  return values;
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
        zoneValues: buildZoneValues(logOptions),
        zoneSpecification: _buildZoneSpecification(this, logOptions),
      );
}
