//
//  DataManager.swift
//  Example
//
//  Created by Jeff Hanna on 6/17/17.
//  Copyright © 2017 Stackberry. All rights reserved.
//

import Foundation
import RealmSwift
import Stackberry

class DataManager {
    
    class func deleteLocalData() {
        
        // delete realm data
        
        let realm = try! Realm()
        let users = realm.objects(User.self)
        
        try! realm.write {
            realm.delete(users)
        }
        
        // delete user defaults (heads up! stackberry saves tokens in user defaults, so this will log you out)
        
        UserDefaults.resetStandardUserDefaults()
        
    }
    
    class func seedMobileAndCloudDatabases() {
        
        let realm = try! Realm()
        
        // let's create a few users
        
        var users: [User] = []
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        
        let jeff = User()
        jeff.name = "Jeff Hanna"
        jeff.birthday = dateFormatter.date(from: "02/04/1991")
        users.append(jeff)
        
        let dominic = User()
        dominic.name = "Dominic King"
        dominic.birthday = dateFormatter.date(from: "11/26/1989")
        users.append(dominic)
        
        let kevin = User()
        kevin.name = "Kevin Hanna"
        kevin.birthday = dateFormatter.date(from: "04/27/1990")
        users.append(kevin)
        
        // hm, these guys look familiar ;)
        
        // now we need to add them to the realm, our mobile database
        
        try! realm.write {
            realm.add(users)
        }
        
        // alright, now lets send them to our stackberry backend
        
        Stackberry.batchPush(users)
        
        // all done, now both our mobile and cloud databases have some initial data
        
    }
    
}
