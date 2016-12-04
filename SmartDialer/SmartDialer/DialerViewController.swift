//
//  ViewController.swift
//  SmartDialer
//
//  Created by Mihai Costiug on 03/12/2016.
//  Copyright © 2016 Mihai Costiug. All rights reserved.
//

import UIKit

class DialerViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var inputContainerBottomDistanceConstraint: NSLayoutConstraint!
    @IBOutlet weak var inputTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.inputTextField.becomeFirstResponder()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardNotification(notification:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
        
        super.viewWillDisappear(animated)
    }
    
    //MARK:- UITableViewDatasource
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "contactsCell")
        let contact = ContactsManager.sharedInstance.contacts[indexPath.row]
        
        cell.textLabel?.text = contact.name
        cell.detailTextLabel?.text = contact.phoneNumber
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ContactsManager.sharedInstance.contacts.count
    }
    
    //MARK:- UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // call contact
        self.inputTextField.resignFirstResponder()  //just for testing
        self.callNumber(phoneNumber: ContactsManager.sharedInstance.contacts[indexPath.row].phoneNumber)
    }
    
    //MARK:- Keyboard Actions
    
    func keyboardNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let endFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            let duration:TimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIViewAnimationOptions.curveEaseInOut.rawValue
            let animationCurve:UIViewAnimationOptions = UIViewAnimationOptions(rawValue: animationCurveRaw)
            
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
    
    //MARK:-  Utils
    
    private func callNumber(phoneNumber: String) {
        if let phoneCallURL: URL = URL(string: "tel://\(phoneNumber)") {
            if (UIApplication.shared.canOpenURL(phoneCallURL)) {
                UIApplication.shared.open(phoneCallURL, options: [:], completionHandler: { (success) in
                    
                });
            }
        }
    }
}

