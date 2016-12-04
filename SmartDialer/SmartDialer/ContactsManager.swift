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
    
    func contactsWithMatchingString(searchTerm: String) -> [Contact] {
        
        
        return []
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
        
        for cnContact in cnContacts {
            let contact =  Contact(fromCNContact: cnContact)
            self.contacts.append(contact)
        }
    }
    
    //MARK:- Testing
    
    private func mockFetchContacts() {
        var contact = Contact(name: "name", phoneNumber: "081274")
        self.contacts.append(contact)
        
        contact = Contact(name: "name1", phoneNumber: "42131")
        self.contacts.append(contact)
        
        contact = Contact(name: "name2", phoneNumber: "21458")
        self.contacts.append(contact)
    }
}
