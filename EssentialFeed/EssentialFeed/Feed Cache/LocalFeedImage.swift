//
//  LocalFeedImage.swift
//  EssentialFeed
//
//  Created by Gleb Cherkashyn on 25.04.2021.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import Foundation

public struct LocalFeedImage: Equatable, Codable {
  public let id: UUID
  public let description: String?
  public let location: String?
  public let url: URL
  
  public init(id: UUID, description: String?, location: String?, url: URL) {
    self.id = id
    self.description = description
    self.location = location
    self.url = url
  }
}
