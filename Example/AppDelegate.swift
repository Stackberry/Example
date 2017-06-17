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

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

