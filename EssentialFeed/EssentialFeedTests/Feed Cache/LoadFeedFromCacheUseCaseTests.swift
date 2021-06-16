//
//  LoadFeedFromCacheUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Gleb Cherkashyn on 25.04.2021.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import XCTest
import EssentialFeed

final class LoadFeedFromCacheUseCaseTests: XCTestCase {
  
  func test_init_doesNotMessageStoreUponCreation() {
    let (store, _) = makeSUT()
    
    XCTAssertEqual(store.receivedMessages, [])
  }
  
  func test_load_requestsCacheRetrieval() {
    let (store, sut) = makeSUT()
    
    sut.load { _ in }
    XCTAssertEqual(store.receivedMessages, [.retrieve])
  }
  
  func test_load_deliversErrorOnCacheRetrievalError() {
    let (store, sut) = makeSUT()
    let retrievalError = anyNSError()
    
    expect(sut, toCompleteWith: .failure(retrievalError), when: {
      store.completeRetrieval(with: retrievalError)
    })
  }
  
  func test_load_deliversNoImagesOnEmptyCache() {
    let (store, sut) = makeSUT()
    
    expect(sut, toCompleteWith: .success([]), when: {
      store.completeRetrievalWithEmptyCache()
    })
  }
  
  func test_load_deliversCachedImagesOnNonExpiredCache() {
    let fixedCurrentDate = Date()
    let feed = uniqueImageFeed
    let nonExpiredTimestamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: 1)
    let (store, sut) = makeSUT(currentDate: { fixedCurrentDate })
    
    expect(sut, toCompleteWith: .success(feed.models), when: {
      store.completeRetrieval(with: feed.local, timestamp: nonExpiredTimestamp)
    })
  }
  
  func test_load_deliversNoImagesOnCacheExpiration() {
    let fixedCurrentDate = Date()
    let feed = uniqueImageFeed
    let expirationTimestamp = fixedCurrentDate.minusFeedCacheMaxAge()
    let (store, sut) = makeSUT(currentDate: { fixedCurrentDate })
    
    expect(sut, toCompleteWith: .success([]), when: {
      store.completeRetrieval(with: feed.local, timestamp: expirationTimestamp)
    })
  }
  
  func test_load_deliversNoImagesOnExpiredCache() {
    let fixedCurrentDate = Date()
    let feed = uniqueImageFeed
    let expiredTimestamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: -1)
    let (store, sut) = makeSUT(currentDate: { fixedCurrentDate })
    
    expect(sut, toCompleteWith: .success([]), when: {
      store.completeRetrieval(with: feed.local, timestamp: expiredTimestamp)
    })
  }
  
  func test_load_hasNoSideEffectsOnRetrievalError() {
    let (store, sut) = makeSUT()
    
    sut.load { _ in }
    store.completeRetrieval(with: anyNSError())
    
    XCTAssertEqual(store.receivedMessages, [.retrieve])
  }
  
  func test_load_hasNoSideEffectsOnEmptyCache() {
    let (store, sut) = makeSUT()
    
    sut.load { _ in }
    store.completeRetrievalWithEmptyCache()
    
    XCTAssertEqual(store.receivedMessages, [.retrieve])
  }
  
  func test_load_hasNoSideEffectsOnNonExpiredCache() {
    let fixedCurrentDate = Date()
    let feed = uniqueImageFeed
    let nonExpiredTimestamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: 1)
    let (store, sut) = makeSUT(currentDate: { fixedCurrentDate })
    
    sut.load { _ in }
    store.completeRetrieval(with: feed.local, timestamp: nonExpiredTimestamp)
    
    XCTAssertEqual(store.receivedMessages, [.retrieve])
  }
  
  func test_load_hasNoSideEffectsOnCacheExpiration() {
    let fixedCurrentDate = Date()
    let feed = uniqueImageFeed
    let expirationTimestamp = fixedCurrentDate.minusFeedCacheMaxAge()
    let (store, sut) = makeSUT(currentDate: { fixedCurrentDate })
    
    sut.load { _ in }
    store.completeRetrieval(with: feed.local, timestamp: expirationTimestamp)
    
    XCTAssertEqual(store.receivedMessages, [.retrieve])
  }
  
  func test_load_hasNoSideEffectsOnExpiredCache() {
    let fixedCurrentDate = Date()
    let feed = uniqueImageFeed
    let expiredTimestamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: -1)
    let (store, sut) = makeSUT(currentDate: { fixedCurrentDate })
    
    sut.load { _ in }
    store.completeRetrieval(with: feed.local, timestamp: expiredTimestamp)
    
    XCTAssertEqual(store.receivedMessages, [.retrieve])
  }
  
  func test_load_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
    let store = FeedStoreSpy()
    var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
    
    var receivedResults: [LocalFeedLoader.LoadResult] = []
    sut?.load { receivedResults.append($0) }
    
    sut = nil
    store.completeRetrievalWithEmptyCache()
    
    XCTAssertTrue(receivedResults.isEmpty)
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
  
  func expect(_ sut: LocalFeedLoader,
              toCompleteWith expectedResult: LocalFeedLoader.LoadResult,
              when action: () -> Void,
              file: StaticString = #file,
              line: UInt = #line) {
    let exp = expectation(description: "wait for load result")

    sut.load { receivedResult in
      switch (receivedResult, expectedResult) {
      case let (.success(receivedImages), .success(expectedImages)):
        XCTAssertEqual(receivedImages, expectedImages)
      case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
        XCTAssertEqual(receivedError, expectedError)
      default:
        XCTFail("Expected result: \(expectedResult), got: \(receivedResult) instead")
      }

      exp.fulfill()
    }

    action()
    wait(for: [exp], timeout: 1)
  }
}
