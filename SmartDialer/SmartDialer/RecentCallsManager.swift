//
//  RecentCallsManager.swift
//  SmartDialer
//
//  Created by Mihai Costiug on 20/02/2017.
//  Copyright © 2017 Mihai Costiug. All rights reserved.
//

import Foundation
import CoreData

/// This class should persistently keep track of all the calls initiated from within the app and provide a total number of calls for each individual phone number.
class RecentCallsManager: NSObject {
    static let sharedInstance = RecentCallsManager()
    
    private var callCounters: [NSManagedObject] = []
    
    private override init() {
        super.init()
        
        self.fetchAllCallCounters()
    }
    
    //MARK:- Public
    
    public func incrementCounter(phoneNumber: String) {
        
    }
    
    //MARK:- Private
    
    private func fetchAllCallCounters() {
        
    }
    
}
