//
//  SharedTestHelpers.swift
//  EssentialFeedTests
//
//  Created by Gleb Cherkashyn on 04.05.2021.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import Foundation

func anyNSError() -> NSError {
  return NSError(domain: "any error", code: 0)
}

func anyURL() -> URL {
  return URL(string: "http://any-url.com")!
}
