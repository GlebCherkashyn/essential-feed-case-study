//
//  FeedStore.swift
//  EssentialFeed
//
//  Created by Gleb Cherkashyn on 25.04.2021.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import Foundation

public enum RetrieveCacheFeedResult {
  case empty
  case found(feed: [LocalFeedImage], timestamp: Date)
  case failure(Error)
}

public protocol FeedStore {
  typealias DeletionCompletion = (Error?) -> ()
  typealias InsertionCompletion = (Error?) -> ()
  typealias RetrievalCompletion = (RetrieveCacheFeedResult) -> ()
  
	/// The completion handler can be invoked in any thread.
	/// Clients are responsible to dispatch to appropriate threads, if needed.
  func deleteCachedFeed(completion: @escaping DeletionCompletion)
  
	/// The completion handler can be invoked in any thread.
	/// Clients are responsible to dispatch to appropriate threads, if needed.
  func insert(_ feed: [LocalFeedImage],
              timestamp: Date,
              completion: @escaping InsertionCompletion)
  
	/// The completion handler can be invoked in any thread.
	/// Clients are responsible to dispatch to appropriate threads, if needed.
  func retrieve(completion: @escaping RetrievalCompletion)
}
