//
//  Logger.swift
//  
//
//  Created by Bobby Srisan on 5/11/22.
//
import Firebase
import Foundation
import CocoaLumberjackSwift

enum Log {
    /**
     Log levels are categories to select what is being logged based on the build configuration.
    */
    enum LogLevel {
        case debug
        case info
        case warn
        case error
        case fatal

        fileprivate var prefix: String {
            switch self {
            case .debug:   return "DEBUG 👾"
            case .info:    return "INFO ℹ️"
            case .warn: return "WARN ⚠️"
            case .error:   return "ERROR ❌"
            case .fatal:   return "FATAL ERROR 💀"
            }
        }
    }

    fileprivate struct Context: CustomStringConvertible {
        let file: String
        let function: String
        let line: Int
        var description: String {
            return "\((file as NSString).lastPathComponent):\(line) \(function)"
        }
    }

    static func enable() {
        // TODO: Check that log isn't already added
        DDLog.add(DDOSLogger.sharedInstance)
    }
    
    static func disable() {
        DDLog.removeAllLoggers()
    }

    /**
     Log level debug: Use for emitting detailed context messages during development and writing to file. Do not allow debug messages in production.
    */
    static func debug(_ str: String, shouldLogContext: Bool = true, file: String = #file, function: String = #function, line: Int = #line) {
        let context = Context(file: file, function: function, line: line)
        Log.handleLog(level: .debug, str: str, shouldLogContext: shouldLogContext, context: context) {
            DDLogDebug($0)
        }
    }

    /**
     Log level info: Use for system monitoring.
    */
    static func info(_ str: String, shouldLogContext: Bool = false, file: String = #file, function: String = #function, line: Int = #line) {
        let context = Context(file: file, function: function, line: line)
        Log.handleLog(level: .info, str: str, shouldLogContext: shouldLogContext, context: context) {
            DDLogInfo($0)
        }
    }

    /**
     Log level warn: Use for recoverable application operation errors, deprecation notices, and cases that may present runtime issues.
    */
    static func warn(_ str: String, shouldLogContext: Bool = false, file: String = #file, function: String = #function, line: Int = #line) {
        let context = Context(file: file, function: function, line: line)
        Log.handleLog(level: .warn, str: str, shouldLogContext: shouldLogContext, context: context) {
            DDLogWarn($0)
        }
    }

    /**
     Log level error: Use for fatal operation errors.
    */
    static func error(_ str: String, shouldLogContext: Bool = false, file: String = #file, function: String = #function, line: Int = #line) {
        let context = Context(file: file, function: function, line: line)
        Log.handleLog(level: .error, str: str, shouldLogContext: shouldLogContext, context: context) {
            DDLogError($0)
        }
    }

    /**
     Log level fatal error: Use for fatal errors that must force a shutdown of service or application to prevent data loss or corruption (or further data loss). This will also trasmit to Firebase console.
     */
    static func fatal(_ str: String, shouldLogContext: Bool = true, file: String = #file, function: String = #function, line: Int = #line) {
        let context = Context(file: file, function: function, line: line)
        Log.handleLog(level: .fatal, str: str, shouldLogContext: shouldLogContext, context: context) {
            DDLogError($0)

            // Also emit log to Firebase
            fatalError($0)
        }
    }

    /**
    Sets log level at run time.
    */
    static func setLogLevel(_ level: LogLevel) {
        switch level {
        case .debug:   dynamicLogLevel = .debug
        case .info:    dynamicLogLevel = .info
        case .warn:    dynamicLogLevel = .warning
        case .error, .fatal:   dynamicLogLevel = .error
        }
    }
    
    fileprivate static func handleLog(level: LogLevel, str: String, shouldLogContext: Bool, context: Context, completion: @escaping (String)-> Void) {
        let logComponents = ["[\(level.prefix)]", str]
        
        var fullString = logComponents.joined(separator: " ")
        if shouldLogContext {
            fullString += " ➜ \(context)"
        }

        completion(fullString)
    }

}
