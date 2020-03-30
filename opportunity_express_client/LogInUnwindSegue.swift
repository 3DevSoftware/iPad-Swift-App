//
//  LogInUnwindSegue.swift
//  opportunity_express_client
//
//  Created by Miles Clark on 10/08/18.
//  Copyright (c) 2018 Eastern Labs. All rights reserved.
//

import UIKit

///  Custom unwind segue to go back to login screen
class LogInUnwindSegue: UIStoryboardSegue {
    
    override func perform() {
        
        // Get source and dest VCs
        let sourceVC = self.source 
        let destVC = self.destination as! LogInViewController
        
        // Assign the source and destination views to local variables.
        let sourceVCView = sourceVC.view as UIView!
        let destVCView = destVC.view as UIView!
        
        // Get the screen width and height.
        let screenWidth = UIScreen.main.bounds.size.width
        let screenHeight = UIScreen.main.bounds.size.height
        
        // Set the initial position of the destination view.
        destVCView?.frame = CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight)
        
        // Access the app's key window and insert the destination view above the current (source) one.
        let window = UIApplication.shared.keyWindow
        window?.insertSubview(destVCView!, belowSubview: sourceVCView!)
        
        // set up destiation view
        let logInButton = destVC.logInButton
        logInButton?.backgroundColor = UIColor(hex: eb_primary_blue)
        
        destVC.emailField.text = ""
        destVC.passwordField.text = ""
        
        // Zoom in view while changing the background color to blue
        let logInView = destVC.logInView
        logInView?.animation = "zoomIn"
        logInView?.curve = "spring"
        logInView?.duration = 1.0
        
        
        // flip the switch to disable test mode on any segue to this VC (currently made switchOff a non private instance method...may be able to switch it to private
        destVC.switchOff()
        
        // Complete animation
        logInView?.animate()
        
        UIView.animate(withDuration: 0.5, animations: {
            sourceVCView?.backgroundColor = UIColor(hex: eb_primary_blue)
            destVCView?.backgroundColor = UIColor(hex: eb_primary_blue)
            },completion: {finished -> Void in
                self.source.dismiss(animated: false, completion: nil)
        })
        
    }
}
