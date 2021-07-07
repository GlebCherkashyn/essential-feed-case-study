//
//  CodableFeedStore.swift
//  EssentialFeed
//
//  Created by Gleb Cherkashyn on 25.06.2021.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import Foundation

public final class CodableFeedStore: FeedStore {
	private struct Cache: Codable {
		
		let feed: [CodableFeedImage]
		let timestamp: Date
		
		var localFeed: [LocalFeedImage] {
			feed.map { $0.local }
		}
		
		init(_ feed: [CodableFeedImage], _ timestamp: Date) {
			self.feed = feed
			self.timestamp = timestamp
		}
	}
	
	private struct CodableFeedImage: Codable {
		let id: UUID
		let description: String?
		let location: String?
		let url: URL
		
		var local: LocalFeedImage {
			.init(id: id, description: description, location: location, url: url)
		}
		
		init(_ image: LocalFeedImage) {
			id = image.id
			description = image.description
			location = image.location
			url = image.url
		}
	}
	
	private let queue = DispatchQueue(label: "\(CodableFeedStore.self)Queue", qos: .userInitiated, attributes: .concurrent)
	private let storeURL: URL
	
	public init(storeURL: URL) {
		self.storeURL = storeURL
	}
	
	public func retrieve(completion: @escaping RetrievalCompletion) {
		let storeURL = self.storeURL
		queue.async {
			guard let data = try? Data(contentsOf: storeURL) else {
				return completion(.empty)
			}
			
			do {
				let decoder = JSONDecoder()
				let cache = try decoder.decode(Cache.self, from: data)
				completion(.found(feed: cache.localFeed, timestamp: cache.timestamp))
			} catch {
				completion(.failure(error))
			}
		}
	}
	
	public func insert(_ feed: [LocalFeedImage],
							timestamp: Date,
							completion: @escaping InsertionCompletion) {
		let storeURL = self.storeURL
		queue.async(flags: .barrier) {
			do {
				let encoder = JSONEncoder()
				let cache = Cache(feed.map(CodableFeedImage.init), timestamp)
				let encoded = try encoder.encode(cache)
				try encoded.write(to: storeURL)
				completion(nil)
			} catch {
				completion(error)
			}
		}
	}
	
	public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
		let storeURL = self.storeURL
		queue.async(flags: .barrier) {
			guard FileManager.default.fileExists(atPath: storeURL.path) else {
				return completion(nil)
			}
			
			do {
				try FileManager.default.removeItem(at: storeURL)
				completion(nil)
			} catch {
				completion(error)
			}
		}
	}
}
