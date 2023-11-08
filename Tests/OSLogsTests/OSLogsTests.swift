import XCTest
import OSLogs

final class OSLogsTests: XCTestCase {
    func testLog() throws {
        Logs.main.log("TEST MESSAGE")
        let string = String(data: Logs.getLogData(interval: 5), encoding: .utf8) ?? ""
        print(string)
        XCTAssertTrue(string.contains("TEST MESSAGE"))
    }
}
