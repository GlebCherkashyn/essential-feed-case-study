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
	
	private let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("image-feed.store")
	
	func retrieve(completion: @escaping FeedStore.RetrievalCompletion) {
		guard let data = try? Data(contentsOf: storeURL) else {
			return completion(.empty)
		}
		
		let decoder = JSONDecoder()
		let cache = try! decoder.decode(Cache.self, from: data)
		
		completion(.found(feed: cache.localFeed, timestamp: cache.timestamp))
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
		
		cleanArtefacts()
	}
	
	override func tearDown() {
		super.tearDown()
		
		cleanArtefacts()
	}
	
	private func cleanArtefacts() {
		let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("image-feed.store")
		try? FileManager.default.removeItem(at: storeURL)
	}
	
	func test_retrieve_deliversEmptyOnEmptyCache() {
		let sut = CodableFeedStore()
		let exp = expectation(description: "Wait for cache retrieval")
		
		sut.retrieve { result in
			switch result {
			case .empty:
				break
				
			default:
				XCTFail("Expected empty result, got \(result) instead")
			}
			
			exp.fulfill()
		}
		
		wait(for: [exp], timeout: 1)
	}
	
	func test_retrieve_hasNoSideEffectsOnEmptyCache() {
		let sut = CodableFeedStore()
		let exp = expectation(description: "Wait for cache retrieval")
		
		sut.retrieve { firstResult in
			sut.retrieve { secondResult in
				switch (firstResult, secondResult) {
				case (.empty, .empty):
					break
					
				default:
					XCTFail("Expected retrieving twice from empty cache to deliver same empty result, got \(firstResult) and \(secondResult) instead")
				}
				
				exp.fulfill()
			}
		}
		
		wait(for: [exp], timeout: 1)
	}
	
	func test_retrieveAfterInsertingToEmptyCache_deliversInsertedValues() {
		let sut = CodableFeedStore()
		let feed = uniqueImageFeed.local
		let timestamp = Date()
		let exp = expectation(description: "Wait for cache retrieval")
		
		sut.insert(feed, timestamp: timestamp) { insertionError in
			XCTAssertNil(insertionError, "Expected feed to be inserted successfully")
			
			sut.retrieve { retrievedResult in
				switch retrievedResult {
				case let .found(retrievedFeed, retrievedTimestamp):
					XCTAssertEqual(retrievedFeed, feed)
					XCTAssertEqual(retrievedTimestamp, timestamp)
					
				default:
					XCTFail("Expected found result with feed: \(feed) and timestamp: \(timestamp), got \(retrievedResult) instead")
				}
				
				exp.fulfill()
			}
		}
		
		wait(for: [exp], timeout: 1)
	}
}
