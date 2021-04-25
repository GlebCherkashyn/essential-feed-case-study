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
