import OSLog
import Foundation

@available(macOS 12.0, iOS 15.0, *)
public enum Logs {
    public typealias LogDestination = (OSLogType, _ category: String, _ message: String) -> Void
    public static let main = AppLogger(category: "") // General
    fileprivate static var logDestinations: [LogDestination] = []

    /// Gets the App logs from the system
    /// - Parameter interval: The time from now into the past (default is 1 hour)
    /// - Returns: The data (string utf-8)
    public static func getLogData(interval: TimeInterval = 60 * 60) -> Data {
        do {
            var logs = ""
            for entry in try getLogEntries(interval: interval) {
                logs += entry.logString
            }
            guard let data = logs.data(using: .utf8) else {
                throw LogsError.failedConversionStringToData
            }
            return data
        } catch {
            main.log("Failed to get logs data with error: \(error)")
            return Data()
        }
    }
    
    /// The way to add a hook to all app logs going into the system
    /// - Parameter logDestination: the closure that will be called for every log logged in the App
    @MainActor
    public static func add(logDestination: @escaping LogDestination) {
        logDestinations.append(logDestination)
    }

    private static func getLogEntries(interval: TimeInterval, isFullLog: Bool = false) throws -> [OSLogEntryLog] {
        let logStore = try OSLogStore(scope: .currentProcessIdentifier)
        let oneHourAgo = logStore.position(date: Date().addingTimeInterval(-1 * interval)) // 1h before
        // FB8518539: Using NSPredicate to filter the subsystem doesn't seem to work.
        let allEntries = try logStore.getEntries(at: oneHourAgo)

        var entries = allEntries
            .compactMap { $0 as? OSLogEntryLog }
        if !isFullLog {
            entries = entries.filter { $0.subsystem == AppLogger.subsystem }
        }
        return entries
    }

    public enum LogsError: Error {
        case failedConversionStringToData
    }
}

@available(macOS 12.0, iOS 15.0, *)
public struct AppLogger {
    static let subsystem = Bundle.main.bundleIdentifier ?? "OSLogger"
    private let logger: Logger
    private let category: String

    public init(category: String) {
        logger = Logger(subsystem: Self.subsystem, category: category)
        self.category = category
    }

    public func log(_ message: String, file: String = #fileID, function: String = #function) {
        note(message: message, level: OSLogType.default, file: file, function: function)
    }

    public func error(_ message: String, file: String = #fileID, function: String = #function) {
        note(message: message, level: OSLogType.error, file: file, function: function)
    }

    private func note(message: String, level: OSLogType, file: String, function: String) {
        let fileName = file.components(separatedBy: "/").last ?? ""
        let message = "[\(fileName) \(function)] \(message)"
        // https://developer.apple.com/documentation/os/logger
        // 2023-06-20 10:58:58 am +0000: notice: subsystem-category:   [<private> configureTimeControlStatusObserver()] <private> -> 6240034
        // OS hides too much right now, so we override our logs to be public
        logger.log(level: level, "\(message, privacy: .public)")
        Logs.logDestinations.forEach { $0(level, category, message) }
    }
}

@available(macOS 12.0, iOS 15.0, *)
fileprivate extension OSLogEntryLog {
    var logString: String {
        "\(date): \(level.logString): \(subsystem)-\(category):   \(composedMessage) -> \(threadIdentifier)\r\n"
    }
}

@available(macOS 12.0, iOS 15.0, *)
fileprivate extension OSLogEntryLog.Level {
    var logString: String {
        switch self {
        case .debug:
            return "debug"
        case .error:
            return "error"
        case .fault:
            return "fault"
        case .info:
            return "info"
        case .notice:
            return "notice"
        case .undefined:
            return "undefined"
        @unknown default:
            return "undefined new"
        }
    }
}
