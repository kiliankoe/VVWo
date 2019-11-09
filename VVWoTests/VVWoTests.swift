import XCTest
@testable import VVWo

class APITests: XCTestCase {

    var client: API!

    override func setUp() {
        self.client = API()
    }

    func testBasicResponse() {
        client.parse(query: "Bring mich zum Hauptbahnhof")

        let e = expectation(description: "get data")

        // This is just a POC, obviously not how this should be tested 🙈
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
            XCTAssertNotNil(self.client.latestQuery)
            e.fulfill()
        }

        waitForExpectations(timeout: 5)
    }
}
