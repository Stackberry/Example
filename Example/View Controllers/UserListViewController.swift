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
    
    // MARK: - constraints
    
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
        
        // now we can initiate the active sync
        
        activeSyncToken = Stackberry.activeSync(queryObject: usersQueryObject)
        
        // the active sync will continue as long as we retain the token (in this case 
        // for the lifetime of this view controller)
     
        // the combination of realm's notification block along with an active sync means
        // that our user interface will reflect the state of our cloud database in realtime
        
    }
    
    // MARK: - actions
    
    // MARK: - notification handlers

}

extension UserListViewController: UITableViewDataSource {
    
    func configureDataSource() {
        
        // our table view will show a list of all users
        
        // first lets fetch all users from our mobile database
        
        let realm = try! Realm()
        
        users = realm.objects(User.self).sorted(byKeyPath: #keyPath(User.birthday))
        
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
    
    // MARK: rows
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users?.count ?? 0
    }
    
    // MARK: - cells
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // dequeue the cell
        
        let cell = tableView.dequeueReusableCell(withIdentifier: userCellReuseIdentifier, for: indexPath)
        
        // configure
        
        cell.textLabel?.text = users?[indexPath.row].name
        
        return cell
        
    }
    
}


