//
//  FeedStore.swift
//  EssentialFeed
//
//  Created by Gleb Cherkashyn on 25.04.2021.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import Foundation

public protocol FeedStore {
  typealias DeletionCompletion = (Error?) -> ()
  typealias InsertionCompletion = (Error?) -> ()
  typealias RetrievalCompletion = (Error?) -> ()
  
  func deleteCachedFeed(completion: @escaping DeletionCompletion)
  
  func insert(_ feed: [LocalFeedImage],
              timestamp: Date,
              completion: @escaping InsertionCompletion)
  
  func retrieve(completion: @escaping RetrievalCompletion)
}
