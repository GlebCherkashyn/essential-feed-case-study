//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Gleb Cherkashyn on 24.06.2021.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import XCTest
@testable import EssentialFeed

final class CodableFeedStoreTests: XCTestCase {
	
	override func setUp() {
		super.setUp()
		
		setupEmptyStoreState()
	}
	
	override func tearDown() {
		super.tearDown()
		
		undoStoreSideEffects()
	}
	
	func test_retrieve_deliversEmptyOnEmptyCache() {
		let sut = makeSUT()
		
		expect(sut, toRetrieve: .empty)
	}
	
	func test_retrieve_hasNoSideEffectsOnEmptyCache() {
		let sut = makeSUT()
		
		expect(sut, toRetrieveTwice: .empty)
	}
	
	func test_retrieveAfterInsertingToEmptyCache_deliversInsertedValues() {
		let sut = makeSUT()
		let feed = uniqueImageFeed.local
		let timestamp = Date()
		
		insert((feed, timestamp), to: sut)
		
		expect(sut, toRetrieve: .found(feed: feed, timestamp: timestamp))
	}
	
	func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
		let sut = makeSUT()
		let feed = uniqueImageFeed.local
		let timestamp = Date()
		
		insert((feed, timestamp), to: sut)
		
		expect(sut, toRetrieveTwice: .found(feed: feed, timestamp: timestamp))
	}
	
	func test_retrieve_deliversFailureOnRetrievalError() {
		let storeURL = Self.testSpecificStoreURL
		let sut = makeSUT(storeURL: storeURL)
		
		try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
		
		expect(sut, toRetrieve: .failure(anyNSError()))
	}
	
	func test_retrieve_hasNoSideEffectsOnFailure() {
		let storeURL = Self.testSpecificStoreURL
		let sut = makeSUT(storeURL: storeURL)
		
		try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
		
		expect(sut, toRetrieveTwice: .failure(anyNSError()))
	}
	
	func test_insert_overridesPreviouslyInsertedCacheValues() {
		let sut = makeSUT()
		
		let firstInsertionError = insert((uniqueImageFeed.local, Date()), to: sut)
		XCTAssertNil(firstInsertionError, "Expected to insert cache successfully")
		
		let latestFeed = uniqueImageFeed.local
		let latestTimestamp = Date()
		let latestInsertionError = insert((latestFeed, latestTimestamp), to: sut)
		XCTAssertNil(latestInsertionError, "Expected to insert cache successfully")
		
		expect(sut, toRetrieve: .found(feed: latestFeed, timestamp: latestTimestamp))
	}
	
	func test_insert_deliversErrorOnInsertionError() {
		let invalidStoreURL = URL(string: "invalid://store-url")!
		let sut = makeSUT(storeURL: invalidStoreURL)
		let feed = uniqueImageFeed.local
		let timestamp = Date()
		
		let insertionError = insert((feed, timestamp), to: sut)
		
		XCTAssertNotNil(insertionError, "Expected cache insertion to fail with an error")
	}
	
	func test_delete_hasNoSideEffectsOnEmptyCache() {
		let sut = makeSUT()
		
		let deletionError = deleteCache(from: sut)
		
		XCTAssertNil(deletionError, "Expected empty cache deletion to succeed")
		expect(sut, toRetrieve: .empty)
	}
	
	func test_delete_emptiesPreviouslyInsertedCache() {
		let sut = makeSUT()
		insert((uniqueImageFeed.local, Date()), to: sut)
		
		let deletionError = deleteCache(from: sut)
		
		XCTAssertNil(deletionError, "Expected non-empty cache deletion to succeed")
		expect(sut, toRetrieve: .empty)
	}
	
	func test_delete_deliversErrorOnDeletionError() {
		let noDeletePermissionsURL = Self.cachesDirectory
		let sut = makeSUT(storeURL: noDeletePermissionsURL)
		
		let deletionError = deleteCache(from: sut)
		
		XCTAssertNotNil(deletionError, "Expected cache deletion to fail")
	}
	
	func test_storeSideEffects_runSerially() {
		let sut = makeSUT()
		
		var completedOperationsInOrder: [XCTestExpectation] = []
		
		let op1 = expectation(description: "Operation 1")
		sut.insert(uniqueImageFeed.local, timestamp: Date()) { _ in
			completedOperationsInOrder.append(op1)
			op1.fulfill()
		}
		
		let op2 = expectation(description: "Operation 2")
		sut.deleteCachedFeed { _ in
			completedOperationsInOrder.append(op2)
			op2.fulfill()
		}
		
		let op3 = expectation(description: "Operation 3")
		sut.insert(uniqueImageFeed.local, timestamp: Date()) { _ in
			completedOperationsInOrder.append(op3)
			op3.fulfill()
		}
		
		waitForExpectations(timeout: 5)
		
		XCTAssertEqual(completedOperationsInOrder, [op1, op2, op3], "Expected side-effects to run serially but operations finished in the wrong order")
	}
	
	// MARK: - Helpers
	
	private func makeSUT(storeURL: URL = testSpecificStoreURL) -> FeedStore {
		let sut = CodableFeedStore(storeURL: storeURL)
		
		trackForMemoryLeaks(sut)
		
		return sut
	}
	
	@discardableResult
	private func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date),
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
	
	private func deleteCache(from sut: FeedStore) -> Error? {
		let exp = expectation(description: "Wait for cache deletion")
		var deletionError: Error?
		
		sut.deleteCachedFeed { receivedDeletionError in
			deletionError = receivedDeletionError
			exp.fulfill()
		}
		
		wait(for: [exp], timeout: 1)
		
		return deletionError
	}
	
	private func expect(_ sut: FeedStore,
											toRetrieveTwice expectedResult: RetrieveCacheFeedResult,
											file: StaticString = #file,
											line: UInt = #line) {
		expect(sut, toRetrieve: expectedResult)
		expect(sut, toRetrieve: expectedResult)
	}
	
	private func expect(_ sut: FeedStore,
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
	
	private static let testSpecificStoreURL = cachesDirectory.appendingPathComponent("\(type(of: self)).store")
	
	private static let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
	
	private func setupEmptyStoreState() {
		deleteStoreArtifacts()
	}
	
	private func undoStoreSideEffects() {
		deleteStoreArtifacts()
	}
	
	private func deleteStoreArtifacts() {
		try? FileManager.default.removeItem(at: Self.testSpecificStoreURL)
	}
}
