//
//  SplashVC.swift
//  Consensus
//
//  Created by Edward Arenberg on 4/28/18.
//  Copyright © 2018 Edward Arenberg. All rights reserved.
//

import UIKit
import OktaAuth
import OktaJWT
import Parse

class SplashVC: UIViewController {
    
    @IBOutlet weak var loginButton: UIButton! {
        didSet {
            loginButton.alpha = 0
            loginButton.layer.cornerRadius = 12
            loginButton.layer.masksToBounds = true
            loginButton.layer.borderColor = UIColor.lightGray.cgColor
            loginButton.layer.borderWidth = 2
        }
    }
    @IBAction func loginHit(_ sender: UIButton) {
        doLogin()
    }
    
    func extractTokenInfo(token:JSONWebToken) {
        AppDelegate.authUserIdent = token.payload["sub"] as? String
        AppDelegate.authUserName = token.payload["name"] as? String
        AppDelegate.authUserEmail = token.payload["preferred_username"] as? String
        AppDelegate.authUserAud = token.payload["aud"] as? String
    }
    
    func doLogin() {
        OktaAuth.tokens?.validationOptions["leeway"] = 10
        let login = OktaAuth.login()
        
        login.start(self)
            .then { manager in
                
                guard let at = manager.accessToken, let it = manager.idToken, let rt = manager.refreshToken else {
                    print("Missing Tokens")
                    return
                }
                
                if let jwt = try? JSONWebToken(string: it) {
                    print(jwt)
                    self.extractTokenInfo(token: jwt)
                }
                
                self.showApp()
                
            }
            .catch {
                error in print(error)
                /*
                if let e = error as? OktaError {
                    switch e {
                    case .JWTValidationError(let s):
                        self.doLogin()
                    default:
                        break
                    }
                }
                 */
        }
    }

    func showApp() {
        if let vc = storyboard?.instantiateViewController(withIdentifier: "MainNC") as? UINavigationController {
            view.window?.rootViewController = vc
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if OktaAuth.isAuthenticated() {
            if let it = tokens?.idToken {
                if let jwt = try? JSONWebToken(string: it) {
                    print(jwt)
                    self.extractTokenInfo(token: jwt)
                }
            }
            showApp()
        } else {
            UIView.animate(withDuration: 0.5, animations: { self.loginButton.alpha = 1 })
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
