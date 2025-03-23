//
//  Utils.swift
//  DeviceValueApp
//
//  Created by Ibrahim Koteish on 16/2/25.
//

import Foundation

public extension Date {
    init(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0, second: Int = 0) {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second
        
        if let date = Calendar.current.date(from: components) {
            self = date
        } else {
            self = Date() // Fallback to current date if initialization fails
        }
    }
}
