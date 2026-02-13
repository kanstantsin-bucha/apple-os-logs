import OSLog
import Foundation

@available(macOS 12.0, iOS 15.0, *)
public enum Logs {

    public static let main = Logs.AppLogger(category: "") // General
    public static let actor = Logs.AppActor()
}
