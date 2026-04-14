//
//  Item.swift
//  EduAssistall
//
//  Created by Donald Clark on 4/14/26.
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
