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
    
    private var contactsManager = ContactsManager()
    private var datasource: [Contact] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.inputTextField.becomeFirstResponder()
        self.loadContacts()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardNotification(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActiveNotification(notification:)), name: UIApplication.didBecomeActiveNotification, object: nil)
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
                    self.datasource = self.contactsManager.fetchAndGetContacts()
                    DispatchQueue.main.async {
                        self.contactsTableView.reloadData()
                    }
                }
            })
        } else {
            self.datasource = self.contactsManager.contacts
        }
    }
    
    //MARK:- UITableViewDatasource
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "contactsCell") as! ContactsTableViewCell
        let contact = self.datasource[indexPath.row]
        
        cell.contactImageView.image = contact.image ?? UIImage(named: kDefaultContactImageName)
        cell.nameLabel.text = contact.displayName
        
        if let phoneNumber = contact.orderedPhoneNumbers.first {
            var text = ""
            
            if phoneNumber.label.count > 0 {
                text += phoneNumber.label + ": "
            }
            text += phoneNumber.number
            cell.phoneLabel.text = text
        }
        cell.dateLabel.text = contact.lastCallDate?.formatted()
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.datasource.count
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        var rowActions: [UITableViewRowAction] = []
        var rowStyleAlternator = true
        
        for (label, number) in self.datasource[indexPath.row].orderedPhoneNumbers {
            let actionTitle = label.count > 0 ? label : number
            let rowAction = UITableViewRowAction(style: .normal, title: actionTitle, handler: { (_, _) in
                self.callNumber(phoneNumber: number)
            })
            if rowStyleAlternator {
                rowAction.backgroundEffect = UIVisualEffect()
            }
            rowStyleAlternator = !rowStyleAlternator
            
            rowActions.append(rowAction)
        }
        
        return rowActions
    }
    
    //MARK:- UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //TODO: Choose which number to call
        self.callNumber(phoneNumber: self.datasource[indexPath.row].orderedPhoneNumbers.first!.number)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.inputTextField.resignFirstResponder()
    }
    
    //MARK:- UITextFieldDelegate
    
    @IBAction func textFieldTextDidChanged(_ sender: UITextField) {
        if let searchTerm = sender.text {
            self.contactsManager.contactsWithMatchingString(searchTerm: searchTerm , completionBlock: { (contacts) in
                self.datasource = contacts
                self.contactsTableView.reloadData()
                self.contactsTableView.setContentOffset(CGPoint(), animated: true)
            })
        }
    }
    
    //MARK:- Notifications
    
    @objc func keyboardNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            let duration: TimeInterval = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIView.AnimationOptions.curveEaseInOut.rawValue
            let animationCurve: UIView.AnimationOptions = UIView.AnimationOptions(rawValue: animationCurveRaw)
            
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
    
    @objc func applicationDidBecomeActiveNotification(notification: NSNotification) {
        self.inputTextField.text = ""
        self.inputTextField.becomeFirstResponder()
        self.datasource = self.contactsManager.contacts
        self.contactsTableView.reloadData()
        self.contactsTableView.setContentOffset(CGPoint(), animated: true)
    }
    
    //MARK:- Actions
    
    @IBAction func callButtonPressed(_ sender: Any) {
        guard let phoneNumber = self.inputTextField.text else {
            return
        }
        
        if phoneNumber.count > 0 {
            if self.datasource.count == 1 {
                //TODO: choose appropriate phone number
                if let (_, contactNumber) = self.datasource.first!.orderedPhoneNumbers.first {
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
                    if success {
                        self.contactsManager.phoneNumberCalled(phoneNumber: phoneNumber)
                    }
                });
            }
        }
    }
    
    //MARK:- Utils
    
    private func stripPhoneNumber(phoneNumber: String) -> String {
        let pattern = "[^+0-9]"
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            
            return regex.stringByReplacingMatches(in: phoneNumber, options: .withTransparentBounds, range: NSRange(location: 0, length: phoneNumber.count), withTemplate: "")
        } catch {
            return ""
        }
    }
}

