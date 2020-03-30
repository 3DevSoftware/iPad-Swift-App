//
//  LogInViewController.swift
//  opportunity_express_client
//
//  Created by Miles Clark on 10/08/18.
//  Copyright (c) 2018 Eastern Labs. All rights reserved.
//

import Foundation
import UIKit

import Alamofire
import SAMKeychain
import SwiftyJSON
import Spring
import WebKit


/// Handles the logging in and out of the user
class LogInViewController: UIViewController, UITextFieldDelegate {

    // Outlets from storyboard
    @IBOutlet weak var logInView: DesignableView!
    @IBOutlet weak var emailField: DesignableTextField!
    @IBOutlet weak var passwordField: DesignableTextField!
    @IBOutlet weak var logInButton: DesignableButton!
    @IBOutlet weak var errorLabel: DesignableLabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var buttonActivityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var environmentSwitch: UISwitch!
    
    @IBOutlet weak var switchLabel: DesignableLabel!
    @IBOutlet weak var environmentLabel: DesignableLabel!
    
    // Version Label on login screen
    @IBOutlet weak var versionInfoLabel: UILabel!
    @IBOutlet weak var deviceInfoLabel: UILabel!
    
    // Outlet to constraint controlling spacing between top of screen to logInView
    @IBOutlet weak var topSpaceConstraint: NSLayoutConstraint!
    
    // height of screen
    fileprivate var availableHeight: CGFloat = UIScreen.main.bounds.size.height
    
    // called when switch was turned on
    func switchOn() {
        environmentSwitch.isOn = true;
        environmentLabel.text = "Test Environment";
        environmentLabel.textColor = UIColor(hex:hexRed)
        switchLabel.text = "Disable Test Mode";
        environmentLabel.isHidden = false;
        errorLabel.text = ""
        
        // STAGING
        LoginManager.setEnvironment(.staging)
        
    }
    
     // called when switch was turned off
     func switchOff() {
        environmentSwitch.isOn = false;
        environmentLabel.isHidden = true;
        switchLabel.text = "Switch to Test Environment";
        errorLabel.text = ""
        
        // Production
        LoginManager.setEnvironment(.prod)
    }
    
    
    @IBAction func toggleEnvironment(_ sender: AnyObject) {
        //if the switch was just turned on...enter test mode IF wifi is enabled else don't enter test mode
        if self.environmentSwitch.isOn {
            
            if LoginManager.getWiFiReachability() {
                switchOn()
                // this will validate against the test environment
                self.validateDevice()
            } else {
                
                // Alert user
                let alert = UIAlertController(title: "Test Mode Only Enabled on WiFi", message: nil, preferredStyle: UIAlertController.Style.alert)
                
                let dismissAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: {[unowned self] (alert) in
                    self.switchOff();
                    })
                alert.addAction(dismissAction)
                
                self.present(alert, animated: false, completion: nil)
            }
            
        } else {
            // if the switch was just turned off disable test mode
            switchOff()
            // this will validate against PROD
            self.validateDevice()
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        switchOff()
    
        // set version and build number: TODO: move this to constants.swift
        if let version = versionString as? String, let build = buildString as? String
        {
            self.versionInfoLabel.text = "Version: " + version + ", Build: " + build
        }
        else
        {
            self.versionInfoLabel.text = "Unknown Version"
        }
        
        self.deviceInfoLabel.text = "Device: " + device_name;
        self.errorLabel.isHidden = true
        
        toggleEnvironment(self)

    }
    
