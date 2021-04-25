//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by Gleb Cherkashyn on 25.04.2021.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import Foundation

public final class LocalFeedLoader {
  public typealias StoreResult = Error?
  
  private let store: FeedStore
  private let currentDate: () -> Date
  
  public init(store: FeedStore, currentDate: @escaping () -> Date) {
    self.store = store
    self.currentDate = currentDate
  }
  
  public func save(_ items: [FeedItem], completion: @escaping (StoreResult) -> Void) {
    store.deleteCachedFeed { [weak self] error in
      guard let `self` = self else { return }
      
      if let error = error {
        completion(error)
        return
      }
      
      self.store.insert(
        items.toLocal(),
        timestamp: self.currentDate(),
        completion: completion
      )
    }
  }
}

// MARK: - Helpers

private extension Array where Element == FeedItem {
  func toLocal() -> [LocalFeedItem] {
    map { LocalFeedItem(
      id: $0.id,
      description: $0.description,
      location: $0.location,
      imageURL: $0.imageURL
    )}
  }
}
