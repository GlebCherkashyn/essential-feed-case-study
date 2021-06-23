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
	func retrieve(completion: @escaping FeedStore.RetrievalCompletion) {
		completion(.empty)
	}
}

final class CodableFeedStoreTests: XCTestCase {
	
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
}