    /// Verify device is provisioned and enabled and if not stop process/workflow. If connectivity issues...prompt to try connecting to test enviroment
    fileprivate func validateDevice() {
        // Start animating activity indicator, making it visable as well
        activityIndicator.startAnimating()
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        // TODO: Replace with Auth Code/Name entered initially
        // Try to get the existing device UUID, stored in the keychain
        // If there's no UUID stored there, create one and store it
        var uuid = SAMKeychain.password(forService: "com.easternlabs.opportunity-express-client", account: "user")
        if uuid == nil {
            uuid = UUID().uuidString
            SAMKeychain.setPassword(uuid!, forService: "com.easternlabs.opportunity-express-client",
                account: "user")
        }
//
        var str:String = uuid!;
//        print(str)
        
//        str = str[10..<(str.length-1)]
        print(str)
        
        let parameters = ["device_uuid": str, "device_name": device_name]
        print("device uuid: ", str);
         request(LoginManager.getBaseURL() + "api/device-status/", method: .post, parameters: parameters, encoding: URLEncoding.default, headers: nil)
        // make call to device-status
        
            .responseJSON {[unowned self] response in
                
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                
                self.activityIndicator.stopAnimating()
                
                // if data is returned
                if let data = response.result.value {
                    
                    // create JSON object from raw data
                    let json = JSON(data)

                    // get payload within json
                    let payload = json["payload"]
                    
                    // if is_provisioned field exists and is false
                    if let isProvisioned = payload["is_provisioned"].bool, !isProvisioned{
                        
                        // Get error message or use default message
                        let errorMessage = json["error_message"].string ?? "Please contact Labs to provision this device"
                        
                        // Alert user
                        let alert = UIAlertController(title: "Device not provisioned", message: "\(errorMessage)", preferredStyle: UIAlertController.Style.alert)
                        
                        let retry_text: String
                        
                        switch LoginManager.getEnvironment() {
                        case .prod:
                            retry_text = "Retry"
                        case .staging:
                            retry_text = "Disable Test Mode"
                        }
                        
                        let defaultAction = UIAlertAction(title: retry_text, style: UIAlertAction.Style.default, handler: {[unowned self] (alert) in
                            
                            // if the device was not provisioned (based on response from MT) and we were hitting the PROD environment. we will allow a retry. hide the login view and try to validate
                            // the device again. If it was the staging environment...switch off test mode and go back to the login screen for hitting PROD environment
                            
                            switch LoginManager.getEnvironment() {
                            case .prod:
                                self.logInView.isHidden = true;
                                self.validateDevice();
                            case .staging:
                                self.switchOff();
                            }
                            
                        })
                        
                        alert.addAction(defaultAction)
                        
                        
                        self.present(alert, animated: false, completion: nil)
                        return
                    }
                    
                    // if is_enabled field exists and is false
                    if let isEnabled = payload["is_enabled"].bool, !isEnabled {
                        
                        
                        // Alert user, with option to retry
                        let errorMessage = json["error_message"].string ?? "Please contact Labs to enable this device"
                        let alert = UIAlertController(title: "Device Disabled", message: "\(errorMessage)", preferredStyle: UIAlertController.Style.alert)
                        
                        let retry_text: String
                        
                        switch LoginManager.getEnvironment() {
                        case .prod:
                            retry_text = "Retry"
                        case .staging:
                            retry_text = "Disable Test Mode"
                        }
                        
                        let defaultAction = UIAlertAction(title: retry_text, style: UIAlertAction.Style.default, handler: {[unowned self] (alert) in
                            
                            switch LoginManager.getEnvironment() {
                            case .prod:
                                self.logInView.isHidden = true;
                                self.validateDevice();
                            case .staging:
                                self.switchOff();
                            }
                            })
                        
                        alert.addAction(defaultAction)
                        
                        self.present(alert, animated: false, completion: nil)
                        return
                    }
                    
                    // if is_provisioned and is_enabled are true, show login view
                    if let isProvisioned = payload["is_provisioned"].bool, let isEnabled = payload["is_enabled"].bool, isProvisioned && isEnabled {
                        self.logInView.isHidden = false;
                        
                    }
                        
                    // else alert user with error message
                    else {
                        let errorMessage = json["error_message"].string ?? "Unable to validate this device"
                        let alert = UIAlertController(title: "Unable to validate", message: "\(errorMessage)", preferredStyle: UIAlertController.Style.alert)
                        
                        let retry_text: String
                        
                        switch LoginManager.getEnvironment() {
                        case .prod:
                            retry_text = "Retry"
                        case .staging:
                            retry_text = "Disable Test Mode"
                        }
                        
                        let defaultAction = UIAlertAction(title: retry_text, style: UIAlertAction.Style.default, handler: {[unowned self] (alert) in
                            switch LoginManager.getEnvironment() {
                            case .prod:
                                self.logInView.isHidden = true;
                                self.validateDevice();
                            case .staging:
                                self.switchOff();
                            }
                            })
                        
                        alert.addAction(defaultAction)
                        
                        self.present(alert, animated: false, completion: nil)
                        return

                    }
                    
                }
                
                // If data doesn't exist, notify user that call has failed
                else {
                    
                    // Alert user, with option to retry
                    let alert = UIAlertController(title: "Connection Error", message: "Unable to connect to server", preferredStyle: UIAlertController.Style.alert)
                    
                    let retry_text: String
                    
                    switch LoginManager.getEnvironment() {
                    case .prod:
                        retry_text = "Retry"
                    case .staging:
                        retry_text = "Disable Test Mode"
                    }
                    
                    let defaultAction = UIAlertAction(title: retry_text, style: UIAlertAction.Style.default, handler: {[unowned self] (alert) in
                        switch LoginManager.getEnvironment() {
                        case .prod:
                            self.logInView.isHidden = true;
                            self.validateDevice();
                        case .staging:
                            self.switchOff();
                        }
                        })
                    
                    alert.addAction(defaultAction)
                    
                    self.present(alert, animated: false, completion: nil)
                    return
                }
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // start with switch off and any time this view appears be sure to toggle the switch off
        switchOff()
        
        toggleEnvironment(self)
        
        // Center logInView and layout views again
        availableHeight = UIScreen.main.bounds.size.height
        centerLogInView(animation: false)
        
        self.view.layoutIfNeeded()
        
        // Set up class to listen for showing and hiding of keyboard
        NotificationCenter.default.addObserver(self, selector: #selector(LogInViewController.keyboardWillShow(_:)), name:UIResponder.keyboardWillShowNotification, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(LogInViewController.keyboardWillHide(_:)), name:UIResponder.keyboardWillHideNotification, object: nil);
    }
    
    // remove keyboard observers when object deinitializes
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    /// Centers logInView on screen with respect to the amount of avaiable height
    fileprivate func centerLogInView(animation withAnimation: Bool, duration: Double = 0.25) {
        topSpaceConstraint?.constant = (availableHeight - logInView.bounds.size.height) / 2
        
        if withAnimation {
            UIView.animate(withDuration: duration, animations: { [unowned self] in
                self.view.layoutIfNeeded()
            })
        } else {
            self.view.layoutSubviews()
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // When the background is touched, dismiss keyboard
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    // Called just before keyboard is shown
    @objc func keyboardWillShow(_ sender: Notification) {
        
        // When the keyboard shows, center the loginview between the top and the keyboard
        let screenHeight = UIScreen.main.bounds.size.height
        
        if let keyboardFrame: NSValue = sender.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            availableHeight = screenHeight - keyboardHeight
        }else {
        
  
            availableHeight = screenHeight
        }
        
        // duration of keyboard animation
        let duration: Double
        
        // Find default duration or use 0.25, which is standard for US keyboard
        if let dur = (sender.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as AnyObject).doubleValue {
            duration = dur
        } else {
            duration = 0.25
        }
        
        centerLogInView(animation: true, duration: duration)
    }
    
    // Called just before keybaord hides
    @objc func keyboardWillHide(_ sender: Notification) {
        
        // When the keyboard hide, move keyboard back to center of the screen
        availableHeight = UIScreen.main.bounds.size.height

        // Duration of keyboard animation
        let duration: Double
    
        // Find default duration or use 0.25, which is standard for US keyboard
        if let dur = (sender.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as AnyObject).doubleValue {
            duration = dur
        } else {
            duration = 0.25
        }
        
        centerLogInView(animation: true, duration: duration)

    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // hide error label when user types
        errorLabel.isHidden = true
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        // if user presses next while in emailFields, focus on password field
        if textField == emailField {
            passwordField.becomeFirstResponder()
        }
        return true
    }
    
    
    
    @IBAction func logIn(_ sender: UIButton) {
        
        // if no email is entered, animate a shake to notify user
        if (emailField.text!.isEmpty) {

            emailField.animation = "shake"
            emailField.curve = "spring"
            emailField.duration = 0.25
            emailField.damping = 1.0
            emailField.force = 0.5
            emailField.animate()
            
        }
        
        // if no password is entered, animate a shake to notify user
        if (passwordField.text!.isEmpty) {
            passwordField.animation = "shake"
            passwordField.curve = "spring"
            passwordField.duration = 0.25
            passwordField.damping = 1.0
            passwordField.force = 0.5
            passwordField.animate()
        }
        
        // If an email or password was not entered, return
        if emailField.text!.isEmpty || passwordField.text!.isEmpty {
            return
        }
        
        
        
        // Parameters to be passed to HTTP POST
        // trim whitespace characters from user_email field before sending for validation
        // this is really space and tab characters
        
        let uuid = SAMKeychain.password(forService: "com.easternlabs.opportunity-express-client", account: "user")
        
        let parameters = [
            "username": emailField.text!.trimmingCharacters(in: CharacterSet.whitespaces) as AnyObject,
            "password": passwordField.text as AnyObject,
            "device_uuid": "\(uuid!)" as AnyObject
        ]
        
        self.logInButton.isEnabled = false
        self.buttonActivityIndicator.startAnimating()
        self.errorLabel.isHidden = true
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        let baseURL = LoginManager.getBaseURL()
        
        // make call to login-user-device url
        
            
       request( baseURL + "api/login/", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: nil)
            .responseJSON {[unowned self] response in
                
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                
                self.buttonActivityIndicator.stopAnimating()
                
                print(response);
                // If data is returned
                if let data = response.result.value {
                    
                    self.logInButton.isEnabled = true
                    
                    // create JSON object from raw data
                    var json = JSON(data)

                    // get paylaod with json
                    let payload = json["payload"]

                    // if user is authenticated
                    if let isAuthenticated = payload["is_authenticated"].bool, isAuthenticated {
                        
                        self.errorLabel.isHidden = true
                        
                        // dismiss keybaord
                        self.emailField.resignFirstResponder()
                        self.passwordField.resignFirstResponder()
                        
                        // set cookies if authenticated
                        
                        if let headerFields = response.response?.allHeaderFields as? [String: String], let URL = response.request?.url
                        {
                            // unpack the cookies coming from the web response
                            let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: URL);
                            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies(cookies, for: URL, mainDocumentURL: nil);
                            
                            
                        } else {
                            self.errorLabel.text = "Invalid Server Response: Try Again";
                            self.errorLabel.isHidden = false;
                            return 
                        }
                     
                        // Login with loginManager, making sure all value exist, using default values if they don't
                        LoginManager.logIn(self.emailField.text!, bankerName: payload["name"].string ?? "Banker Name Unknown",  leadURL: payload["lead_url"].string ?? "")
                        
                        // start segue to next view
                        self.performSegue(withIdentifier: "loginSuccess", sender: self)
                    
                    } else {
                        
                        
                        //animate login button (shake and turn red) to show that login failed
                        self.logInButton.animation = "shake"
                        self.logInButton.curve = "spring"
                        self.logInButton.duration = 0.5
                        self.logInButton.damping = 1.0
                        self.logInButton.force = 0.5
                        
                        
                        // Color change animation
                        UIView.animate(withDuration: 0.1, animations: {
                            self.logInButton.backgroundColor = UIColor(hex: hexRed)
                            }, completion: { [unowned self] (finished) in
                                UIView.animate(withDuration: 0.5, animations: {
                                    self.logInButton.backgroundColor = UIColor(hex: eb_primary_blue)
                                })
                        })

                       self.logInButton.animate()
                        
                        // Get error message from json or use a default one
                        self.errorLabel.text = json["error_message"].string ?? "Unable to login user"
                        self.errorLabel.isHidden = false
                        
                    }
                    

                } else {
                    self.errorLabel.text = "Unable to connect to server"
                    self.errorLabel.isHidden = false
                }

            }
    }
    
    // Called when device rotates
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        // readjust position of logInView
        availableHeight = size.height
        centerLogInView(animation: true, duration: coordinator.transitionDuration)
    }

    
    // MARK: - Navigation

    // Called before transition to
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    
    /// IBAction placeholder for unwind segue.
    /// Required to allow connection in Storyboard
    @IBAction func logOutUnwindSegue(_ sender: UIStoryboardSegue){
        
    }
    
    // Returns the type fo segue for unwinding
    override func segueForUnwinding(to toViewController: UIViewController, from fromViewController: UIViewController, identifier: String?) -> UIStoryboardSegue {
       
        // if the segue is an unwind segue
        if let id = identifier{
            if id == "logOut" {
                
                // return a custom LogInUnwindSegue
                let unwindSegue = LogInUnwindSegue(identifier: id, source: fromViewController, destination: toViewController, performHandler: { () -> Void in})
                return unwindSegue
            }
        }
        
        return UIStoryboardSegue(identifier: identifier, source: fromViewController, destination: toViewController)
    }


}
