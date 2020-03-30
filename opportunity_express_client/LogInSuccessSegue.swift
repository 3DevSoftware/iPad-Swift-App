//
//  LogInSuccessSegue.swift
//  opportunity_express_client
//
//  Created by Miles Clark on 10/08/18.
//  Copyright (c) 2018 Eastern Labs. All rights reserved.
//

import UIKit

/// Segue for animating the login views
class LogInSuccessSegue: UIStoryboardSegue {
    
    override func perform() {
        
        let sourceVC = self.source as! LogInViewController
        let destVC = self.destination 
        
        // Assign the source and destination views to local variables.
        let sourceVCView = sourceVC.view as UIView!
        let destVCView = destVC.view as UIView!
        
        // Get the screen width and height.
        let screenWidth = UIScreen.main.bounds.size.width
        let screenHeight = UIScreen.main.bounds.size.height
        
        // Specify the initial position of the destination view.
        destVCView?.frame = CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight)
        
        // Access the app's key window and insert the destination view above the current (source) one.
        let window = UIApplication.shared.keyWindow
        window?.insertSubview(destVCView!, belowSubview: sourceVCView!)
        
        let logInButton = sourceVC.logInButton
        
        // First animate login button to green
        UIView.animate(withDuration: 0.5, animations: {
            logInButton?.backgroundColor = UIColor(hex: login_success_green)
            }, completion: { finished in
                
                // Then Zoom out view while changing the background color to white
                let logInView = sourceVC.logInView
                logInView?.animation = "zoomOut"
                logInView?.curve = "spring"
                logInView?.duration = 1.0
                
                
                UIView.animate(withDuration: 1.0, animations: {
                    sourceVCView?.backgroundColor = UIColor(hex: hexwhite)
                })
                
                logInView?.animateNext(completion: {
                    self.source.present(destVC, animated: false, completion: nil)
                })
               
        })
    }
    
   
}
