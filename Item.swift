//
//  Item.swift
//  Tchpnt
//
//  Created by Tanner Briggs on 1/3/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
