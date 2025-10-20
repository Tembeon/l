import 'package:meta/meta.dart';

import '../log_message.dart';

@internal
abstract base class MessageFormattingPipeline {
  @internal
  String? format(LogMessage event) {
    final messageString = event.message.toString();
    if (event is LogMessageError) {
      final stackTrace = event.stackTrace;
      if (!identical(stackTrace, StackTrace.empty)) {
        final buffer = StringBuffer(messageString);
        // if user give input which ends with new line, then no new lines required
        if (messageString.isNotEmpty && !messageString.endsWith('\n')) {
          buffer.writeln();
        }
        buffer.write(stackTrace);
        return buffer.toString();
      }
    }
    return messageString;
  }
}
