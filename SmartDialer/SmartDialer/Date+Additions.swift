//
//  Date+Additions.swift
//  SmartDialer
//
//  Created by Mihai Costiug on 21/02/2017.
//  Copyright © 2017 Mihai Costiug. All rights reserved.
//

import Foundation

extension Date {
    public func formatted() -> String {
        if self.isToday() {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm"
            
            return dateFormatter.string(from: self)
        } else if self.isYesterday() {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm"
            
            return dateFormatter.string(from: self) + ",\nYesterday"
        } else if !self.isMoreThanDaysAgo(days: kNumberOfDaysForCallToCount) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm,\nEEEE"
            
            return dateFormatter.string(from: self)
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm,\ndd MMM yyyy"
            
            return dateFormatter.string(from: self)
        }
    }
    
    public func isToday() -> Bool {
        return Calendar.current.isDateInToday(self)
    }
    
    public func isYesterday() -> Bool {
        return Calendar.current.isDateInYesterday(self)
    }
    
    public func isMoreThanDaysAgo(days: Int) -> Bool {
        let calendar = Calendar.current
        let finalDays = calendar.component(.day, from: self)
        
        return finalDays <= days
    }
}
