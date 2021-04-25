//
//  FeedStoreSpy.swift
//  EssentialFeedTests
//
//  Created by Gleb Cherkashyn on 25.04.2021.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import Foundation
import EssentialFeed

class FeedStoreSpy: FeedStore {
  enum ReceivedMessage: Equatable {
    case deleteCachedFeed
    case insert([LocalFeedImage], Date)
    case retrieve
  }
  
  private(set) var receivedMessages: [ReceivedMessage] = []
  
  private var deletionCompletions: [DeletionCompletion] = []
  private var insertionCompletions: [InsertionCompletion] = []
  private var retrievalCompletions: [RetrievalCompletion] = []
  
  func deleteCachedFeed(completion: @escaping DeletionCompletion) {
    deletionCompletions.append(completion)
    receivedMessages.append(.deleteCachedFeed)
  }
  
  func insert(_ feed: [LocalFeedImage],
              timestamp: Date,
              completion: @escaping InsertionCompletion) {
    receivedMessages.append(.insert(feed, timestamp))
    insertionCompletions.append(completion)
  }
  
  func retrieve(completion: @escaping RetrievalCompletion) {
    receivedMessages.append(.retrieve)
    retrievalCompletions.append(completion)
  }
  
  func completeDeletion(with error: Error, at index: Int = 0) {
    deletionCompletions[index](error)
  }
  
  func completeInsertion(with error: Error, at index: Int = 0) {
    deletionCompletions[index](error)
  }
  
  func completeRetrieval(with error: Error, at index: Int = 0) {
    retrievalCompletions[index](.failure(error))
  }
  
  func completeDeletionSuccessfully(at index: Int = 0) {
    deletionCompletions[index](nil)
  }
  
  func completeInsertionSuccessfully(at index: Int = 0) {
    insertionCompletions[index](nil)
  }
  
  func completeRetrievalWithEmptyCache(at index: Int = 0) {
    retrievalCompletions[index](.empty)
  }
  
  func completeRetrieval(with feed: [LocalFeedImage],
                         timestamp: Date,
                         at index: Int = 0) {
    retrievalCompletions[index](.found(feed: feed, timestamp: timestamp))
  }
}
