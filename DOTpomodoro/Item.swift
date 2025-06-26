//
//  Item.swift
//  DOTpomodoro
//
//  Created by Sri Harsha on 26/06/25.
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
