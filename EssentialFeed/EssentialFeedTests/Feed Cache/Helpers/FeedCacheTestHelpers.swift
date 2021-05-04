//
//  FeedCacheTestHelpers.swift
//  EssentialFeedTests
//
//  Created by Gleb Cherkashyn on 04.05.2021.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import Foundation
import EssentialFeed

var uniqueFeedImage: FeedImage {
  FeedImage(id: UUID(), description: "any", location: nil, url: anyURL())
}

var uniqueImageFeed: (models: [FeedImage], local: [LocalFeedImage]) {
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

extension Date {
  func adding(days: Int) -> Date {
    Calendar.current.date(byAdding: .day, value: days, to: self)!
  }
  
  func adding(seconds: Int) -> Date {
    Calendar.current.date(byAdding: .second, value: seconds, to: self)!
  }
}
