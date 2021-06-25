//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Gleb Cherkashyn on 24.06.2021.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import XCTest
@testable import EssentialFeed

final class CodableFeedStore {
	private struct Cache: Codable {
		
		let feed: [CodableFeedImage]
		let timestamp: Date
		
		var localFeed: [LocalFeedImage] {
			feed.map { $0.local }
		}
		
		init(_ feed: [CodableFeedImage], _ timestamp: Date) {
			self.feed = feed
			self.timestamp = timestamp
		}
	}
	
	private struct CodableFeedImage: Codable {
		let id: UUID
		let description: String?
		let location: String?
		let url: URL
		
		var local: LocalFeedImage {
			.init(id: id, description: description, location: location, url: url)
		}
		
		init(_ image: LocalFeedImage) {
			id = image.id
			description = image.description
			location = image.location
			url = image.url
		}
	}
	
	private let storeURL: URL
	
	init(storeURL: URL) {
		self.storeURL = storeURL
	}
	
	func retrieve(completion: @escaping FeedStore.RetrievalCompletion) {
		guard let data = try? Data(contentsOf: storeURL) else {
			return completion(.empty)
		}
		
		do {
			let decoder = JSONDecoder()
			let cache = try decoder.decode(Cache.self, from: data)
			completion(.found(feed: cache.localFeed, timestamp: cache.timestamp))
		} catch {
			completion(.failure(error))
		}
	}
	
	func insert(_ feed: [LocalFeedImage],
							timestamp: Date,
							completion: @escaping FeedStore.InsertionCompletion) {
		let encoder = JSONEncoder()
		let encoded = try! encoder.encode(Cache(feed.map { CodableFeedImage($0) }, timestamp))
		try! encoded.write(to: storeURL)
		completion(nil)
	}
}

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
		let sut = makeSUT()
		
		try! "invalid data".write(to: testSpecificStoreURL, atomically: false, encoding: .utf8)
		
		expect(sut, toRetrieve: .failure(anyNSError()))
	}
	
	// MARK: - Helpers
	
	private func makeSUT() -> CodableFeedStore {
		let sut = CodableFeedStore(storeURL: testSpecificStoreURL)
		trackForMemoryLeaks(sut)
		
		return sut
	}
	
	private func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date), to sut: CodableFeedStore) {
		let exp = expectation(description: "Wait for cache insertion")
		sut.insert(cache.feed, timestamp: cache.timestamp) { insertionError in
			XCTAssertNil(insertionError, "Expected feed to be inserted successfully")
			exp.fulfill()
		}
		wait(for: [exp], timeout: 1)
	}
	
	private func expect(_ sut: CodableFeedStore,
											toRetrieveTwice expectedResult: RetrieveCacheFeedResult,
											file: StaticString = #file,
											line: UInt = #line) {
		expect(sut, toRetrieve: expectedResult)
		expect(sut, toRetrieve: expectedResult)
	}
	
	private func expect(_ sut: CodableFeedStore,
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
	
	private let testSpecificStoreURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).store")
	
	private func setupEmptyStoreState() {
		deleteStoreArtifacts()
	}
	
	private func undoStoreSideEffects() {
		deleteStoreArtifacts()
	}
	
	private func deleteStoreArtifacts() {
		try? FileManager.default.removeItem(at: testSpecificStoreURL)
	}
}
