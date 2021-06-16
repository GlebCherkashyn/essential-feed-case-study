//
//  ValidateFeedCacheUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Gleb Cherkashyn on 04.05.2021.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import XCTest
import EssentialFeed

class ValidateFeedCacheUseCaseTests: XCTestCase {

  func test_init_doesNotMessageStoreUponCreation() {
    let (store, _) = makeSUT()
    
    XCTAssertEqual(store.receivedMessages, [])
  }
  
  func test_validateCache_deletesCacheOnRetrievalError() {
    let (store, sut) = makeSUT()
    
    sut.validateCache()
    store.completeRetrieval(with: anyNSError())
    
    XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedFeed])
  }
  
  func test_validateCache_doesNotDeleteCacheOnEmptyCache() {
    let (store, sut) = makeSUT()
    
    sut.validateCache()
    store.completeRetrievalWithEmptyCache()
    
    XCTAssertEqual(store.receivedMessages, [.retrieve])
  }

  func test_validateCache_doesNotDeleteCacheOnNonExpiredCache() {
    let fixedCurrentDate = Date()
    let feed = uniqueImageFeed
		let nonExpiredTimestamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: 1)
    let (store, sut) = makeSUT(currentDate: { fixedCurrentDate })
    
    sut.validateCache()
    store.completeRetrieval(with: feed.local, timestamp: nonExpiredTimestamp)
    
    XCTAssertEqual(store.receivedMessages, [.retrieve])
  }
  
  func test_validateCache_deletesCacheOnExpiration() {
    let fixedCurrentDate = Date()
    let feed = uniqueImageFeed
    let expirationTimestamp = fixedCurrentDate.minusFeedCacheMaxAge()
    let (store, sut) = makeSUT(currentDate: { fixedCurrentDate })
    
    sut.validateCache()
    store.completeRetrieval(with: feed.local, timestamp: expirationTimestamp)
    
    XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedFeed])
  }
  
  func test_validateCache_deletesExpiredCache() {
    let fixedCurrentDate = Date()
    let feed = uniqueImageFeed
    let expiredTimestamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: -1)
    let (store, sut) = makeSUT(currentDate: { fixedCurrentDate })
    
    sut.validateCache()
    store.completeRetrieval(with: feed.local, timestamp: expiredTimestamp)
    
    XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedFeed])
  }
  
  func test_validateCache_doesNotDeleteInvalidCacheAfterSUTInstanceHasBeenDeallocated() {
    let store = FeedStoreSpy()
    var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
    
    sut?.validateCache()
    
    sut = nil
    store.completeRetrieval(with: anyNSError())
    
    XCTAssertEqual(store.receivedMessages, [.retrieve])
  }
  
  // MARK: - Helpers
  
  private func makeSUT(currentDate: @escaping (() -> Date) = Date.init,
                       file: StaticString = #file,
                       line: UInt = #line) -> (FeedStoreSpy, LocalFeedLoader) {
    let store = FeedStoreSpy()
    let sut = LocalFeedLoader(store: store, currentDate: currentDate)
    
    trackForMemoryLeaks(store, file: file, line: line)
    trackForMemoryLeaks(sut, file: file, line: line)
    
    return (store, sut)
  }
}
