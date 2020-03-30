//
//  ViewController.swift
//  opportunity_application_view
//
//  Created by Njeru, Kevin on 6/29/16.
//  Copyright © 2016 Njeru, Kevin. All rights reserved.
//

import UIKit
import SwiftyJSON
import Alamofire

/// Struct for encapsulating data about the company
private struct Header {
    
    /**
     Builds header from json
     
     :param: json JSON object containing company details
     */
    init(header:JSON, appHeader:JSON) {
        
        self.headerJSON = header
        self.name = header["name"].string ?? ""
        self.street = header["contact_address_street_1"].string ?? ""
        self.city = header["contact_address_city"].string ?? ""
        self.state = header["contact_address_state"].string ?? ""
        self.zipCode = header["contact_address_zip_code"].string ?? ""
        self.phone = header["contact_phone"].string ?? ""
        self.email = header["corporate_email_address"].string ?? ""
        self.cis = header["core_id"].string ?? ""
        
        self.appHeaderJSON = appHeader
        self.status = appHeader["state"].int ?? 0
        self.statusMessage = appHeader["message"].string ?? "No Application Found"
        
        self.is_ineligible = appHeader["is_ineligible"].bool ?? true
        
        if self.is_ineligible {
            self.eligibility = "Not eligible for Express"
        } else {
            self.eligibility = "Eligible for Express"
        }
    }
    var headerJSON: JSON
    var appHeaderJSON:JSON
    var name = ""
    var street = ""
    var city = ""
    var state = ""
    var zipCode = ""
    var phone = ""
    var email = ""
    var cis = ""
    var status = 0
    var statusMessage = ""
    var eligibility = ""
    var is_ineligible = true
    
    /// computed address, which buils the address from appropriate fields
    var address: String {
        get {
            let address = "\(street), \(city), \(state) \(zipCode)"
            
            // If address length is less than 6 return empty string to remove commas
            if address.characters.count < 6 {
                return ""
            }
            
            return address
        }
    }
    
    /// returns a map of field name to value for placing data in a table
    var mapForTable: [String: String] {
        get {
            return ["Company Name" : name,
                    "Company CIS": cis,
                    "Company Address" : self.address,
                    "Email" : email,
                    "Phone Number" : phone,
                    "Status": self.statusMessage,
                    "Eligibility": self.eligibility]
        }
    }
    
    /// returns the keys for displaying data in table, in this particular order
    var keys: [String] {
        get {
            return ["Company Name", "Company CIS", "Company Address", "Email", "Phone Number", "Status", "Eligibility"]
        }
    }
}

/// Struct for encapsulating data about an action
private struct Action {
    
    /**
     Builds Action from json
     
     :param: json JSON object containing action details
     */
    init(json:JSON) {
        self.json = json
        self.url = json["url"].string ?? ""
        
        // escape url string
        self.url = self.url.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet()) ?? ""
        self.title = json["title"].string ?? ""
    }
    
    init(url:String, title:String, shouldOpenWebView:Bool) {
        self.url = url
        self.title = title
        self.shouldOpenWebView = shouldOpenWebView
        
        // escape url string
        self.url = self.url.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet()) ?? ""
    }
    
    var json: JSON?
    var url = ""
    var title  = ""
    var shouldOpenWebView = true
}

private struct Loan_App {
    
    /**
     Build Loan_App from json
     
     :param: json JSON object containing loan_app details
    **/
    
    init(json:JSON) {
        self.json = json
        self.id = json["id"].string ?? ""
        self.time_started = json["time_started"].string ?? ""
        self.requested_amount = json["requested_amount"].string ?? ""
        self.app_state = json["application_state_lookup_id"].string ?? ""
    }
    
//    init(id:String, time_started:String, requested_amount:String, app_state:String) {
//        
//        self.id = id
//        self.time_started = time_started
//        self.requested_amount = requested_amount
//        self.app_state = app_state
//    }
    
    var json: JSON?
    var id = ""
    var time_started = ""
    var requested_amount = ""
    var app_state = ""
}

