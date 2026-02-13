import Foundation
import OSLog

extension Logs {

    @available(macOS 12.0, iOS 15.0, *)
    public struct AppLogger: Sendable {
        
        static let subsystem = Bundle.main.bundleIdentifier ?? "OSLogger"
        private let osLogger: os.Logger
        private let category: String

        public init(category: String) {
            osLogger = os.Logger(subsystem: Self.subsystem, category: category)
            self.category = category
        }

        /// Logs the default message
        /// - Parameters:
        ///   - message: The message that describes the context
        ///   - file: The file of the source code location
        ///   - function: The function of the source code location
        public func log(_ message: String, file: String = #fileID, function: String = #function) {
            note(message: message, level: OSLogType.default, file: file, function: function)
        }

        /// Logs the useful info, in format `event: message`
        /// - Parameters:
        ///   - message: The message that describes the context
        ///   - event: The short classified name of the event that we describe
        ///   - file: The file of the source code location
        ///   - function: The function of the source code location
        public func info(_ message: String, event: String? = nil, file: String = #fileID, function: String = #function) {
            note(message: message, event: event, level: OSLogType.info, file: file, function: function)
        }


        /// Logs the error with message first, then the error description.
        /// - Parameters:
        ///   - message: The message that describes the context
        ///   - event: The event to log
        ///   - error: The error to log
        ///   - file: The file of the source code location
        ///   - function: The function of the source code location
        public func error(_ message: String, error: Error? = nil, file: String = #fileID, function: String = #function) {
            note(message: message, error: error, level: OSLogType.error, file: file, function: function)
        }

        private func note(
            message: String,
            event: String? = nil,
            error: Error? = nil,
            level: OSLogType,
            file: String,
            function: String
        ) {
            let fileName = file.components(separatedBy: "/").last ?? ""
            var logMessage = ""
            if let event {
                logMessage += event + ": "
            }
            logMessage += message
            if let error {
                logMessage += ": " + String(describing: error)
            }
            logMessage += " [\(fileName) \(function)]"
            // https://developer.apple.com/documentation/os/logger
            // 2023-06-20 10:58:58 am +0000: notice: subsystem-category:   [<private> configureTimeControlStatusObserver()] <private> -> 6240034
            // OS hides too much right now, so we override our logs to be public
            osLogger.log(level: level, "\(logMessage, privacy: .public)")
            Task {
                await Logs.actor.sendToDestinations(
                    level: level,
                    category: category,
                    message: logMessage,
                    event: event,
                    error: error
                )
            }
        }
    }
}
