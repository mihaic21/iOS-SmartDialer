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
        
        self.fetchContacts()
        //TODO: Default order of the contacts
    }
    
    //MARK:- Public
    
    func contactsWithMatchingString(searchTerm: String) -> [Contact] {
        // Perform search on background thread
        return []
    }
    
    func fetchContacts() {
        //TODO: Handle contacts permission inside this class
        if CNContactStore.authorizationStatus(for: .contacts) != CNAuthorizationStatus.authorized {
            let contactStore = CNContactStore()
            contactStore.requestAccess(for: .contacts, completionHandler: { (status, error) in
                self.fetchAllContacts()
            })
        } else {
            self.fetchAllContacts()
        }
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
}
