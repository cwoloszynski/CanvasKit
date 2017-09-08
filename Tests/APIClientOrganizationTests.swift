//
//  APIClientProjectTests.swift
//  CanvasKitTests
//
//  Created by Sam Soffes on 11/2/15.
//  Copyright © 2015 Canvas Labs, Inc. All rights reserved.
//

import XCTest
import DVR
import CanvasKit

class APIClientProjectTests: XCTestCase {
	func testListProjects() {
		let expectation = expectationWithDescription("Networking")
		let dvr = Session(cassetteName: "list-projects")
		let client = APIClient(accessToken: "REDACTED_TOKEN", session: dvr)

		client.listProjects {
			switch $0 {
			case .Success(let projects):
				XCTAssertEqual(["soffes", "canvas"], projects.map({ $0.name }))
			default:
				XCTFail()
			}
			expectation.fulfill()
		}

		waitForExpectationsWithTimeout(1, handler: nil)
	}
}
