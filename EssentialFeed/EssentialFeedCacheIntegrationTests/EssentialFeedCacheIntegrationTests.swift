//
//  EssentialFeedCacheIntegrationTests.swift
//  EssentialFeedCacheIntegrationTests
//
//  Created by Gleb Cherkashyn on 22.07.2021.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import XCTest
import EssentialFeed

class EssentialFeedCacheIntegrationTests: XCTestCase {

	func test_load_deliversEmptyOnEmptyCache() {
		let sut = makeSUT()
		
		let exp = expectation(description: "Wait for load completion")
		sut.load { result in
			switch result {
			case let .success(imageFeed):
				XCTAssertEqual(imageFeed, [], "Expected empty feed")
			case let .failure(error):
				XCTFail("Expected successful feed result, got \(error) instead")
			}
			
			exp.fulfill()
		}
		
		wait(for: [exp], timeout: 1)
	}
	
	private func makeSUT(file: StaticString = #file,
											 line: UInt = #line) -> LocalFeedLoader {
		let storeBundle = Bundle(for: CoreDataFeedStore.self)
		let storeURL = testSpecificStoreURL
		let store = try! CoreDataFeedStore(storeURL: storeURL, bundle: storeBundle)
		let sut = LocalFeedLoader(store: store, currentDate: Date.init)
		
		trackForMemoryLeaks(store, file: file, line: line)
		trackForMemoryLeaks(sut, file: file, line: line)
		
		return sut
	}
	
	private var testSpecificStoreURL: URL {
		cachesDirectory.appendingPathComponent("\(type(of: self)).store")
	}
	
	private var cachesDirectory: URL {
		FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
	}
}
