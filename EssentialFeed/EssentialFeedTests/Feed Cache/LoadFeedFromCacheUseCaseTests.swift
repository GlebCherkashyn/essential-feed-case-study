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
  
  func test_load_deliversCachedImagesOnLessThanSevenDaysOldCache() {
    let fixedCurrentDate = Date()
    let feed = uniqueImageFeed
    let lessThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: 1)
    let (store, sut) = makeSUT(currentDate: { fixedCurrentDate })
    
    expect(sut, toCompleteWith: .success(feed.models), when: {
      store.completeRetrieval(with: feed.local, timestamp: lessThanSevenDaysOldTimestamp)
    })
  }
  
  func test_load_deliversNoImagesOnSevenDaysOldCache() {
    let fixedCurrentDate = Date()
    let feed = uniqueImageFeed
    let sevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7)
    let (store, sut) = makeSUT(currentDate: { fixedCurrentDate })
    
    expect(sut, toCompleteWith: .success([]), when: {
      store.completeRetrieval(with: feed.local, timestamp: sevenDaysOldTimestamp)
    })
  }
  
  func test_load_deliversNoImagesOnMoreThanSevenDaysOldCache() {
    let fixedCurrentDate = Date()
    let feed = uniqueImageFeed
    let moreThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: -1)
    let (store, sut) = makeSUT(currentDate: { fixedCurrentDate })
    
    expect(sut, toCompleteWith: .success([]), when: {
      store.completeRetrieval(with: feed.local, timestamp: moreThanSevenDaysOldTimestamp)
    })
  }
  
  func test_load_deletesCacheOnRetrievalError() {
    let (store, sut) = makeSUT()
    
    sut.load { _ in }
    store.completeRetrieval(with: anyNSError())
    
    XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedFeed])
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
  
  private func anyNSError() -> NSError {
    return NSError(domain: "any error", code: 0)
  }
  
  private func anyURL() -> URL {
    return URL(string: "http://any-url.com")!
  }
  
  private var uniqueFeedImage: FeedImage {
    FeedImage(id: UUID(), description: "any", location: nil, url: anyURL())
  }
  
  private var uniqueImageFeed: (models: [FeedImage], local: [LocalFeedImage]) {
    let feed = [uniqueFeedImage, uniqueFeedImage]
    let local = feed.map {
      LocalFeedImage(
        id: $0.id,
        description: $0.description,
        location: $0.location,
        url: $0.url
      )}
    
    return (feed, local)
  }
}

private extension Date {
  func adding(days: Int) -> Date {
    Calendar.current.date(byAdding: .day, value: days, to: self)!
  }
  
  func adding(seconds: Int) -> Date {
    Calendar.current.date(byAdding: .second, value: seconds, to: self)!
  }
}