///  TableViewController for showing a summary of the application as well as
///  giving the users the ability to sign the documents
class ApplicationDetailTableViewController: UITableViewController {
    
    // constants for tableview sections
    private let HEADER_SECTION = 0
    private let ACTION_SECTION = 1
    
    
    var sectionHeaderNames = ["Company Details", "No Actions Found"]
    
    // header object. optional so it can be nil during initialization
    private var header: Header?
    
    // all available actions for this application
    private var actions = [Action]()
    
    // company's uuid. Set from segue into this VC
    var uuid = ""
    
    // All loan applications for company
    var all_apps: [String] = [String]()
    
    // save request so they can be canceled later on
    var dataRequest:Request?
    
    // signer UUID
    var signerUuid = ""
    
    private var hasAttemptedToGetData = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var nib = UINib(nibName: "Custom_CompanyDetailsCell", bundle: nil)
        tableView.registerNib(nib, forCellReuseIdentifier: "Custom_CompanyDetailsCell")
        hasAttemptedToGetData = false
        
        // Needed to remove dividers from empty cells at the bottom of the table
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
        
        // Refresh control to allow pull to refresh
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.backgroundColor = UIColor(hex: ineligible_grey)
        self.refreshControl?.tintColor = UIColor.whiteColor()
        
        // Adds action to refresh controller
        // The method retry is called when tableview is pulled down
        self.refreshControl?.addTarget(self, action: #selector(ApplicationDetailTableViewController.retry), forControlEvents: UIControlEvents.ValueChanged)
        
      
        
    }
    
    // Method for refreshing with refresh control
    // Note: Do not make private
    func retry() {
        getData()
    }
    
    
    // start loading data before view appears
    override func viewWillAppear(animated: Bool) {
        getData()
    }
    
    
    /// Gets data from url and builds tableview data as appropriate
    private func getData() {
        
        if !self.hasAttemptedToGetData {
            // Show activity indicator when fetching data
            let activityIndicator = UIActivityIndicatorView(frame:  CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height))
            activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
            activityIndicator.sizeToFit()
            self.tableView.backgroundView = activityIndicator
            activityIndicator.hidesWhenStopped = true
            activityIndicator.startAnimating()
            self.tableView.setNeedsDisplay()
        }
        
        // Cancel old requests
        dataRequest?.cancel()
        
        let baseURL = LoginManager.getBaseURL()
        
        // build string and escape characters with %
        let queryString: String = baseURL + "api/get-company-details/".stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
        
