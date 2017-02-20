//
//  ContactsManager.swift
//  SmartDialer
//
//  Created by Mihai Costiug on 03/12/2016.
//  Copyright © 2016 Mihai Costiug. All rights reserved.
//

import Contacts

class ContactsManager: NSObject {
    static let sharedInstance = ContactsManager()
    var contacts: [Contact] = []
    
    private override init() {
        super.init()
        
        self.fetchAllContacts()
    }
    
    //MARK:- Public
    
    func contactsWithMatchingString(searchTerm: String, completionBlock block: @escaping ([Contact]) -> ()) {
        DispatchQueue.global(qos: .background).async {
            //match searchTerm with characters
            //matching is be case insensitive
            
            var regex = "^"
            
            for digit in searchTerm.characters {
                let matches = self.possibleMatchedCharactersForDigit(digit: digit)
                
                if matches.count > 0 {
                    var digitValues = "["
                    
                    for match in matches {
                        digitValues += "\(match)"
                    }
                    digitValues += "]"
                    regex += digitValues
                } else {    //special characters
                    regex += "\\"   //this is always written twice; check how to avoid
                    //check if inserted character is a special one. if it's not, do NOT add an escape before it
                    regex += "\(digit)"
                }
            }
            
            var filteredContacts: [Contact] = []
            var filteredLowMatchContacts: [Contact] = []    //any contact that is not matched with displayName is a lower match
            
            for contact in self.contacts {
                // apply regex on each name
                let displayName = contact.displayName.replacingOccurrences(of: " ", with: "")   //if checking for the full display name, do not take into account the spaces
                
                if displayName =~ regex {
                    filteredContacts.append(contact)
                    continue
                }
                
                let names = [contact.givenName, contact.middleName, contact.familyName, contact.nickname]
                
                for name in names {
                    if name =~ regex {  //name matches regex
                        filteredLowMatchContacts.append(contact)
                        break
                    }
                }
                
                //if name is not matched, look inside the phone numbers; you can search by the search term with "contains"
            }
            
            filteredContacts.append(contentsOf: filteredLowMatchContacts)
            
            DispatchQueue.main.async {
                block(filteredContacts)
            }
        }
    }
    
    public func fetchAndGetContacts() -> [Contact] {
        self.fetchAllContacts()
        
        return self.contacts
    }
    
    //MARK:- Private
    
    private func fetchAllContacts() {
        if CNContactStore.authorizationStatus(for: .contacts) != CNAuthorizationStatus.authorized {
            return
        }
        
        let keysToFetch = [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactImageDataAvailableKey as CNKeyDescriptor,
            CNContactThumbnailImageDataKey as CNKeyDescriptor]
            as [CNKeyDescriptor]
        
        let contactStore = CNContactStore()
        let containerIdentifier = contactStore.defaultContainerIdentifier()
        let predicate = CNContact.predicateForContactsInContainer(withIdentifier: containerIdentifier)
        
        var cnContacts: [CNContact] = []
        
        do {
            let containerResults = try contactStore.unifiedContacts(matching: predicate, keysToFetch: keysToFetch)
            cnContacts.append(contentsOf: containerResults)
        } catch {
            return
        }
        
        var contacts: [Contact] = []
        
        for cnContact in cnContacts {
            let contact =  Contact(fromCNContact: cnContact)
            contacts.append(contact)
        }
        
        self.contacts = contacts.sorted(by: { (firstContact, secondContact) -> Bool in
            if firstContact.givenName != secondContact.givenName {
                return firstContact.givenName < secondContact.givenName
            }
            if firstContact.middleName != secondContact.middleName {
                return firstContact.middleName < secondContact.middleName
            }
            if firstContact.familyName != secondContact.familyName {
                return firstContact.familyName < secondContact.familyName
            }
            return firstContact.nickname < secondContact.nickname
        })
    }
    
    private func possibleMatchedCharactersForDigit(digit: Character) -> [Character] {
        switch digit {
        case "1":
            return ["1"]
        case "2":
            return ["2", "a", "A", "b", "B", "c", "C"]
        case "3":
            return ["3", "d", "D", "e", "E", "f", "F"]
        case "4":
            return ["4", "g", "G", "h", "H", "i", "I"]
        case "5":
            return ["5", "j", "J", "k", "K", "l", "L"]
        case "6":
            return ["6", "m", "M", "n", "N", "o", "O"]
        case "7":
            return ["7", "p", "P", "q", "Q", "r", "R", "s", "S"]
        case "8":
            return ["8", "t", "T", "u", "U", "v", "V"]
        case "9":
            return ["9", "w", "W", "x", "X", "y", "Y", "z", "Z"]
        case "0":
            return ["0", "+"]
        default:
            return []
        }
    }
}

infix operator =~
func =~(string: String, regex: String) -> Bool {
    return (string.range(of: regex, options: .regularExpression, range: nil, locale: nil) != nil)
}
