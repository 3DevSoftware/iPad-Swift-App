//
//  LoginViewManager.swift
//  opportunity_express_client
//
//  Created by Miles Clark on 10/08/18.
//  Copyright (c) 2018 Eastern Labs. All rights reserved.
//

import Foundation
import UIKit

import Alamofire
import SwiftyJSON
import SAMKeychain

/// Static function that handles the displaying of an alert controller, which will allow
/// current user to login and mantain the state of their progress
struct LoginViewManager {
    
    // Blur view to hide any sensitive data
    fileprivate static var darkBlur = UIBlurEffect(style: UIBlurEffect.Style.dark)
    fileprivate static var blurView = UIVisualEffectView(effect: darkBlur)
    
    /**
        Attempt to refresh token by prompting current user for password and then logging.
        If the login fails or user does not wish to continue, they are redirected back to the home login page
        
        - parameter viewController: view controller (currently displaying) on which to present the AlertController
        - parameter errorMessage: optional error message provided by middle tier
        - parameter completion: optional callback function which will be passed the success of the login as a boolean
    */
    static func refreshToken(_ viewController: UIViewController, errorMessage:String?, completion:((_ loginSuccessful:Bool)->Void)? = nil) {
        
        
        // size blurView
        blurView.frame = viewController.view.bounds
        
        // add blur view to vc
        // note: will not cover tab or nav bars
        viewController.view.addSubview(blurView)
        
        // get the username of currently logged in user
        let user = LoginManager.getUserName() ?? ""
        
        // alert view that will display the message
        let alertController = UIAlertController(title: "Session Expired", message: (errorMessage ?? "Your user session has expired") + "\n Please reenter the password for:\n\(user)", preferredStyle: .alert)
        
        // action that will attempt to login
        let loginAction = UIAlertAction(title: "Login", style: .default, handler: { (_) in
            
            // get password from field
            let passwordTextField = alertController.textFields![0] 
            
            // Attempt to login user
            self.reLoginUser(alertController, viewController:viewController, userName: LoginManager.getUserName() ?? "", password: passwordTextField.text!, completion:completion)
        })
        
        // action that will return user to the login view
        let cancelAction = UIAlertAction(title: "Logout", style: .destructive, handler: { (action:UIAlertAction) in
            
            // login failed
            self.loginFail(viewController, completion: completion)
        })

        // Add text field to the login view
        alertController.addTextField { (textField) in
            textField.placeholder = "Password"
            textField.isSecureTextEntry = true
        }
        
        // Add actions
        alertController.addAction(loginAction)
        alertController.addAction(cancelAction)
        
        // present the action alert
        viewController.present(alertController, animated: true, completion: nil)
        
        
    }
    
    
    /**
        Attempts to login the user again through the API
    
        - parameter alertController: presented alert controller
        - parameter viewController: view controller on which the alert is being presented
        - parameter userName: user name (or email) of user to log in
        - parameter password: password entered in alert controller
        - parameter completion: optional callback function which will be passed the success of the login as a boolean
    */
    fileprivate static func reLoginUser(_ alertController: UIAlertController, viewController:UIViewController, userName:String, password:String, completion:((_ loginSuccessful:Bool)->Void)? = nil ) {
        
        let uuid = SAMKeychain.password(forService: "com.easternlabs.opportunity-express-client", account: "user")
        
        // Parameters to be passed to HTTP POST
        let parameters = [
            "username": userName,
            "password": password,
            "device_uuid": uuid!
        ]
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        let baseURL = LoginManager.getBaseURL()
        
       request(baseURL + "api/login/", method: .post, parameters: parameters, encoding: URLEncoding.default, headers: nil)
        
        
            .responseJSON { response in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                // If data is returned
                if let data = response.result.value {
                    
                    // create JSON object from raw data
                    var json = JSON(data)
                    
                    // get paylaod with json
                    let payload = json["payload"]
                    
                    // if user is authenticated
                    if let isAuthenticated = payload["is_authenticated"].bool, isAuthenticated {
                        
                        
                        // set cookies if authenticated
                        if let headerFields = response.response?.allHeaderFields as? [String: String], let URL = response.request?.url
                        {
                            // unpack the cookies coming from the web response
                           
                            
                            // set the cookies coming back from login on the Alamofire manager session cfg
                            
                        }
                        
                        // hide blur view
                        self.blurView.removeFromSuperview()
                        
                        // run callback if one exists
                        completion?(true)
                        
                        
                    } else {
                        
                        // if password is incorrect
                        if let errorMessage = json["error_message"].string, errorMessage == "Incorrect password" {
                            
                            // alert to notify user of incorrect password
                            let alertController = UIAlertController(title: "Error", message: (json["error_message"].string ?? "Unable to login user"), preferredStyle: .alert)
                            
                            // action to allow user to retry
                            let retry = UIAlertAction(title: "Retry", style: .cancel, handler: { (action:UIAlertAction!) in
                                
                                // recursively calls refreshToken, which will present a new alert
                                self.refreshToken(viewController, errorMessage: "Incorrect password.", completion: completion)
                            })
                            
                            alertController.addAction(retry)
                            
                            // present the alert
                            viewController.present(alertController, animated: true, completion: nil)
                            
                        }
                        // any other error
                        else {
                            
                            // alert to notify user of incorrect password
                            let alertController = UIAlertController(title: "Error", message: (json["error_message"].string ?? "Unable to login user"), preferredStyle: .alert)
                            
                            // action to logout user
                            let logoutAction = UIAlertAction(title: "Logout", style: .cancel, handler: { (action:UIAlertAction!) in
                                
                                self.loginFail(viewController, completion: completion)
                            })
                            
                            alertController.addAction(logoutAction)
                            
                            // present alert
                            viewController.present(alertController, animated: true, completion: nil)
                        }
                        
                    }
                    
                    
                } else {
                    
//                    // alert to notify user of incorrect password
//                    let alertController = UIAlertController(title: "Error", message: "Unable to login user", preferredStyle: .alert)
//                    
//                    // action to logout user
//                    let logoutAction = UIAlertAction(title: "Logout", style: .cancel, handler: { (action:UIAlertAction!) in
//                        
//                        self.loginFail(viewController, completion: completion)
//                    })
//                    
//                    alertController.addAction(logoutAction)
//                    
//                    // present alert
//                    viewController.present(alertController, animated: true, completion: nil)

                }
                
        }
    }
    
