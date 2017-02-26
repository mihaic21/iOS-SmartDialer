//
//  Date+Additions.swift
//  SmartDialer
//
//  Created by Mihai Costiug on 21/02/2017.
//  Copyright © 2017 Mihai Costiug. All rights reserved.
//

import Foundation

let kNumberOfDaysForCallToBeRecent = 3
let kNumberOfDaysInAWeek = 7

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
        } else if self.isThisWeek() {
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
    
    /// Decides whether or not the date is considered recent. A date is recent if the number of days that have passed since is less than
    ///
    /// - Returns: true is date is recent, false otherwise
    public func isRecent() -> Bool {
        return !self.isMoreThanDaysAgo(days: kNumberOfDaysForCallToBeRecent)
    }
    
    public func isThisWeek() -> Bool {
        return !self.isMoreThanDaysAgo(days: kNumberOfDaysInAWeek)
    }
    
    private func isMoreThanDaysAgo(days: Int) -> Bool {
        let components = Calendar.current.dateComponents([.day], from: self, to: Date())
        
        return components.day! >= days
    }
}