        /** UNCOMMENT AND DELETE SKELETON DUPE ONCE LOGIN IS MERGED **/
        let parameters = ["uuid": self.uuid, "user_token":LoginManager.getToken() ?? "",
                          "signer_uuid": self.signerUuid]
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        // make async request and wait on response
        self.dataRequest = request(.POST,  queryString, parameters:parameters).responseJSON {
            [unowned self, weak refreshControl = self.refreshControl!, weak tableView = self.tableView!] response in
            
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            
            self.hasAttemptedToGetData = true
            
            // hide refresh control
            refreshControl?.endRefreshing()
            
            // return if error is found
            if response.result.error != nil {
                self.header = nil
                return
            }
            
            // if data is returned
            if let data: AnyObject = response.result.value {
                
                // create JSON object from raw data
                var json = JSON(data)
                
                // Verify status code
                if let statusCode = json["status_code"].int where statusCode == 403 {
                    // Token has expired, prompt to login again
                    LoginViewManager.refreshToken(self, errorMessage: json["error_message"].string, completion:({[unowned self] (logInSuccessful:Bool) in
                        self.hasAttemptedToGetData = false
                        if logInSuccessful {
                            self.getData()
                        }
                    }))
                    
                    
                } else if let statusCode = json["status_code"].int where statusCode == 200 {
                    
                    // get payload within json
                    let payload = json["payload"]
                    
                    // return existing applications
                    if let loans_apps = payload["loan_apps"].array {
                        
                        let dateFormatter = NSDateFormatter()
                        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
                        
                        let currencyFormatter = NSNumberFormatter()
                        currencyFormatter.numberStyle = NSNumberFormatterStyle.CurrencyStyle
                        
                        
                        if loans_apps.count > 1 {
                            for loan_app in loans_apps {
                                let app = Loan_App(json: loan_app)

                              
                            }
                        }
                        else {
                           
                        }
                    }
                    
                    // build and set tableview header
                    self.header = Header(header: payload["header"], appHeader: payload["app_header"])
                    
                    // remove all actions
                    let actions = payload["actions"].array ?? []
                    self.actions.removeAll(keepCapacity: false)
                    
                    // Check if company is eligible
                    // If not, add an action that submits an AAN request
                    let is_ineligible = self.header?.is_ineligible ?? true
                    
                    // TODO: this needs to be moved to the MT
                    if is_ineligible {
                        let requestAanUrl: String = LoginManager.getBaseURL() + "api/save_aan_request/".stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
                        
                        self.actions.append(Action(url: requestAanUrl, title: "Request AAN", shouldOpenWebView: false))
                        
                    } else {
                        // build new actions from JSON
                        for action in actions {
                            self.actions.append(Action(json: action))
                        }
                    }
                }
            } else {
                self.header = nil
            }
            
            // Refresh tableview
            tableView?.reloadData()
            tableView?.setNeedsDisplay()
            
                  }
        
    }
  
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // Build error message label
        let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height))
        messageLabel.textColor = UIColor(red: 0, green: 51, blue: 102, alpha: 1)
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .Center
        messageLabel.font = UIFont.systemFontOfSize(20.0)
        messageLabel.sizeToFit()
        
        // Check a variety of states and display error message if appropriate
        if !self.hasAttemptedToGetData {
            
            self.tableView.separatorStyle = .None
            
            self.view.layoutIfNeeded()
            
            return 0
            
        } else if self.header == nil {
            messageLabel.text = "Unable to connect to server. Please pull down to retry."
            messageLabel.sizeToFit()
            
            self.tableView.backgroundView = messageLabel
            self.tableView.backgroundView?.hidden = false
            
            self.tableView.separatorStyle = .None
            
            self.view.layoutIfNeeded()
            
            return 0
            
        } else if self.actions.count == 0 {
            
            self.tableView.backgroundView?.hidden = true
            self.tableView.separatorStyle = .SingleLine
            
            self.view.layoutIfNeeded()
            
            self.sectionHeaderNames[ACTION_SECTION] = "No Actions Found"
            
            // no actions found so display 2 section
            return 2
            
        } else {
            
            self.tableView.backgroundView?.hidden = true
            self.tableView.separatorStyle = .SingleLine
            
            self.view.layoutIfNeeded()
            
            self.sectionHeaderNames[ACTION_SECTION] = "Actions"
            
            // 2 sections: one for company details and the other for actions
            return 2
        }
        
        
        
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        switch section {
        case HEADER_SECTION: return self.header?.mapForTable.count ?? 0
        case ACTION_SECTION: return actions.count ?? 0
        default: return 0
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        // return appropriate section name
        switch section {
        case HEADER_SECTION: return sectionHeaderNames[HEADER_SECTION]
        case ACTION_SECTION: return sectionHeaderNames[ACTION_SECTION]
        default: return nil
        }
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 20
    }
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    override func tableView(tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        view.tintColor = UIColor.whiteColor()
    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        view.tintColor = UIColor(hex: eastern_orange)
        let header = view as! UITableViewHeaderFooterView
        header.textLabel!.textColor = UIColor.whiteColor()
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // Get the cell based on the section
        switch indexPath.section {
        case HEADER_SECTION:
            let keys = header!.keys
            let cell:Custom_CompanyDetailsCell = self.tableView.dequeueReusableCellWithIdentifier("Custom_CompanyDetailsCell") as! Custom_CompanyDetailsCell
            cell.itemLabel.text = keys[indexPath.row]
            cell.valueLabel.text = self.header!.mapForTable[keys[indexPath.row]]!
            return cell
            
        case ACTION_SECTION:
            let cell = tableView.dequeueReusableCellWithIdentifier("actionCell", forIndexPath: indexPath) as! ActionTableViewCell
            cell.documentLabel.text = actions[indexPath.row].title
            cell.url = actions[indexPath.row].url
            return cell
        default: return UITableViewCell()
            
        }
    }
    
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        // Manually return cell heights
        switch indexPath.section {
        case HEADER_SECTION: return 35
        case ACTION_SECTION: return 54
        default: return 0
        }
    }
    
    override func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        
        // only allow cell selection for actions
        switch indexPath.section {
        case HEADER_SECTION: return false
        case ACTION_SECTION: return true
        default: return true
        }
    }
    
    // MARK: - Navigation
    
    override func shouldPerformSegueWithIdentifier(identifier: String?, sender: AnyObject?) -> Bool {
        
        // prepare for transition to next VC
        if identifier == "showWebView" {
            
            let selectedResult = self.actions[tableView.indexPathForSelectedRow!.row]
            if selectedResult.shouldOpenWebView {
                return true
            }
            
            // Do a POST request instead
            
            // TODO: Attach parameters to Action class so they can be
            let parameters = ["company_uuid": self.uuid, "user_token":LoginManager.getToken() ?? ""]
            
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            
            self.dataRequest?.cancel()
            
            // make async request and wait on response
            self.dataRequest = request(.POST, selectedResult.url, parameters:parameters).responseJSON {
                [unowned self, weak refreshControl = self.refreshControl!] response in
                
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                
                self.hasAttemptedToGetData = true
                
                // hide refresh control
                refreshControl?.endRefreshing()
                
                // return if error is found
                if response.result.error != nil {
                    
                    let alertController: UIAlertController = UIAlertController(title: "Error", message: "Could not request AAN. Please try again later.", preferredStyle: .Alert)
                    let okAction: UIAlertAction = UIAlertAction(title: "OK", style: .Cancel) { action -> Void in
                        // Dismiss UIAlert
                    }
                    alertController.addAction(okAction)
                    self.presentViewController(alertController, animated: true, completion: nil)
                    
                    return
                }
                
                // if data is returned
                if let data: AnyObject = response.result.value {
                    
                    // create JSON object from raw data
                    var json = JSON(data)
                    
                    // Verify status code
                    if let statusCode = json["status_code"].int where statusCode == 200 {
                        
                        let alertController: UIAlertController = UIAlertController(title: "Success", message: "Your AAN request was successfully submitted.", preferredStyle: .Alert)
                        let okAction: UIAlertAction = UIAlertAction(title: "OK", style: .Cancel) { action -> Void in
                            // Dismiss UIAlert
                        }
                        alertController.addAction(okAction)
                        self.presentViewController(alertController, animated: true, completion: nil)
                        
                        self.tableView.deselectRowAtIndexPath(self.tableView.indexPathForSelectedRow!, animated: true)
                        
                        return
                        
                    } else {
                        
                        let alertController: UIAlertController = UIAlertController(title: "Error", message: "Could not request AAN. Please try again later.", preferredStyle: .Alert)
                        let okAction: UIAlertAction = UIAlertAction(title: "OK", style: .Cancel) { action -> Void in
                            // Dismiss UIAlert
                        }
                        alertController.addAction(okAction)
                        self.presentViewController(alertController, animated: true, completion: nil)
                        
                        return
                    }
                }
            }
        }
        
        return false
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        // prepare for transition to next VC
        if segue.identifier == "showWebView" {
            
            let destVC = segue.destinationViewController as! WebViewController
            
            let selectedResult = self.actions[tableView.indexPathForSelectedRow!.row]
            
            destVC.initialUrl = selectedResult.url
            destVC.hidesBottomBarWhenPushed = true
        }
        
    }
    
}
