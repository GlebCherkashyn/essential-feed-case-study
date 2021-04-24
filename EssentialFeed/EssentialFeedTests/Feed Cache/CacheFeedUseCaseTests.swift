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
  private(set) var deleteCachedFeedCounter = 0
  private(set) var insertCallCount = 0
  
  func deleteCachedFeed() {
    deleteCachedFeedCounter += 1
  }
  
  func complete(with error: Error, at index: Int = 0) {
    
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
  
  func test_save_doesNotRequestInsertionOnDeletionCacheError() {
    let (store, sut) = makeSUT()
    let items = [uniqueItem, uniqueItem]
    let deletionError = anyNSError()
    
    sut.save(items)
    store.complete(with: deletionError)
    
    XCTAssertEqual(store.insertCallCount, 0)
  }
  
  // MARK: - Helpers
  
  private func makeSUT(file: StaticString = #file,
                       line: UInt = #line) -> (FeedStore, LocalFeedLoader) {
    let store = FeedStore()
    let sut = LocalFeedLoader(store: store)
    
    trackForMemoryLeaks(store, file: file, line: line)
    trackForMemoryLeaks(sut, file: file, line: line)
    
    return (store, sut)
  }
  
  private var uniqueItem: FeedItem {
    FeedItem(id: UUID(), description: "any", location: nil, imageURL: anyURL())
  }
  
  private func anyURL() -> URL {
    return URL(string: "http://any-url.com")!
  }
  
  private func anyNSError() -> NSError {
    return NSError(domain: "any error", code: 0)
  }
}

