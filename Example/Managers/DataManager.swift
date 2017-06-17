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
        
        try! realm.write {
            realm.deleteAll()
        }
        
        // delete user defaults (heads up! stackberry saves tokens in user defaults, so this will log you out)
        
        UserDefaults.resetStandardUserDefaults()
        
    }
    
    class func seedMobileAndCloudDatabases() {
        
        let realm = try! Realm()
        
        // let's create a few users
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        
        let jeff = User()
        jeff.name = "Jeff Hanna"
        jeff.birthday = dateFormatter.date(from: "02/04/1991")
        
        let dominic = User()
        dominic.name = "Dominic King"
        dominic.birthday = dateFormatter.date(from: "11/26/1989")
        
        let kevin = User()
        kevin.name = "Kevin Hanna"
        kevin.birthday = dateFormatter.date(from: "04/27/1990")
        
        // hm, these guys look familiar ;)
        
        // now we need to add them to the realm, our mobile database
        
        try! realm.write {
            
            realm.add([
                jeff,
                dominic,
                kevin
                ])
            
        }
        
        // alright, now lets send them to our stackberry backend
        
        Stackberry.push(jeff)
        Stackberry.push(dominic)
        Stackberry.push(kevin)
        
        // all done, now both our mobile and cloud databases have some initial data
        
    }
    
}
