//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Gleb Cherkashyn on 25.04.2021.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import XCTest
@testable import EssentialFeed

class FeedStore {
  var deleteCachedFeedCounter = 0
  
  func deleteCachedFeed() {
    deleteCachedFeedCounter += 1
  }
}

class LocalFeedLoader {
  private let store: FeedStore
  
  init(store: FeedStore) {
    self.store = store
  }
  
  func save(_ items: [FeedItem]) {
    store.deleteCachedFeed()
  }
}

final class CacheFeedUseCaseTests: XCTestCase {
  
  func test_init_doesNotDeleteCacheUponCreation() {
    let (store, _) = makeSUT()
    
    XCTAssertEqual(store.deleteCachedFeedCounter, 0)
  }
  
  func test_save_requestsCacheDeletion() {
    let (store, sut) = makeSUT()
    let items = [uniqueItem, uniqueItem]
    
    sut.save(items)
    
    XCTAssertEqual(store.deleteCachedFeedCounter, 1)
  }
  
  // MARK: - Helpers
  
  private func makeSUT() -> (FeedStore, LocalFeedLoader) {
    let store = FeedStore()
    let sut = LocalFeedLoader(store: store)
    
    return (store, sut)
  }
  
  private var uniqueItem: FeedItem {
    FeedItem(id: UUID(), description: "any", location: nil, imageURL: anyURL())
  }
  
  private func anyURL() -> URL {
    return URL(string: "http://any-url.com")!
  }
}

