//
//  AppDelegate.swift
//  Example
//
//  Created by Jeff Hanna on 6/17/17.
//  Copyright © 2017 Stackberry. All rights reserved.
//

import UIKit
import Stackberry

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        Stackberry.initialize(appKey: "put your App Key here in quotes",
                              appSecret: "put your App Secret here in quotes",
                              environment: .development,
                              options: [.deployOnNewSchema]) { (status) in
                                
                                switch status {
                                case .firstDeploy, .deployedOnNewSchema, .forceRedeploy:
                                    
                                    // in all three of these cases we just got a freshly deployed backend
                                    // since our backend doesn't have any data, we probably want our frotend in the same state
                                    
                                    DataManager.deleteLocalData()
                                    
                                    // now would be a great time to seed your mobile and cloud databases with some initial data
                                    
                                    DataManager.seedMobileAndCloudDatabases()
                                    
                                case .unchanged:
                                
                                    // your local schema matches the schema on your current backend, so you're all set to go!
                                    
                                    break
                                    
                                case .invalidSchema:
                                    
                                    // whoops, looks like your local schema doesn't match the schema on your backend
                                    // if you're in development, you can use the option .deployOnNewSchema to have
                                    // stackberry destroy and rebuild your backend with the new schema when one is detected
                                    
                                    break
                                    
                                case .deploymentFailed:
                                    
                                    // uh oh, something went wrong. Check the logs for errors and let us know what happend on Slack or Github
                                    
                                    break
                                    
                                }
                                
        }
        
        return true
    }

}

