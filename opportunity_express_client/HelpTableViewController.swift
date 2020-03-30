//
//  HelpTableViewController.swift
//  opportunity_express_client
//
//  Created by Miles Clark on 10/08/18.
//  Copyright (c) 2018 Eastern Labs. All rights reserved.
//

import UIKit

class HelpTableViewController: UITableViewController {
    
    @IBOutlet weak var nav: UINavigationItem!
    
    // Reference to cells that link to websites
    @IBOutlet weak var expressWebsiteCell: UITableViewCell!
    @IBOutlet weak var logoutCell: UITableViewCell!
    
    @IBOutlet weak var termsandconditionCell: UITableViewCell!
    @IBOutlet weak var bankerNameLabel: UILabel!
    
    @IBOutlet weak var versionBuildLabel: UILabel!
    
    @IBOutlet weak var deviceNameLabel: UILabel!
    
    var title_webview=""
    var url_webview=""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set the title in the NavBar
        self.title = "Help Menu"
        
      
        bankerNameLabel.text = ""
        
        if let bankerNameText = LoginManager.getBankerName() {
            self.bankerNameLabel.text = bankerNameText;
        } else {
            bankerNameLabel.text = "Unknown";}
        
        if let version = versionString as? String, let build = buildString as? String {
         self.versionBuildLabel.text = "Version " + version + ", Build " + build
        } else {
            self.versionBuildLabel.text = "Version: Unknown"
        }
        
        self.deviceNameLabel.text = "Device: " + device_name
        
        // Needed to remove dividers from empty cells at the bottom of the table
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
       
        
        
    }
    override func viewDidAppear(_ animated: Bool) {
        
        //TODO: don't need to declare type...ForcedCast
        let button: UIButton = UIButton(type:UIButton.ButtonType.custom)
        button.setImage(UIImage(named: "User-Profile.png"), for: UIControl.State())
        //add function for button
        //button.addTarget(self, action: "ButtonPressed", forControlEvents: UIControlEvents.TouchUpInside)
        //set frame
        button.frame = CGRect(x: 0, y: 0, width: 20 , height: 20)
        
        let barButton = UIBarButtonItem(customView: button)
        nav.rightBarButtonItem=barButton
        switch LoginManager.getEnvironment() {
        case .prod:
            break
        case .staging:
            let width = self.view.frame.width
            let height = CGFloat(200)
            let xpos = CGFloat(0.0)
            let ypos = self.view.frame.height / 3.0
            let rect = CGRect(x: xpos,y: ypos,width: width, height: height)
            let envLabel = LoginManager.getTestEnvironmentLabel(rect)
            self.view.addSubview(envLabel)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // If the user selects the logout cell
        if tableView.cellForRow(at: indexPath) == logoutCell {
            
            // Confirm user actually wants to log out
            let alertView = UIAlertController(title: nil, message: "Are you sure you want to log out?", preferredStyle: .alert)
            alertView.addAction(UIAlertAction(title: "Logout", style: UIAlertAction.Style.destructive, handler: { (alertAction) -> Void in
                
                // If user confirms, perform the logout segue
                LoginManager.logOut()
                
                // Note: this segue must first be connected in the storyboard
                self.performSegue(withIdentifier: "logOut", sender: self)
            }))
            alertView.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {(alertAction) -> Void in
                tableView.deselectRow(at: indexPath, animated: true)
            }))
            present(alertView, animated: true, completion: nil)
        }
        

        if tableView.cellForRow(at: indexPath) == termsandconditionCell {
            
            // Confirm user actually wants to log out
            title_webview="Express Terms and Conditions"
            // /page_terms
            url_webview=LoginManager.getBaseURL() + "page_terms"
            self.performSegue(withIdentifier: "webview_openurl", sender: self)
            
        }
        
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "webview_openurl" {
            
            let destVC = segue.destination as! HelpWebViewController
            destVC.title = title_webview
            destVC.url = url_webview
            
        }
        
    }
    
    
}
