
//
//  DetailSearchTableViewController.swift
//  opportunity_express_client
//
//  Created by Miles Clark on 10/08/18.
//  Copyright (c) 2018 Eastern Labs. All rights reserved.
//

import Foundation
import UIKit

import SwiftyJSON
import Alamofire

/// Struct for encapsulating data about the person
private struct Header {
    
    /**
        Builds header from json
        - parameter json: JSON object containing person details
    */
    
    init(json:JSON) {
        
        self.json = json
        self.name = json["full_name"].string ?? "Unknown Name"
        self.street = json["address_1"].string ?? ""
        self.city = json["city"].string ?? ""
        self.state = json["state"].string ?? ""
        self.zipCode = json["zip_code"].string ?? ""
        self.phone = json["contact_phone"].string ?? ""
        self.email = json["email_address"].string ?? ""
        self.cis = json["core_id"].string ?? ""
        self.address = json["ipad_address_text"].string ?? ""
        self.city_state_zip = json["city_state_zip"].string ?? ""
        
        self.id_string_label = json["id_string_label"].string ?? ""
        self.id_string_value = json["id_string_value"].string ?? ""
    }
    var json: JSON
    var name = ""
    var street = ""
    var city = ""
    var state = ""
    var zipCode = ""
    var phone = ""
    var email = ""
    var cis = ""
    var address = ""
    var city_state_zip = ""
    
    var id_string_label = ""
    var id_string_value = ""
        
    /// returns a map of field name to value for placing data in a table
    var mapForTable: [String: String] {
        get {
                let rows = ["Name" : self.name,
                            self.id_string_label : self.id_string_value,
                            "Address" :self.address,
                            "City/State/Zip": self.city_state_zip,
                            "Email" : email,
                            "Phone Number" : phone]
            return rows
        }
    }
    
    /// returns the keys for displaying data in table, in this particular order
    var keys: [String] {
        get {
            return ["Name", self.id_string_label, "Address", "City/State/Zip", "Email", "Phone Number"]
        }
        
    }
}

/// Struct for encapsulating data about a company
private struct Company {
    
    /**
        Builds Company from json
    
        - parameter json: JSON object containing company details
    */
    init(json:JSON) {
        
        self.json = json
        self.name = json["name"].string ?? ""
        self.street = json["contact_address_street_1"].string ?? ""
        self.city = json["contact_address_city"].string ?? ""
        self.state = json["contact_address_state"].string ?? ""
        self.zipCode = json["contact_address_zip_code"].string ?? ""
        self.phone = json["primary_phone"].string ?? ""
        self.email = json["corporate_email_address"].string ?? ""
        self.uuid = json["uuid"].string ?? ""
        self.is_ineligible = json["is_ineligible"].bool ?? true
        
        self.company_label_text = json["company_label_text"].string ?? ""
        self.company_label_color = json["company_label_color"].string ?? ineligible_grey
    }
    var json: JSON
    var name = ""
    var street = ""
    var city = ""
    var state = ""
    var zipCode = ""
    var phone = ""
    var email = ""
    var uuid = ""
    var is_ineligible = true
    
    var company_label_text = ""
    var company_label_color = ineligible_grey
}

/// ViewController to show a few details about an individual and
/// that individuals related companies
class RelatedCompaniesViewController: UITableViewController {
    
    // constants for tableview sections
    fileprivate let HEADER_SECTION = 0
    fileprivate let COMPANIES_SECTION = 1
    
    // person's uuid. Set from segue into this VC
    var uuid = ""
    
    // header object. optional so it can be nil during initialization
    fileprivate var header: Header?
    
    // array of companies. optional so it can be nil during initialization
    fileprivate var companies: [Company]? = [Company]()
    
    // save requests to cancel old ones
    var dataRequest:Request?
    
    fileprivate var hasAttemptedToGetData = false
    
