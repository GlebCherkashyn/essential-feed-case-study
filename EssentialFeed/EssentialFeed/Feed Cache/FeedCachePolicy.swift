//
//  FeedCachePolicy.swift
//  EssentialFeed
//
//  Created by Gleb Cherkashyn on 16.06.2021.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import Foundation

enum FeedCachePolicy {
	private static let calendar = Calendar.current
	private static var maxCacheAgeInDays = 7
		
	static func validate(_ timestamp: Date, against date: Date) -> Bool {
		guard let maxCacheAge = calendar.date(byAdding: .day, value: maxCacheAgeInDays, to: timestamp) else {
			return false
		}
		
		return date < maxCacheAge
	}
}
