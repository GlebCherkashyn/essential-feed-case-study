//
//  CoreDataFeedStore.swift
//  EssentialFeed
//
//  Created by Gleb Cherkashyn on 09.07.2021.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import Foundation

public final class CoreDataFeedStore: FeedStore {
	public init() {}

	public func retrieve(completion: @escaping RetrievalCompletion) {
		completion(.empty)
	}

	public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {

	}

	public func deleteCachedFeed(completion: @escaping DeletionCompletion) {

	}
}
