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
     
        // create button
        
        let createButton = UIButton(type: .system)
        createButton.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        let inset: CGFloat  = 10
        createButton.contentEdgeInsets = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
        createButton.imageView?.contentMode = .scaleAspectFit
        createButton.setImage(#imageLiteral(resourceName: "create"), for: .normal)
        createButton.addTarget(self, action: #selector(didPressCreateButton), for: .touchUpInside)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: createButton)
        
        // table view
        
        tableView.dataSource = self
        tableView.register(UITableViewCell.self,
                           forCellReuseIdentifier: userCellReuseIdentifier)
        
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
    
    func didPressCreateButton() {
        
        // show alert view controller to create new user
        
        let alertController = UIAlertController(title: NSLocalizedString("Create User", comment: ""),
                                                message: NSLocalizedString("Enter the user's name", comment: ""),
                                                preferredStyle: .alert)
        
        // cancel action
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""),
                                         style: .cancel,
                                         handler: nil)
        alertController.addAction(cancelAction)
        
        // create action
        
        let createAction = UIAlertAction(title: NSLocalizedString("Create", comment: ""),
                                         style: .default) { _ in
                                          
                                            // create user locally, our realm notification block will handle the ui updates automatically!
                                            
                                            guard let textField = alertController.textFields?.first else {
                                                return
                                            }
                                            
                                            let user = User()
                                            user.name = textField.text ?? NSLocalizedString("No Name", comment: "")
                                            
                                            let realm = try! Realm()
                                            try! realm.write {
                                                realm.add(user)
                                            }
                                            
                                            // push to backend. It's really that simple
                                            
                                            Stackberry.push(user)
                                            
        }
        createAction.isEnabled = false
        alertController.addAction(createAction)
        
        // text field
        
        alertController.addTextField { textField in
            
            textField.placeholder = NSLocalizedString("Name", comment: "")
            textField.autocapitalizationType = .words
            
            NotificationCenter.default.addObserver(forName: .UITextFieldTextDidChange, object: textField, queue: .main) { _ in
                createAction.isEnabled = textField.text != ""
            }
            
        }
        
        present(alertController, animated: true, completion: nil)
        
    }
    
    func didPressDeleteButton(button: UIButton) {
        
        // get user by button tag
        
        let index = button.tag
        
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
        
        deleteButton.tag = indexPath.row
        deleteButton.addTarget(self, action: #selector(didPressDeleteButton), for: .touchUpInside)
        
        cell.accessoryView = deleteButton
        
        return cell
        
    }
    
}


