//
//  Contact.swift
//  SmartDialer
//
//  Created by Mihai Costiug on 03/12/2016.
//  Copyright © 2016 Mihai Costiug. All rights reserved.
//

import Contacts
import UIKit

class Contact: NSObject {
    private(set) var givenName: String
    private(set) var middleName: String
    private(set) var familyName: String
    private(set) var nickname: String
    private(set) var image: UIImage?
    
    public var lastCallDate: Date?
    public var callCount: Int = 0
    
    /// The phone numbers are ordered by last call date; the first element is the last one called.
    public var orderedPhoneNumbers: [(label: String, number: String)]
    
    var displayName: String {
        get {
            let names = [self.givenName, self.middleName, self.familyName]
            var finalName = ""
            
            for name in names {
                if name.characters.count > 0 {
                    finalName += "\(name) "
                }
            }
            
            if self.nickname.characters.count > 0 {
                finalName += "\"\(self.nickname)\""
            } else if finalName.characters.count > 0 {
                finalName.characters.removeLast()   //last character is a white space
            }
            
            return finalName
        }
    }
    
    init(fromCNContact cnContact: CNContact) {
        self.givenName = cnContact.givenName
        self.middleName = cnContact.middleName
        self.familyName = cnContact.familyName
        self.nickname = cnContact.nickname
        
        if let imageData = cnContact.thumbnailImageData {
            self.image = UIImage(data: imageData)
        }
        
        self.orderedPhoneNumbers = []
        
        for phoneNumber in cnContact.phoneNumbers {
            let number = phoneNumber.value.stringValue
            
            if number.characters.count > 0 {
                let label = CNLabeledValue<NSString>.localizedString(forLabel: phoneNumber.label ?? "")
                self.orderedPhoneNumbers.append((label, number))
            }
        }
        
        super.init()
    }    
}
