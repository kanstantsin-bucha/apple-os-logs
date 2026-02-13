import XCTest
import OSLogs
import OSLog

final class OSLogsTests: XCTestCase {

    func test_logsRetrieval() async throws {
        Logs.main.log("TEST MESSAGE")
        let string = String(data: await Logs.actor.getLogData(interval: 5), encoding: .utf8) ?? ""
        print("LogData: \(string)")
        XCTAssertTrue(string.contains("TEST MESSAGE [OSLogsTests.swift test_logsRetrieval()]"))
    }

    func test_logDestination() async throws {
        let collector = LogCollector()
        let expectation = XCTestExpectation(description: "all")
        let error = TestError()

        expectation.expectedFulfillmentCount = 5

        await Logs.actor.add { [collector] type, category, message, event, error in
            await collector.append(params: (type, category, message, event, error))
            expectation.fulfill()
        }

        // When
        Logs.main.log("[log 1]")
        Logs.main.info("[info 1]")
        Logs.main.info("[info 2]", event: "[event 1]")
        Logs.main.error("[error 1]")
        Logs.main.error("[error 2]", error: error)

        await fulfillment(of: [expectation], timeout: 2)
        let logs = await collector.logs

        // Then
        let log1 = logs.element(at: 0)
        let info1 = logs.element(at: 1)
        let info2 = logs.element(at: 2)
        let error1 = logs.element(at: 3)
        let error2 = logs.element(at: 4)

        XCTAssertNotNil(log1)
        XCTAssertNotNil(info1)
        XCTAssertNotNil(info2)
        XCTAssertNotNil(error1)
        XCTAssertNotNil(error2)

        XCTAssertEqual(log1?.message, "[log 1] [OSLogsTests.swift test_logDestination()]")

        XCTAssertEqual(info1?.message, "[info 1] [OSLogsTests.swift test_logDestination()]")

        XCTAssertEqual(info2?.message, "[event 1]: [info 2] [OSLogsTests.swift test_logDestination()]")
        XCTAssertEqual(info2?.event, "[event 1]")

        XCTAssertEqual(error1?.message, "[error 1] [OSLogsTests.swift test_logDestination()]")

        XCTAssertEqual(error2?.message, "[error 2]: TestError() [OSLogsTests.swift test_logDestination()]")
        XCTAssertNotNil(error2?.error as? TestError)
    }

    private struct TestError: Error, Equatable {}
}

private actor LogCollector {
    typealias Params = (type: OSLogType, category: String,
                        message: String, event: String?, error: (any Error)?)
    var logs: [Params] = []

    func append(params: Params) {
        logs.append(params)
    }
}

private extension Array where Element == LogCollector.Params {

    func element(at index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}
