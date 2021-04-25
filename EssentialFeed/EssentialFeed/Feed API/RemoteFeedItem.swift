//
//  RemoteFeedItem.swift
//  EssentialFeed
//
//  Created by Gleb Cherkashyn on 25.04.2021.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import Foundation

struct RemoteFeedItem: Decodable {
  let id: UUID
  let description: String?
  let location: String?
  let image: URL
}
