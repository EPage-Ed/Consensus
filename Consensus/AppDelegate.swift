//
//  AppDelegate.swift
//  Consensus
//
//  Created by Edward Arenberg on 4/28/18.
//  Copyright © 2018 Edward Arenberg. All rights reserved.
//

import UIKit
import Parse
import OktaAuth
import OktaJWT

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    static var authUserIdent : String?
    static var authUserName : String?
    static var authUserEmail : String?
    static var authUserAud : String?

    static func logout(callback:@escaping (Bool)->()) {
        if let token = OktaAuth.tokens?.accessToken {
            print(token)
            /*
            let options : [String:String] = [:]
            let validator = OktaJWTValidator(options)
            
            do {
                let valid = try validator.isValid(token)
                print(valid)
            }
            catch (let e) {
                print(e)
            }
             */
            
            let u = URL(string: "https://dev-718449.oktapreview.com/login/signout?fromURI=com.oktapreview.dev-718449")!
            let task = URLSession.shared.dataTask(with: u, completionHandler: { data, response, error in
                print(error)
                print(response)
                
                OktaAuth.revoke(token) { success, error in
                    //                guard let success = success else { return }
                    //                if success {
                    OktaAuth.clear()
                    
                    callback(true)
                    //                }
                }
            })
            task.resume()
            
        }
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let configuration = ParseClientConfiguration {
            $0.applicationId = "CSNPtB4AcRPU7JgeOYtrKyaMCaCiZJGOelYxOx6S"
            $0.clientKey = "NjUpPe8KHSMMAXcrXcPb4vemESxlQGFcf4oooCsH"
            $0.server = "https://parseapi.back4app.com"
        }
        Parse.initialize(with: configuration)
        saveInstallationObject()
        
        CUser.logInWithUsername(inBackground: "Consensus", password: "susnesnoC", block: { user, error in
            print(error)
            print(user)
        })
        
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

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        return OktaAuth.resume(url, options: options)
//        return OktaAuth.resume(url: url, options: options)
    }
    
    func saveInstallationObject(){
        if let installation = PFInstallation.current(){
            installation.saveInBackground {
                (success: Bool, error: Error?) in
                if (success) {
                    print("You have successfully connected your app to Back4App!")
                } else {
                    if let myError = error{
                        print(myError.localizedDescription)
                    }else{
                        print("Uknown error")
                    }
                }
            }
        }
    }

}

