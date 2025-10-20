import 'package:meta/meta.dart';

import 'inner_logger.dart';
import 'inner_zoned_mixin.dart';
import 'logger.dart';

/// Operators for logging
@internal
base mixin InnerLoggerOperatorsMixin on InnerLogger {
  @override
  void operator <(Object info) => super.i(info);

  @override
  void operator <<(Object debug) => super.d(debug);

  @override
  L operator [](String tag) {
    pushInlineTag(tag);
    return this;
  }
}
