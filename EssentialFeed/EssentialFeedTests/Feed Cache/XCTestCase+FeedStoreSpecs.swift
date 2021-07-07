//
//  XCTestCase+FeedStoreSpecs.swift
//  EssentialFeedTests
//
//  Created by Gleb Cherkashyn on 07.07.2021.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import XCTest
import EssentialFeed

extension FeedStoreSpecs where Self: XCTestCase {
	
	@discardableResult
	func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date),
							to sut: FeedStore) -> Error? {
		let exp = expectation(description: "Wait for cache insertion")
		var insertionError: Error?
		
		sut.insert(cache.feed, timestamp: cache.timestamp) { retrievedInsertionError in
			insertionError = retrievedInsertionError
			exp.fulfill()
		}
		wait(for: [exp], timeout: 1)
		
		return insertionError
	}
	
	@discardableResult
	func deleteCache(from sut: FeedStore) -> Error? {
		let exp = expectation(description: "Wait for cache deletion")
		var deletionError: Error?
		
		sut.deleteCachedFeed { receivedDeletionError in
			deletionError = receivedDeletionError
			exp.fulfill()
		}
		
		wait(for: [exp], timeout: 1)
		
		return deletionError
	}
	
	func expect(_ sut: FeedStore,
							toRetrieveTwice expectedResult: RetrieveCacheFeedResult,
							file: StaticString = #file,
							line: UInt = #line) {
		expect(sut, toRetrieve: expectedResult)
		expect(sut, toRetrieve: expectedResult)
	}
	
	func expect(_ sut: FeedStore,
							toRetrieve expectedResult: RetrieveCacheFeedResult,
							file: StaticString = #file,
							line: UInt = #line) {
		let exp = expectation(description: "Wait for cache retrieval")
		
		sut.retrieve { retrievedResult in
			switch (expectedResult, retrievedResult) {
			case (.empty, .empty),
					 (.failure, .failure):
				break
				
			case let (.found(expectedFeed, expectedTimestamp), .found(retrievedFeed, retrievedTimestamp)):
				XCTAssertEqual(expectedFeed, retrievedFeed, file: file, line: line)
				XCTAssertEqual(expectedTimestamp, retrievedTimestamp, file: file, line: line)
				
			default:
				XCTFail("Expected to retrieve \(expectedResult), got \(retrievedResult) instead", file: file, line: line)
			}
			
			exp.fulfill()
		}
		
		wait(for: [exp], timeout: 1)
	}
}
