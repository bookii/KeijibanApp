//
//  Item.swift
//  KeijibanApp
//
//  Created by Tsubasa YABUKI on 2025/12/23.
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
