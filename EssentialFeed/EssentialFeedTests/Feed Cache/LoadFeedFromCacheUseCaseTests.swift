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
    let exp = expectation(description: "wait for load result")
    let retrievalError = anyNSError()
    var receivedError: Error?
    
    sut.load { error in
      receivedError = error
      exp.fulfill()
    }
    
    store.completeRetrieval(with: retrievalError)
    wait(for: [exp], timeout: 1)
    
    XCTAssertEqual(receivedError as NSError?, retrievalError)
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
  
  private func anyNSError() -> NSError {
    return NSError(domain: "any error", code: 0)
  }
}
