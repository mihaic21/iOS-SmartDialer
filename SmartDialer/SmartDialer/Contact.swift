//
//  Contact.swift
//  SmartDialer
//
//  Created by Mihai Costiug on 03/12/2016.
//  Copyright © 2016 Mihai Costiug. All rights reserved.
//

import Contacts

class Contact: NSObject {
    private(set) var name: String
    private(set) var phoneNumber: String
    
    init(name: String, phoneNumber: String) {
        self.name = name
        self.phoneNumber = phoneNumber
        
        super.init()
    }
    
    init(fromCNContact cnContact: CNContact) {
        self.name = ""
        self.phoneNumber = ""
        
        let names = [cnContact.givenName, cnContact.middleName, cnContact.familyName]
        
        for name in names {
            self.name += "\(name) "
        }
        
        for label in cnContact.phoneNumbers {
            let number = label.value.stringValue
            
            if number.characters.count > 0 {
                self.phoneNumber = label.value.stringValue
                break
            }
        }
        
        super.init()
    }
}
