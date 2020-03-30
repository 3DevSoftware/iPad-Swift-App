//
//  LoginManager.swift
//  opportunity_express_client
//
//  Created by Miles Clark on 10/08/18.
//  Copyright (c) 2018 Eastern Labs. All rights reserved.
//

import Foundation
import Alamofire
import UIKit
import SwiftyJSON
import Reachability
import Spring
enum expressEnv {
    case prod
    case staging
}


/// Singleton for handling saving and deleting data during login and logout
struct LoginManager {
    
    // User defaults instance that persists throughout the application
    // Used for storing data
    fileprivate static let userDefaults = UserDefaults.standard
    
    #if DEBUG_BUILD && USE_LOCAL_SERVER
    private static var kExpressBaseUrl: String = "https://acme1-customer.ngtcloud.com/" //"http://localhost:8000/"
    #else
    fileprivate static var kExpressBaseUrl: String = "https://acme1-customer.ngtcloud.com/"
    #endif
    
    fileprivate static var express_environment: expressEnv = .prod
    
    static func setEnvironment(_ env: expressEnv) -> Void {
        
        switch env {
        case .prod:
            express_environment = env
//            #if DEBUG_BUILD && USE_LOCAL_SERVER
//            kExpressBaseUrl = "http://localhost:8000/"
//            #else
            kExpressBaseUrl = "https://acme1-customer.ngtcloud.com/"
//            #endif
        case .staging:
            express_environment = env
            kExpressBaseUrl = "https://acme1-customer.ngtcloud.com/"
        }
        
    }
    
    // getter for the baseURL
    static func getBaseURL() -> String {
        return kExpressBaseUrl
    }
    
    // getter for the current environment
    static func getEnvironment() -> expressEnv {
        return express_environment
    }
    
    
    /**
     Logs in a user saving appropriate data to NSUserDefaults
     
     - parameter id: id given by database
     - parameter userName: username or email
     - parameter bankerName: banker's full name
     */
    static func logIn(_ userName: String, bankerName: String, leadURL: String) {
        saveUserName(userName)
        saveBankerName(bankerName)
        saveLeadURL(leadURL)
    }
    
    
    /**
     Logs out current banker, deleting locally stored data as well as calling the logout api
     */
    static func logOut() {
        
        let baseURL = LoginManager.getBaseURL()
        
        // TODO: logout via cookie instead of user-token?
        // if id and token are found, call url to logout user with id and token
        
        request(baseURL + "api/logout-device-user/", method: .post, parameters: nil, encoding: URLEncoding.default, headers: nil)
            .responseJSON {
                
                response in
                
                // we don't need to parse the status code of logging out becauase we clear data on the iPad
                
                // Delete fields locally
                deleteUserName()
                deleteBankerName()
                deleteLeadURL()
        }
        
        // delete all cookies on logout
        
        
    }
    
    
    /**
     Save userName (or Email) to local data
     
     - parameter userName: userName to save
     */
    static func saveUserName(_ userName: String) {
        userDefaults.set(userName, forKey: "userName")
    }
    
    
    /**
     Gets userName from NSUserDefaults if it exists
     
     - returns: Optional String containing userName if it exists
     */
    static func getUserName() -> String? {
        return userDefaults.string(forKey: "userName")
    }
    
    
    /**
     Deletes userName from local data
     */
    static func deleteUserName() {
        userDefaults.removeObject(forKey: "userName")
    }
    
    
    /**
     Save banker's full name to local data
     
     - parameter bankerName: banker's full name to save
     */
    static func saveBankerName(_ bankerName: String) {
        userDefaults.set(bankerName, forKey: "bankerName")
    }
    
    
    /**
     Gets banker's full name from NSUserDefaults if it exists
     
     - returns: Optional String containing banker's full name if it exists
     */
    static func getBankerName() -> String? {
        return userDefaults.string(forKey: "bankerName")
    }
    
    /**
     Delete's banker's name from local data
     */
    static func deleteBankerName() {
        userDefaults.removeObject(forKey: "bankerName")
    }
    
    
    static func saveLeadURL(_ leadURL: String) {
        userDefaults.set(leadURL, forKey: "leadURL")
    }
    
    
    static func getLeadURL() -> String? {
        return userDefaults.string(forKey: "leadURL")
    }
    
    
    static func deleteLeadURL() {
        userDefaults.removeObject(forKey: "leadURL")
    }
    
    
    static func getTestEnvironmentLabel(_ labelframe: CGRect) -> DesignableLabel {
        
        let envLabel = DesignableLabel(frame: labelframe)
        envLabel.text = "TEST ENVIRONMENT"
        envLabel.textColor = UIColor.red
        envLabel.textAlignment = .center
        envLabel.font = UIFont.systemFont(ofSize: 45)
        // this transform could be applied outside but they will all be in the same location in general
        envLabel.transform = CGAffineTransform(rotationAngle: -45.0)
        envLabel.isHidden = false
        
        return envLabel
        
    }
    
    static func getWiFiReachability() -> Bool {
        
        let reachability = Reachability()!
        
        if reachability.connection == .wifi {
            return true
        } else {
            return false
        }
    }
    
    
    
}
