//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Gleb Cherkashyn on 25.04.2021.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import XCTest

class FeedStore {
  var deleteCachedFeedCounter = 0
}

class LocalFeedLoader {
  init(store: FeedStore) {}
}

final class CacheFeedUseCaseTests: XCTestCase {
  
  func test_init_doesNotDeleteCacheUponCreation() {
    let store = FeedStore()
    _ = LocalFeedLoader(store: store)
    
    XCTAssertEqual(store.deleteCachedFeedCounter, 0)
  }
}

