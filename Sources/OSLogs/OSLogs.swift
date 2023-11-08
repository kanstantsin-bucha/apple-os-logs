import OSLog
import Foundation

public enum Logs {
    public static let main = AppLogger(category: "") // General

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

public struct AppLogger {
    static let subsystem = Bundle.main.bundleIdentifier ?? "OSLogger"
    private let logger: Logger

    public init(category: String) {
        self.logger = Logger(subsystem: Self.subsystem, category: category)
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
    }
}

fileprivate extension OSLogEntryLog {
    var logString: String {
        "\(date): \(level.logString): \(subsystem)-\(category):   \(composedMessage) -> \(threadIdentifier)\r\n"
    }
}

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
