//
//  UserListViewController.swift
//  Example
//
//  Created by Jeff Hanna on 6/17/17.
//  Copyright © 2017 Stackberry. All rights reserved.
//

import UIKit
import RealmSwift
import Stackberry

class UserListViewController: UIViewController {

    // MARK: - ui elements
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var createUserView: UIView!
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var createUserButton: UIButton!
    
    // MARK: - constraints
    
    @IBOutlet weak var createUserViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var separatorViewHeightConstraint: NSLayoutConstraint!
    
    // MARK: - properties
    
    var users: Results<User>?
    var realmNotificationToken: NotificationToken?
    var activeSyncToken: ActiveSyncToken?
    let userCellReuseIdentifier = "userCell"
    
    // MARK: - init
    
    convenience init() {
        
        let type = type(of: self)
        let className = String(describing: type)
        let bundle = Bundle(for: type)
        self.init(nibName: className, bundle: bundle)
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - view lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
     
        // table view
        
        tableView.dataSource = self
        tableView.rowHeight = 50
        tableView.register(UITableViewCell.self,
                           forCellReuseIdentifier: userCellReuseIdentifier)
        
        // create user view
        
        // separator view
        
        separatorViewHeightConstraint.constant = 1.0/UIScreen.main.scale // 1 pixel
        
        // user name text field
        
        userNameTextField.placeholder = NSLocalizedString("User Name", comment: "")
        userNameTextField.addTarget(self, action: #selector(userNameTextFieldDidChange), for: .editingChanged)
        
        // create user button
        
        createUserButton.imageView?.contentMode = .scaleAspectFit
        let inset: CGFloat = 6
        createUserButton.contentEdgeInsets = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
        
        // register for notifications
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        
        // data source
        
        configureDataSource()
        
        // active sync
        
        configureActiveSync()
        
    }
    
    // MARK: - methods
    
    func configureActiveSync() {
        
        // first we need to setup a query object
        // our query object doesn't take in any parameters
        
        let usersQueryObject = UsersQueryObject()
        
        // the query object needs to be added to the realm
        
        let realm = try! Realm()
        try! realm.write {
            realm.add(usersQueryObject)
        }
        
        // now we can initiate the active sync
        
        activeSyncToken = Stackberry.activeSync(queryObject: usersQueryObject, deleteUnmatchedLocal: true)
        
        // the active sync will continue as long as we retain the token (in this case 
        // for the lifetime of this view controller)
     
        // the combination of Realm's notification block along with an active sync means
        // that our user interface will reflect the state of our cloud database in realtime
        
    }
    
    // MARK: - actions
    
    func userNameTextFieldDidChange() {
        createUserButton.isEnabled = userNameTextField.text?.isEmpty == false
    }
    
    @IBAction func didPressCreateUserButton() {
        
        let user = User()
        user.name = userNameTextField.text ?? NSLocalizedString("No Name", comment: "")
        
        let realm = try! Realm()
        try! realm.write {
            realm.add(user)
        }
        
        // push to backend. It's really that simple
        
        Stackberry.push(user)
        
        // clear text
        
        userNameTextField.text = nil
        createUserButton.isEnabled = false
        
    }
    
    func didPressDeleteButton(button: UIButton) {
        
        // get index path of cell
        
        let point = tableView.convert(button.center, from: button.superview)
        
        guard let indexPath = tableView.indexPathForRow(at: point) else {
            return
        }
        
        let index = indexPath.row
        
        guard let users = users,
            index < users.count else {
                return
        }
        
        let user = users[index]
        
        // delete user from backend, yes it's that easy
        
        Stackberry.delete(user)
        
        // delete user locally, our realm notification block will handle the ui updates automatically!
        
        let realm = try! Realm()
        try! realm.write {
            realm.delete(user)
        }
        
    }
    
    // MARK: - notification handlers
    
    func keyboardWillChangeFrame(notification: NSNotification) {
        
        guard UIApplication.shared.applicationState != .background else {
            return
        }
        
        guard let info = notification.userInfo as? [String: AnyObject],
            let frameEndValue = info[UIKeyboardFrameEndUserInfoKey] as? NSValue,
            let durationNumber = info[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber,
            let curveNumber = info[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber
            else {
                return
        }
        
        let frameEndRect = view.convert(frameEndValue.cgRectValue, from: nil)
        let duration = durationNumber.doubleValue as TimeInterval
        let options = UIViewAnimationOptions(rawValue: UInt(curveNumber.intValue << 16))
        
        // update layout
        
        view.setNeedsLayout()
        view.layoutIfNeeded()
        
        // update constraints
        
        if frameEndRect.origin.y == view.bounds.size.height {
            
            // keyboard will hide
            
            createUserViewBottomConstraint.constant = 0
            
        } else {
            
            createUserViewBottomConstraint.constant = 0 + frameEndRect.height
            
        }
        
        // animate layout change
        
        UIView.animate(withDuration: duration,
                       delay: 0,
                       options: options,
                       animations: {
                        self.view.layoutIfNeeded()
        },
                       completion: nil)
        
    }

}

extension UserListViewController: UITableViewDataSource {
    
    func configureDataSource() {
        
        // our table view will show a list of all users
        
        // first lets fetch all users from our mobile database
        
        let realm = try! Realm()
        
        users = realm.objects(User.self).sorted(byKeyPath: #keyPath(User.name))
        
        // now lets setup a notification block so our UI can refresh if the mobile database changes
        // realm makes this incredibly easy
        
        realmNotificationToken = users?.addNotificationBlock({ [weak self] changes in
            
            switch changes {
            case .initial(_):
                
                break
                
            case .update(_, let deletions, let insertions, let modifications):
                
                // animate updates
                
                self?.tableView.beginUpdates()
                
                // note: always make updates in this order to avoid internal inconsistency exceptions
                
                // delete
                
                self?.tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) }, with: .fade)
                
                // insert
                
                self?.tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) }, with: .top)
                
                // modify
                
                self?.tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: 0) }, with: .none)
                
                self?.tableView.endUpdates()
                
                // scroll to new cells
                
                if let maxIndex = insertions.max(){
                   
                    let indexPath = IndexPath(row: maxIndex, section: 0)
                    self?.tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
                    
                }
                
                
            case .error(let err):
                fatalError("\(err)")
            }
            
        })
        
        // reload the table
        
        tableView.reloadData()
        
    }
    
    // MARK: - rows
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users?.count ?? 0
    }
    
    // MARK: - cells
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // dequeue the cell
        
        let cell = tableView.dequeueReusableCell(withIdentifier: userCellReuseIdentifier, for: indexPath)
        
        // title
        
        cell.textLabel?.text = users?[indexPath.row].name
        
        // delete button
        
        let deleteButton = UIButton(type: .system)
        deleteButton.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        let inset: CGFloat = 10
        deleteButton.contentEdgeInsets = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
        deleteButton.imageView?.contentMode = .scaleAspectFit
        deleteButton.setImage(#imageLiteral(resourceName: "delete"), for: .normal)
        
        deleteButton.addTarget(self, action: #selector(didPressDeleteButton), for: .touchUpInside)
        
        cell.accessoryView = deleteButton
        
        return cell
        
    }
    
}

