//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by Gleb Cherkashyn on 25.04.2021.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import Foundation

public protocol FeedStore {
  typealias DeletionCompletion = (Error?) -> ()
  typealias InsertionCompletion = (Error?) -> ()
  
  func deleteCachedFeed(completion: @escaping DeletionCompletion)
  func insert(_ items: [FeedItem],
              timestamp: Date,
              completion: @escaping InsertionCompletion)
}

public final class LocalFeedLoader {
  private let store: FeedStore
  private let currentDate: () -> Date
  
  public init(store: FeedStore, currentDate: @escaping () -> Date) {
    self.store = store
    self.currentDate = currentDate
  }
  
  public func save(_ items: [FeedItem], completion: @escaping (Error?) -> Void) {
    store.deleteCachedFeed { [weak self] error in
      guard let `self` = self else { return }
      
      if let error = error {
        completion(error)
        return
      }
      
      self.store.insert(
        items,
        timestamp: self.currentDate(),
        completion: completion
      )
    }
  }
}
