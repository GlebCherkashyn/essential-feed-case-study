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
  public typealias LoadResult = LoadFeedResult
  
  private let store: FeedStore
  private let currentDate: () -> Date
  private let calendar = Calendar.current
  private var maxCacheAgeInDays = 7
  
  public init(store: FeedStore, currentDate: @escaping () -> Date) {
    self.store = store
    self.currentDate = currentDate
  }
  
  public func save(_ feed: [FeedImage], completion: @escaping (StoreResult) -> Void) {
    store.deleteCachedFeed { [weak self] error in
      guard let `self` = self else { return }
      
      if let error = error {
        completion(error)
        return
      }
      
      self.store.insert(
        feed.toLocal(),
        timestamp: self.currentDate(),
        completion: completion
      )
    }
  }
  
  public func load(completion: @escaping (LoadResult) -> Void) {
    store.retrieve { [weak self] result in
      guard let `self` = self else { return }
      
      switch result {
      case let .failure(error):
        self.store.deleteCachedFeed { _ in }
        completion(.failure(error))
        
      case let .found(feed, timestamp) where self.validate(timestamp):
        completion(.success(feed.toModels()))
        
      case .empty, .found:
        completion(.success([]))
      }
    }
  }
  
  private func validate(_ timestamp: Date) -> Bool {
    guard let maxCacheAge = calendar.date(byAdding: .day, value: maxCacheAgeInDays, to: timestamp) else {
      return false
    }
    
    return currentDate() < maxCacheAge
  }
}

// MARK: - Helpers

private extension Array where Element == FeedImage {
  func toLocal() -> [LocalFeedImage] {
    map { LocalFeedImage(
      id: $0.id,
      description: $0.description,
      location: $0.location,
      url: $0.url
    )}
  }
}

private extension Array where Element == LocalFeedImage {
  func toModels() -> [FeedImage] {
    map { FeedImage(
      id: $0.id,
      description: $0.description,
      location: $0.location,
      url: $0.url
    )}
  }
}
