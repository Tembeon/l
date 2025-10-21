// ignore_for_file: public_member_api_docs, avoid_print
// ignore_for_file: use_named_constants, do_not_use_environment

library;

import 'dart:async';

import 'package:l/l.dart';
import 'package:l/log_binding.dart';

import 'another.dart';

/// Whether to override the output of the logger.
const bool overrideOutput = true;

/// ```bash
/// dart compile exe -o example/out/main.exe example/main.dart
/// dart compile js -O3 --generate-code-with-compile-time-errors -o example/out/main.dart.js  example/main.dart
/// ```
void main([List<String>? args]) => runZonedGuarded(
      () => l.capture<void>(
        () => runZonedGuarded<void>(
          () {
            l
              ..v('Regular 1')
              ..e('Error')
              ..w('Warning')
              ..i('Info')
              ..d('Debug')
              ..s('Shout')
              ..vv('Regular 2')
              ..v6('Regular 6');
            print('Hello from original print!');
            l
              ..v('Running')
              ..capture(
                () async {
                  print('Original print');
                  l
                    ..v('Scoped verbose')
                    ..vv('usual 2');

                  bindLog(
                    const SomeClass(),
                    tag: 'SomeClassInstance',
                  )
                    ..foo()
                    ..bar();

                  bindLog(const SomeClass(), tag: 'Test').bar();
                  const SomeClass().bar();
                },
                const LogOptions(
                  handlePrint: false,
                  // messageFormatting: _customFormatter,
                  // overrideOutput: _customPrinter,
                ),
              );

            throw Exception('Exception');
          },
          l.e, // Log uncaught errors received by the zone.
        ),
        // Logger options passed to the underlying logger zone.
        const LogOptions(
          handlePrint: true,
          // Whether to handle `print()` calls.
          // messageFormatting: _customFormatter,
          // overrideOutput: overrideOutput ? _customPrinter : null,
          outputInRelease: true,
          // Whether to output in release mode.
          printColors: true,
          // Whether to print colors in the console.
          output: LogOutput.platform, // Whether to use `print()` for output.
        ),
      ),
      (error, stack) {},
    );