    var isDisplayingLoginAlert: Bool = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        let nib1 = UINib(nibName: "ExistingCustomer_SearchCell", bundle: nil)
        tableView.register(nib1, forCellReuseIdentifier: "ExistingCustomer_SearchCell")
        hasAttemptedToGetData = false
        let nib = UINib(nibName: "Custom_CompanyDetailsCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "Custom_CompanyDetailsCell")
        // Needed to remove dividers from empty cells at the bottom of the table
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        // Set the title in the NavBar if one is not already set
        self.title = self.title ?? "Error: No Person Found"
        
        // Let this view define presentation context
        self.definesPresentationContext = true
        
        // create a refresh controller to allow for pull to refresh
        self.refreshControl = UIRefreshControl()
        
        // Style refresh control
        self.refreshControl?.backgroundColor = UIColor(hex: eb_primary_blue)
        self.refreshControl?.tintColor = UIColor.white
        
        // Adds action to refresh controller
        // The method retry is called when tableview is pulled down
        self.refreshControl?.addTarget(self, action: #selector(RelatedCompaniesViewController.retry), for: UIControl.Event.valueChanged)

        
        // Refresh views
        self.tableView.reloadData()
        self.tableView.setNeedsDisplay()
        
    }
    
    
    /// Method for refreshing with refresh control
    /// Note: Do not make private
    @objc func retry() {
        getData()
    }
    
    // start loading data before view appears
    override func viewWillAppear(_ animated: Bool) {
        getData()
    }

    /// Gets data from url and builds tableview data as appropriate
    fileprivate func getData() {
        
        if !self.hasAttemptedToGetData {
            // Show activity indicator when fetching data
            let activityIndicator = UIActivityIndicatorView(frame:  CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height))
            activityIndicator.style = UIActivityIndicatorView.Style.gray
            activityIndicator.sizeToFit()
            self.tableView.backgroundView = activityIndicator
            activityIndicator.hidesWhenStopped = true
            activityIndicator.startAnimating()
            self.tableView.setNeedsDisplay()
        }
        
        // Cancel old data request
        dataRequest?.cancel()
        
        let query = self.uuid
        
        if !query.isEmpty {
            
            let baseURL = LoginManager.getBaseURL()
            // build search string and escape characters with %
            let queryString: String = baseURL + "api/related-search/\(query)/".addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            
            self.dataRequest = request(queryString, method: .post, parameters: nil, encoding: URLEncoding.default, headers: nil)
           .responseJSON {
                [unowned self,
                 weak refreshControl = self.refreshControl,
                 weak tableView = self.tableView] response in
                
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                
                self.hasAttemptedToGetData = true
                
                // hide refresh control
                refreshControl?.endRefreshing()
                
                if let resp = response.response {
                    
                    if resp.statusCode == 401 {
                        
                        // Token has expired, prompt to login again
                        self.isDisplayingLoginAlert = true
                        LoginViewManager.refreshToken(self, errorMessage: nil, completion:({
                            [unowned self]
                            (logInSuccessful:Bool) in
                            self.isDisplayingLoginAlert = !logInSuccessful
                            if logInSuccessful {
                                self.getData()
                            }
                            }))
                    }
                }
                    
                // other error responses
                else if response.result.error != nil {
                    return
                }
                
                if let data = response.result.value {
                    
                    // create JSON object from raw data
                    var json = JSON(data)
                    // Verify status code
                    if let statusCode = json["status_code"].int, statusCode == 403 {
                        // Token has expired, prompt to login again
                        LoginViewManager.refreshToken(self, errorMessage: json["error_message"].string, completion:({[unowned self] (logInSuccessful:Bool) in
                            self.hasAttemptedToGetData = false
                            if logInSuccessful {
                                self.getData()
                            }
                        }))
                        
                        
                    } else if let statusCode = json["status_code"].int, statusCode == 200 {

                        
                        // get payload within json
                        let payload = json["payload"]
                        
                        // build and set tableview header
                        self.header = Header(json: payload["header"])
                        
                        // get company json
                        let companies = payload["companies"].array ?? []
                        
                        // empty companies array
                        self.companies = self.companies ?? []
                        self.companies?.removeAll(keepingCapacity: false)
                        
                        // build companies and add to self
                        for company in companies {
                            self.companies?.append(Company(json: company))
                        }
                    }
                    
                } else {
                    self.companies = nil
                }
                
                // refresh tableview
                tableView?.reloadData()
                tableView?.setNeedsDisplay()
            }
        } else {
            companies = nil
            
            // refresh tableview
            tableView?.reloadData()
            tableView?.setNeedsDisplay()
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        // Build error message label
        let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height))
        messageLabel.textColor = UIColor(hex: eb_primary_blue)
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.font = UIFont.systemFont(ofSize: 20.0)
        messageLabel.sizeToFit()
        
