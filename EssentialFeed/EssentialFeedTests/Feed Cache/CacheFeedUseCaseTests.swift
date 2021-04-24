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
  typealias DeletionCompletion = (Error?) -> ()
  
  enum ReceivedMessage: Equatable {
    case deleteCachedFeed
    case insert([FeedItem], Date)
  }
  
  private(set) var receivedMessages: [ReceivedMessage] = []
  
  private var deletionCompletions: [DeletionCompletion] = []
  
  func deleteCachedFeed(completion: @escaping DeletionCompletion) {
    deletionCompletions.append(completion)
    receivedMessages.append(.deleteCachedFeed)
  }
  
  func insert(_ items: [FeedItem], timestamp: Date) {
    receivedMessages.append(.insert(items, timestamp))
  }
  
  func complete(with error: Error, at index: Int = 0) {
    deletionCompletions[index](error)
  }
  
  func completeDeletionSuccessfully(at index: Int = 0) {
    deletionCompletions[index](nil)
  }
}

class LocalFeedLoader {
  private let store: FeedStore
  private let currentDate: () -> Date
  
  init(store: FeedStore, currentDate: @escaping () -> Date) {
    self.store = store
    self.currentDate = currentDate
  }
  
  func save(_ items: [FeedItem]) {
    store.deleteCachedFeed { [weak self] error in
      guard let `self` = self else { return }
      
      if error == nil {
        self.store.insert(items, timestamp: self.currentDate())
      }
    }
  }
}

final class CacheFeedUseCaseTests: XCTestCase {
  
  func test_init_doesNotMessageStoreUponCreation() {
    let (store, _) = makeSUT()
    
    XCTAssertEqual(store.receivedMessages, [])
  }
  
  func test_save_requestsCacheDeletion() {
    let (store, sut) = makeSUT()
    let items = [uniqueItem, uniqueItem]
    
    sut.save(items)
    
    XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
  }
  
  func test_save_doesNotRequestInsertionOnDeletionCacheError() {
    let (store, sut) = makeSUT()
    let items = [uniqueItem, uniqueItem]
    let deletionError = anyNSError()
    
    sut.save(items)
    store.complete(with: deletionError)
    
    XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
  }
  
  func test_save_requestsNewCacheInsertionWithTimestampOnSuccessfulDeletion() {
    let timestamp = Date()
    let (store, sut) = makeSUT(currentDate: { timestamp })
    let items = [uniqueItem, uniqueItem]
    
    sut.save(items)
    store.completeDeletionSuccessfully()
    
    XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed, .insert(items, timestamp)])
  }
  
  // MARK: - Helpers
  
  private func makeSUT(currentDate: @escaping (() -> Date) = Date.init,
                       file: StaticString = #file,
                       line: UInt = #line) -> (FeedStore, LocalFeedLoader) {
    let store = FeedStore()
    let sut = LocalFeedLoader(store: store, currentDate: currentDate)
    
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

