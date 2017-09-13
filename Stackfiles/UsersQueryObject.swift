//
//  UsersQueryObject.swift
//  Example
//
//  Created by Jeff Hanna on 6/17/17.
//  Copyright © 2017 Stackberry. All rights reserved.
//

import Foundation
import Stackberry

// note: this is a Stackfile, meaning it runs on the backend, 
// remember not to reference any other frontend code here
// you're free to use the Swift standard library, the Foundation Framework, 
// and your model classes (only stored properties!)
// Stackfiles can be used on the frontend too, adding to the code re-use and 
// symmetric behavior of your app

class UsersQueryObject:  QueryObject {
    
    // first we have to tell Stackberry what type of objects we're querying
    
    override class var berryClass: Berry.Type {
        return User.self
    }
    
    // next we have to tell Stackberry if a single object matches the query
    // the authId passed in will typically represent the user makng a request
    // you can use it to make user specific queries like "my" friends
    
    override func objectMatches(authId: String?, object: Berry) -> Bool {
        
        // we have the full flexibility of Swift to write advanced query logic
        // but in this case, all we need to do is make sure the object is a user
        
        return type(of: object) == User.self
        
    }
    
    override func allObjects(authId: String?) -> [Berry] {
        
        // for performance, we also need to provide a way to fetch all objects that 
        // match the query since Realm is not on the backend, use the objects 
        // method (similar to Realm.objects), this method will work on the backend
        // as well as the frontend
        
        return objects(User.self).all()
        
        // if we needed to, we could add filters or sorting here, 
        // but we're just going to fetch all users
        
    }
    
}
