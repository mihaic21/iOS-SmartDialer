//
//  ViewController.swift
//  SmartDialer
//
//  Created by Mihai Costiug on 03/12/2016.
//  Copyright © 2016 Mihai Costiug. All rights reserved.
//

import UIKit
import Contacts

let kDefaultContactImageName = "default_contact"

class DialerViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var inputContainerBottomDistanceConstraint: NSLayoutConstraint!
    @IBOutlet weak var inputTextField: UITextField!
    @IBOutlet weak var contactsTableView: UITableView!
    
    private var datasource: [Contact] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.inputTextField.becomeFirstResponder()
        self.loadContacts()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardNotification(notification:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
        
        super.viewWillDisappear(animated)
    }
    
    //MARK:- Contacts permissions
    
    private func loadContacts() {
        if CNContactStore.authorizationStatus(for: .contacts) != CNAuthorizationStatus.authorized {
            //TODO: show UI for contacts permissions
            
            let contactStore = CNContactStore()
            contactStore.requestAccess(for: .contacts, completionHandler: { (status, error) in
                if status {
                    //update UI
                    self.datasource = ContactsManager.sharedInstance.fetchAndGetContacts()
                    DispatchQueue.main.async {
                        self.contactsTableView.reloadData()
                    }
                }
            })
        } else {
            self.datasource = ContactsManager.sharedInstance.contacts
        }
    }
    
    //MARK:- UITableViewDatasource
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "contactsCell") as! ContactsTableViewCell
        let contact = self.datasource[indexPath.row]
        
        cell.contactImageView.image = contact.image ?? UIImage(named: kDefaultContactImageName)
        cell.nameLabel.text = contact.displayName
        cell.phoneLabel.text = contact.phoneNumbers.first
        cell.dateLabel.text = "15:24,\nToday"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.datasource.count
    }
    
    //MARK:- UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //TODO: Choose which number to call
        self.callNumber(phoneNumber: self.datasource[indexPath.row].phoneNumbers.first!)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.inputTextField.resignFirstResponder()
    }
    
    //MARK:- UITextFieldDelegate
    
    @IBAction func textFieldTextDidChanged(_ sender: UITextField) {
        if let searchTerm = sender.text {
            ContactsManager.sharedInstance.contactsWithMatchingString(searchTerm: searchTerm , completionBlock: { (contacts) in
                self.datasource = contacts
                self.contactsTableView.reloadData()
                self.contactsTableView.setContentOffset(CGPoint(), animated: true)
            })
        }
    }
    
    //MARK:- Keyboard Notifications
    
    func keyboardNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let endFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            let duration: TimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIViewAnimationOptions.curveEaseInOut.rawValue
            let animationCurve: UIViewAnimationOptions = UIViewAnimationOptions(rawValue: animationCurveRaw)
            
            if (endFrame?.origin.y)! >= UIScreen.main.bounds.size.height {
                self.inputContainerBottomDistanceConstraint.constant = 0
            } else {
                self.inputContainerBottomDistanceConstraint.constant = endFrame?.size.height ?? 0.0
            }
            UIView.animate(withDuration: duration,
                           delay: TimeInterval(0),
                           options: animationCurve,
                           animations: { self.view.layoutIfNeeded() },
                           completion: nil)
        }
    }
    
    //MARK:- Actions
    
    @IBAction func callButtonPressed(_ sender: Any) {
        guard let phoneNumber = self.inputTextField.text else {
            return
        }
        
        if phoneNumber.characters.count > 0 {
            if self.datasource.count == 1 {
                //TODO: choose appropriate phone number
                if let contactNumber = self.datasource.first!.phoneNumbers.first {
                    self.callNumber(phoneNumber: contactNumber)
                }
            } else {
                self.callNumber(phoneNumber: phoneNumber)
            }
        }
    }
    
    private func callNumber(phoneNumber: String) {
        if let phoneCallURL: URL = URL(string: "tel://\(self.stripPhoneNumber(phoneNumber: phoneNumber))") {
            if (UIApplication.shared.canOpenURL(phoneCallURL)) {
                UIApplication.shared.open(phoneCallURL, options: [:], completionHandler: { (success) in
                    RecentCallsManager.sharedInstance.incrementCounter(phoneNumber: phoneNumber)
                });
            }
        }
    }
    
    //MARK:- Utils
    
    private func stripPhoneNumber(phoneNumber: String) -> String {
        let pattern = "[^+0-9]"
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            
            return regex.stringByReplacingMatches(in: phoneNumber, options: .withTransparentBounds, range: NSRange(location: 0, length: phoneNumber.characters.count), withTemplate: "")
        } catch {
            return ""
        }
    }
}

