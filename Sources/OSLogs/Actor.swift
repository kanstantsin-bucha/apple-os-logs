import OSLog
import Foundation

extension Logs {
    
    @available(macOS 12.0, iOS 15.0, *)
    public actor AppActor {
        
        public typealias LogDestination = @Sendable (OSLogType, _ category: String, _ message: String, _ event: String?, _ error: Error?) -> Void
        private var logDestinations: [LogDestination] = []

        public func add(logDestination: @escaping LogDestination) {
            logDestinations.append(logDestination)
        }

        public func sendToDestinations(level: OSLogType, category: String, message: String, event: String?, error: Error?) {
            logDestinations.forEach { $0(level, category, message, event, error) }
        }

        /// Gets the App logs from the system
        /// - Parameter interval: The time from now into the past (default is 1 hour)
        /// - Returns: The data (string utf-8)
        public func getLogData(interval: TimeInterval = 60 * 60) -> Data {
            do {
                var logs = ""
                for entry in try getLogEntries(interval: interval) {
                    logs += entry.logString
                }
                guard let data = logs.data(using: .utf8) else {
                    throw LocalError.failedConversionStringToData
                }
                return data
            } catch {
                Logs.main.log("Failed to get logs data with error: \(error)")
                return Data()
            }
        }

        /// The way to add a hook to all app logs going into the system
        /// - Parameter logDestination: the closure that will be called for every log logged in the App
        private func getLogEntries(interval: TimeInterval, isFullLog: Bool = false) throws -> [OSLogEntryLog] {
            let logStore = try OSLogStore(scope: .currentProcessIdentifier)
            let oneHourAgo = logStore.position(date: Date().addingTimeInterval(-1 * interval)) // 1h before
            // FB8518539: Using NSPredicate to filter the subsystem doesn't seem to work.
            let allEntries = try logStore.getEntries(at: oneHourAgo)

            var entries = allEntries
                .compactMap { $0 as? OSLogEntryLog }
            if !isFullLog {
                entries = entries.filter { $0.subsystem == Logs.AppLogger.subsystem }
            }
            return entries
        }

        public enum LocalError: Error {
            case failedConversionStringToData
        }
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

