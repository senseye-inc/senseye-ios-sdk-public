# senseye-ios-sdk

A description of this package.

# Unit Tests

To run the tests, ensure you have an iOS Simulator selected as your build destination, tests won't compile on macOS. To select a build destination, type `control + shift + 0` and select a device. Run all tests with `command + U` or press `command 6` to open the test naviagtor and select which tests you would like to run.

# Logging

The `Log` enum found under the SDK is a convenience logger. To emit a log message, use appropriate method of `Log`.

Before emitting a log, 1) enable logging and 2) set a log level within scope. Log categories are: debug, info, warn, and error.

2) Log levels control which category of logs are emitted. There are two methods to define log levels: The `dynamicLogLevel` variable is changeable at runtime and set inline with code. The level definable at build time is in the `GCC_PREPROCESSOR_DEFINITIONS` build setting. There you can add a `DD_LOG_LEVEL` defined to the desired log level. Both levels have a default of `DDLogLevelAll`.