    /**
        Utility function that logs out user and transitions to main login view controller
        
        - parameter viewController: view controller to transition away from
        - parameter completion: callback function to run
    */
    fileprivate static func loginFail(_ viewController: UIViewController, completion: ((_ loginSuccessful:Bool)->Void)? = nil) {
        // Delete user data in LoginManager
        LoginManager.logOut()
        
        // run completion callback if provided
        completion?(false)
        
        // Get the loginVC and present it modally
        let loginVC = viewController.storyboard?.instantiateViewController(withIdentifier: "LogInVC") as! LogInViewController
        
        loginVC.view.backgroundColor = UIColor.white
        loginVC.view.alpha = 0.0
        
        loginVC.emailField.text = ""
        loginVC.passwordField.text = ""
        
        loginVC.logInView.isHidden = true
        
        // Animate in the login view controller
        viewController.present(loginVC, animated: false, completion: {() in
            // Zoom in view while changing the background color to blue
            let logInView = loginVC.logInView
            logInView?.animation = "zoomIn"
            logInView?.curve = "spring"
            logInView?.duration = 1.0
            
            // Complete animation
            logInView?.animate()
            
            UIView.animate(withDuration: 0.5, animations: {
                loginVC.view.backgroundColor = UIColor(hex: eb_primary_blue)},completion: nil)
                loginVC.view.alpha = 1.0
        })
    }
}