        // Check a variety of states and display error message if appropriate
        if !self.hasAttemptedToGetData {
            
            self.tableView.separatorStyle = .none
            
            self.view.layoutIfNeeded()
            
            return 0
            
        } else if companies == nil {
            messageLabel.text = "Unable to connect to server. Please pull down to retry."
            messageLabel.sizeToFit()
            
            self.tableView.backgroundView = messageLabel
            self.tableView.separatorStyle = .none
            
            return 0
        } else if let companies = self.companies, companies.isEmpty{
            messageLabel.text = "No results found"
            messageLabel.sizeToFit()
            
            self.tableView.backgroundView = messageLabel
            self.tableView.separatorStyle = .none
            return 0
            
        } else {
            
            // No error found so show search bar and display 1 section

            self.tableView.backgroundView?.isHidden = true
            self.tableView.separatorStyle = .singleLine
            return 2
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.1
    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        view.tintColor = UIColor.white
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = UIColor(hex: "#666666")
        let header = view as! UITableViewHeaderFooterView
        header.textLabel!.textColor = UIColor.white
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        switch section {
        case HEADER_SECTION: return self.header?.mapForTable.count ?? 0
        case COMPANIES_SECTION: return companies?.count ?? 0
        default: return 0
        }
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Get the cell based on the section
        switch indexPath.section {
        case HEADER_SECTION:
            let keys = header!.keys
            let cell = tableView.dequeueReusableCell(withIdentifier: "Custom_CompanyDetailsCell", for: indexPath) as! Custom_CompanyDetailsCell
            cell.itemLabel.text = keys[indexPath.row]
            cell.valueLabel.text = self.header!.mapForTable[keys[indexPath.row]]!
            return cell
            
        case COMPANIES_SECTION:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ExistingCustomer_SearchCell", for: indexPath) as! ExistingCustomer_SearchCell
            if (indexPath.row < companies?.count ?? 0) {
                
                let current_company = companies![indexPath.row]
                
                cell.SearchLabel.text = current_company.name
                cell.statusLabel.text = current_company.company_label_text
                cell.statusLabel.backgroundColor = UIColor(hex:current_company.company_label_color)
                cell.typeView.image = UIImage(named: "SearchCompanyIcon")
            }
            return cell
        default: return UITableViewCell()
            
        }


    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.dataRequest?.cancel()
    }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        // return appropriate section name
        switch section {
        case HEADER_SECTION: return "Person Details"
        case COMPANIES_SECTION: return "Select an associated company to start or continue an application"
        default: return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Manually return cell heights
        switch indexPath.section {
        case HEADER_SECTION: return 35
        case COMPANIES_SECTION: return 44
        default: return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        
        // only allow cell selection for actions
        switch indexPath.section {
        case HEADER_SECTION: return false
        case COMPANIES_SECTION: return true
        default: return true
        }
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "companySelected", sender: self)
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView.init(frame: CGRect.zero)
    }
    // MARK: - Navigation
   
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // cancel and pending request
        dataRequest?.cancel()
        
        // prepare for transition to next VC
        if segue.identifier == "companySelected" {
            let destVC = segue.destination as! CompanyDetailsViewController
            
            let selectedCompany = self.companies![tableView.indexPathForSelectedRow!.row]
            
            destVC.title = selectedCompany.name
            destVC.uuid = selectedCompany.uuid
            
        }
        
    }
    
    deinit {
        dataRequest?.cancel()
    }
    
}
