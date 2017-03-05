//
//  ContactsManager.swift
//  SmartDialer
//
//  Created by Mihai Costiug on 03/12/2016.
//  Copyright © 2016 Mihai Costiug. All rights reserved.
//

import Contacts

class ContactsManager: NSObject {
    var contacts: [Contact] = []
    private var recentCallsManager = RecentCallsManager.sharedInstance
    
    override init() {
        super.init()
        
        self.fetchAllContacts()
    }
    
    //MARK:- Public
    
    func contactsWithMatchingString(searchTerm: String, completionBlock block: @escaping ([Contact]) -> ()) {
        if searchTerm == "" {
            block(self.contacts)
            
            return
        }
        
        DispatchQueue.global(qos: .background).sync {
            //match searchTerm with characters
            
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
                
                //TODO: Look inside phone numbers
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
    
    public func phoneNumberCalled(phoneNumber: String) {
        let date = Date()
        self.recentCallsManager.incrementCounterFor(phoneNumber: phoneNumber, withDate: date)
        //update local arrays
        for contact in self.contacts {
            if contact.orderedPhoneNumbers.contains(where: { (_, number) -> Bool in
                if number == phoneNumber {
                    return true
                } else {
                    return false
                }
            }) {
                contact.callCount += 1
                contact.lastCallDate = date
                
                break
            }
        }
        self.sortContacts()
    }
    
    //MARK:- Private
    
    private func fetchAllContacts() {
        if CNContactStore.authorizationStatus(for: .contacts) != CNAuthorizationStatus.authorized {
            return
        }
        
        DispatchQueue.global(qos: .background).sync {
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
            
            for cnContact in cnContacts {
                let contact = Contact(fromCNContact: cnContact)
                var totalCallsCounter = 0
                var phoneNumbersWithDate: [(label: String, number: String, date: Date?)] = []
                
                for (label, number) in contact.orderedPhoneNumbers {
                    let information = self.recentCallsManager.callCountAndLastDateFor(phoneNumber: number)
                    totalCallsCounter += information.callCount
                    
                    if let date = contact.lastCallDate {
                        if let lastCallDate = information.lastCallDate {
                            if date < lastCallDate {
                                contact.lastCallDate = lastCallDate
                            }
                        }
                    } else {
                        contact.lastCallDate = information.lastCallDate
                    }
                    phoneNumbersWithDate.append((label, number, information.lastCallDate))
                }
                contact.callCount = totalCallsCounter
                contact.orderedPhoneNumbers = self.orderPhoneNumbersBasedOnDate(numbers: phoneNumbersWithDate)
                
                self.contacts.append(contact)
            }
            
            self.sortContacts()
        }
    }
    
    private func sortContacts() {
        self.contacts = self.contacts.sorted(by: { (firstContact, secondContact) -> Bool in
            if firstContact.lastCallDate != nil || secondContact.lastCallDate != nil {
                if let firstDate = firstContact.lastCallDate,
                    let secondDate = secondContact.lastCallDate {
                    
                    if firstDate.isRecent() {
                        if secondDate.isRecent() {
                            //both dates are considered recent
                            return self.sortOrderBasedOnDate(date1: firstContact.lastCallDate, date2: secondContact.lastCallDate)
                        } else {
                            return true
                        }
                    } else {
                        if secondDate.isRecent() {
                            return false
                        }
                    }
                }
            }
            if firstContact.callCount != secondContact.callCount {
                return firstContact.callCount > secondContact.callCount
            }
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
    
    //MARK: Utils
    
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
    
    private func sortOrderBasedOnDate(date1: Date?, date2: Date?) -> Bool {
        if let secondDate = date2 {
            if let firstDate = date1 {
                return firstDate > secondDate
            } else {
                return false
            }
        } else if date1 != nil {
            return true
        } else {
            return false
        }
    }
    
    private func orderPhoneNumbersBasedOnDate(numbers: [(label: String, number: String, date: Date?)]) -> [(label: String, number: String)] {
        let orderedResults = numbers.sorted { (first, second) -> Bool in
            return self.sortOrderBasedOnDate(date1: first.date, date2: second.date)
        }
        
        var orderedNumbers: [(label: String, number: String)] = []
        
        for (label, number, _) in orderedResults {
            orderedNumbers.append((label, number))
        }
        
        return orderedNumbers
    }
}

infix operator =~
func =~(string: String, regex: String) -> Bool {
    return (string.range(of: regex, options: .regularExpression, range: nil, locale: nil) != nil)
}
