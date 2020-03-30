//
//  SearchTableViewController.swift
//  opportunity_express_client
//
//  Created by Miles Clark on 10/08/18.
//  Copyright (c) 2018 Eastern Labs. All rights reserved.
//

import UIKit

import Alamofire
import SwiftyJSON

private struct SearchResult {
    
    init(json:JSON) {
        self.name = json["name"].string ?? "Error: Entry has no name"
        self.type = json["type"].string ?? "Person"
        self.uuid = json["uuid"].string ?? ""
        self.is_ineligible = json["is_ineligible"].bool ?? true
        self.label_text = json["label_text"].string ?? "Unknown"
        self.label_color = json["label_color"].string ?? "#969696"
    }
    
    var name = ""
    var type = ""
    var uuid = ""
    var is_ineligible = true
    var label_text = ""
    var label_color = ""
    
}

private struct SearchResult_newCustomer {
    
    init(json:JSON) {
        self.name = json["name"].string ?? ""
        self.city = json["city"].string ?? ""
        self.state = json["state"].string ?? ""
        self.uuid = json["uuid"].string ?? ""
        self.related_to = json["related_to"].string ?? ""
        self.is_ineligible = json["company_is_ineligible"].bool ?? true
        self.is_company = json["is_company"].bool ?? true
        self.start_app_url = json["start_app_url"].string ?? ""
        self.go_to_company_details = json["go_to_company_details"].bool ?? true
    }
    
    var name = ""
    var city=""
    var state=""
    var uuid = ""
    var related_to = ""
    var is_ineligible = true
    var is_company = true
    var start_app_url = ""
    var go_to_company_details = true
    
}

/// Table view to support searching of companies and individuals
class SearchTableViewController: UITableViewController, UISearchResultsUpdating, UISearchBarDelegate {
    
    @IBOutlet weak var nav: UINavigationItem!
    @IBOutlet weak var segmentControl: UISegmentedControl!
    
    var company_url_uuid = ""
    var query = ""
    
    var selectedIndexPath : IndexPath?
    var tag_to_segue: Int = 0
    var numberofsections:Int = 0
    // Its optional value is used to indicate connection/DB return failures
    fileprivate var tableData: [SearchResult]? = [SearchResult]()
    fileprivate var tableData_newCustomer: [SearchResult_newCustomer]? = [SearchResult_newCustomer]()
    
    // Used to store filtered values from searching
    fileprivate var filteredData = [SearchResult]()
    fileprivate var filteredData_newCustomer = [SearchResult_newCustomer]()
    
    // used for handling searchbar
    var resultSearchController = UISearchController()
    var resultNewSearchController = UISearchController()
    
    // save requests to cancel old ones
    var dataRequest:Request?
    
    // store scope of search
    var scope = "All"
    
    var isDisplayingLoginAlert = false
    
    var actInd = UIActivityIndicatorView(frame: CGRect(x: 0,y: 0, width: 300, height: 300))
    
    @IBAction func segmentControlAction(_ sender: AnyObject) {
        
        self.resultSearchController.loadViewIfNeeded()
        self.resultNewSearchController.loadViewIfNeeded()
        
        switch segmentControl.selectedSegmentIndex
        {
        case 0:
            self.resultSearchController = ({
                [unowned self] in
                let controller = UISearchController(searchResultsController: nil)
                controller.searchResultsUpdater = self
                controller.dimsBackgroundDuringPresentation = false
                controller.hidesNavigationBarDuringPresentation = true
                let searchBar = controller.searchBar
              //  searchBar.prompt = "Existing Customer: Search for a Company or Person, CIS# or Express Application #"
                searchBar.placeholder = "Company/Person Name or CIS# or Express Application #";
                
                searchBar.scopeButtonTitles = ["All", "Companies Only", "Individuals Only"]
                searchBar.tintColor = UIColor(hex: eb_primary_blue)
                searchBar.selectedScopeButtonIndex = 0
                searchBar.delegate = self
                searchBar.sizeToFit()
                self.tableView.tableHeaderView = searchBar
                return controller
                })()
            tableView?.reloadData()
            tableView?.setNeedsDisplay()
        case 1:
            self.resultNewSearchController = ({
                [unowned self] in
                let controller = UISearchController(searchResultsController: nil)
                controller.searchResultsUpdater = self
                controller.dimsBackgroundDuringPresentation = false
                controller.hidesNavigationBarDuringPresentation = true
                let searchBar = controller.searchBar
            //    searchBar.prompt = "New Customer: Search for a Company or Person by Name"
                searchBar.placeholder = "Company/Person Name"
                searchBar.tintColor = UIColor(hex: eb_primary_blue)
                searchBar.scopeButtonTitles = ["All", "Companies Only", "Individuals Only"]
                searchBar.selectedScopeButtonIndex = 0
                //TODO: Possible memory leak
                searchBar.delegate = self
                searchBar.sizeToFit()
                self.tableView.tableHeaderView = searchBar
                return controller
                })()
        default:
            break;
        }
        
    }
    
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
        
        let nib = UINib(nibName: "NewCustomer_SearchCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "NewCustomer_SearchCell")
        let nib1 = UINib(nibName: "ExistingCustomer_SearchCell", bundle: nil)
        tableView.register(nib1, forCellReuseIdentifier: "ExistingCustomer_SearchCell")
       
        // Set the title in the NavBar
        self.title = "Search"
        
        // activity indicator
        self.actInd.transform = CGAffineTransform(scaleX: 1.5, y: 1.5);
        self.actInd.center = self.view.center
        self.actInd.hidesWhenStopped = true
        self.actInd.style = UIActivityIndicatorView.Style.whiteLarge
        self.actInd.color = UIColor.gray
        self.tableView.addSubview(actInd)
        
        self.segmentControlAction(self)
        
        // Needed to remove dividers from empty cells at the bottom of the table
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        // Let this view define presentation context
        self.definesPresentationContext = true
        
        self.isDisplayingLoginAlert = false
//        
//        self.resultSearchController.loadViewIfNeeded()
//        self.resultNewSearchController.loadViewIfNeeded()
        
        self.resultSearchController.reloadInputViews()
        self.resultNewSearchController.reloadInputViews()
        
        // Refresh control to allow pull to refresh
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.backgroundColor = UIColor(hex: ineligible_grey)
        self.refreshControl?.tintColor = UIColor.white
        
        // Adds action to refresh controller
        // The method retry is called when tableview is pulled down
        self.refreshControl?.addTarget(self, action: #selector(SearchTableViewController.retry), for: UIControl.Event.valueChanged)
        
        // Refresh views
        self.tableView.reloadData()
        self.view.layoutIfNeeded()
        
    }
   
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
    {
        runQuery()
    }
    /// Method for refreshing with refresh control
    /// Note: Do not make private
    @objc func retry() {
        
        // if user refreshes and has not searched, prompt them to type something with a message
        if !self.resultSearchController.isActive || self.resultSearchController.searchBar.text!.isEmpty {
            let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height))
            messageLabel.textColor = UIColor(hex: eb_primary_blue)
            messageLabel.numberOfLines = 0
            messageLabel.textAlignment = .center
            messageLabel.font = UIFont.systemFont(ofSize: 20.0)
            messageLabel.text = "Please Search Before Refreshing"
            messageLabel.sizeToFit()
            
            self.tableView.backgroundView = messageLabel
            self.tableView.separatorStyle = .none
            self.refreshControl?.endRefreshing()
            
        } else {
            getData()
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    fileprivate func getData() {
        
        // Canel old data requests
        dataRequest?.cancel()
        if(segmentControl.selectedSegmentIndex == 1)
        {
            query = self.resultNewSearchController.searchBar.text!
        }
        else
        {
            query = self.resultSearchController.searchBar.text!
        }
        // get query from search bar
        if !query.isEmpty && segmentControl.selectedSegmentIndex == 1
        {
            let baseURL = LoginManager.getBaseURL()
            
            let queryString: String = baseURL + "api/mass_corp_search/\(query)/".addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            actInd.startAnimating()
            
            
            //make async
             self.dataRequest = request(queryString, method: .post, parameters: nil, encoding: URLEncoding.default, headers: nil)
            .responseJSON {
                [unowned self,
                weak refreshControl = self.refreshControl,
                weak tableView = self.tableView,
                weak searchBar = self.resultNewSearchController.searchBar] response in
                
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                
                // hide refresh control
                refreshControl?.endRefreshing()
                
                if let resp = response.response {
                    if resp.statusCode == 401 {
                        
                        self.tableData_newCustomer = nil
                        
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
                } // other error responses
                if response.result.error != nil {
                    self.tableData_newCustomer = nil
                    return }
                
                // if data is returned
                if let data = response.result.value {
                    
                    // create JSON object from raw data
                    var json = JSON(data)
                                        
                    // Verify status code
                    if let statusCode = json["status_code"].int, statusCode == 403 {
                        // Token has expired, prompt to login again
                        self.isDisplayingLoginAlert = true
                        LoginViewManager.refreshToken(self, errorMessage: json["error_message"].string, completion:({
                            [unowned self]
                            (logInSuccessful:Bool) in
                            self.isDisplayingLoginAlert = !logInSuccessful
                            if logInSuccessful {
                                self.getData()
                            }
                            }))
                        
                    }
                        // Successful search
                    else if let statusCode = json["status_code"].int, statusCode == 200 {
                        
                        // get payload within json
                        let payload = json["payload"]

                        // Ensure table data exists and is empty
                        self.tableData_newCustomer = self.tableData_newCustomer ?? []
                        self.tableData_newCustomer?.removeAll(keepingCapacity: false)
                        
                        let results = payload.array ?? []
                        for result in results {
                            
                            self.tableData_newCustomer?.append(SearchResult_newCustomer(json: result))
                        }
                        
                                                if searchBar?.selectedScopeButtonIndex == SearchScope.all.rawValue {
                            self.filteredData_newCustomer = self.tableData_newCustomer!
                           
                        } else if searchBar?.selectedScopeButtonIndex == SearchScope.companiesOnly.rawValue {
                            self.filteredData_newCustomer = self.tableData_newCustomer!.filter({(result:SearchResult_newCustomer) in result.is_company == true}
                            )
                            
                        } else if searchBar?.selectedScopeButtonIndex == SearchScope.individualsOnly.rawValue {
                            self.filteredData_newCustomer = self.tableData_newCustomer!.filter({(result:SearchResult_newCustomer) in result.is_company == false})
                                                    
                        }
                    }
                    
                } else {
                    self.tableData_newCustomer = nil
                }
                
                // refresh tableview
                tableView?.reloadData()
                tableView?.setNeedsDisplay()
                
                self.actInd.stopAnimating()
                
            }
        }
            
        else if !query.isEmpty && segmentControl.selectedSegmentIndex == 0
        {
            
            let baseURL = LoginManager.getBaseURL()
            
            // build query string and escape characters with %
            let queryString: String = baseURL + "api/search/\(query)/".addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
            
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            actInd.startAnimating()
            // make async request and wait on response
             self.dataRequest = request(queryString, method: .post, parameters: nil, encoding: URLEncoding.default, headers: nil)
           .responseJSON {
                [unowned self,
                weak refreshControl = self.refreshControl,
                weak tableView = self.tableView,
                weak searchBar = self.resultSearchController.searchBar] response in
                
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                
                // hide refresh control
                refreshControl?.endRefreshing()
                
                // if we have a response
                
                if let resp = response.response {
                    if resp.statusCode == 401 {
                        
                        self.tableData = nil
                        
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
                } // other error responses
                if response.result.error != nil {
                    self.tableData = nil
                    return }
                
            
                
                // if data is returned
                if let data = response.result.value {
                    
                    // create JSON object from raw data
                    var json = JSON(data)
                    
                    // Verify status code
                    if let statusCode = json["status_code"].int, statusCode == 403 {
                        // Token has expired, prompt to login again
                        self.isDisplayingLoginAlert = true
                        LoginViewManager.refreshToken(self, errorMessage: json["error_message"].string, completion:({
                            [unowned self]
                            (logInSuccessful:Bool) in
                            self.isDisplayingLoginAlert = !logInSuccessful
                            if logInSuccessful {
                                self.getData()
                            }
                            }))
                        
                    } else if let statusCode = json["status_code"].int, statusCode == 200 {
                        
                        // get payload within json
                        let payload = json["payload"]
                        
                        // Ensure table data exists and is empty
                        self.tableData = self.tableData ?? []
                        self.tableData?.removeAll(keepingCapacity: false)
                        
                        let results = payload.array ?? []
                        for result in results {
                            self.tableData?.append(SearchResult(json: result))
                        }
                        if searchBar?.selectedScopeButtonIndex == SearchScope.all.rawValue {
                            self.filteredData = self.tableData!
                        } else if searchBar?.selectedScopeButtonIndex == SearchScope.companiesOnly.rawValue {
                            self.filteredData = self.tableData!.filter({(result:SearchResult) in result.type == "Company"})
                        } else if searchBar?.selectedScopeButtonIndex == SearchScope.individualsOnly.rawValue {
                            self.filteredData = self.tableData!.filter({(result:SearchResult) in result.type == "Person"})}
                    }
                    
                } else {
                    self.tableData = nil
                }
                
                // refresh tableview
                tableView?.reloadData()
                tableView?.setNeedsDisplay()
                
                self.actInd.stopAnimating()
                
            }
            
        }
        else {
            
            self.tableData = nil
            tableView?.reloadData()
            tableView?.setNeedsDisplay()
            
            self.actInd.stopAnimating()
        }
        
        
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
        if segmentControl.selectedSegmentIndex == 0{
            // Check a variety of states and display error message if appropriate
            if !self.resultSearchController.isActive {
                messageLabel.text = "Tap the search bar to search for companies or people."
                messageLabel.sizeToFit()
                
                self.tableView.backgroundView = messageLabel
                self.tableView.separatorStyle = .none
                
                return 0
                
            }
            else if self.resultSearchController.isActive
            {
                return 1
            }
            else if self.resultSearchController.searchBar.text!.isEmpty {
                messageLabel.text = ""
                messageLabel.sizeToFit()
                
                self.tableView.backgroundView = messageLabel
                self.tableView.separatorStyle = .none
                
                return 0
                
                
            } else if tableData == nil && !self.resultSearchController.searchBar.text!.isEmpty {
                messageLabel.text = "Unable to connect to server. Please pull down to retry."
                messageLabel.sizeToFit()
                
                self.tableView.backgroundView = messageLabel
                self.tableView.separatorStyle = .none
                
                return 0
            } else if filteredData.isEmpty  {
                messageLabel.text = "No results found"
                messageLabel.sizeToFit()
                
                self.tableView.backgroundView = messageLabel
                self.tableView.separatorStyle = .none
                return 0
            } else {
                
                // No error found so display 1 section
                
                self.tableView.separatorStyle = .singleLine
                self.tableView.backgroundView?.isHidden = true
                return 1
            }
        }
        if segmentControl.selectedSegmentIndex == 1{
            // Check a variety of states and display error message if appropriate
            if !self.resultNewSearchController.isActive {
                messageLabel.text = "Tap the search bar to search for companies or people."
                messageLabel.sizeToFit()
                
                self.tableView.backgroundView = messageLabel
                self.tableView.separatorStyle = .none
                
                return 0
                
            }
            else if self.resultNewSearchController.isActive
            {
                return 1
            }
            else if self.resultNewSearchController.searchBar.text!.isEmpty {
                messageLabel.text = ""
                messageLabel.sizeToFit()
                
                self.tableView.backgroundView = messageLabel
                self.tableView.separatorStyle = .none
                
                return 0
                
                
            } else if tableData_newCustomer == nil && !self.resultNewSearchController.searchBar.text!.isEmpty {
                messageLabel.text = "Unable to connect to server. Please pull down to retry."
                messageLabel.sizeToFit()
                
                self.tableView.backgroundView = messageLabel
                self.tableView.separatorStyle = .none
                
                return 0
            } else if filteredData_newCustomer.isEmpty  {
                messageLabel.text = "No results found"
                messageLabel.sizeToFit()
                
                self.tableView.backgroundView = messageLabel
                self.tableView.separatorStyle = .none
                return 0
            } else {
                
                // No error found so display 1 section
                
                self.tableView.separatorStyle = .singleLine
                self.tableView.backgroundView?.isHidden = true
                return 1
            }
        }
            
        else
        {
            return 1
        }
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if segmentControl.selectedSegmentIndex == 0{
            // Return the number of rows in the section
            return self.filteredData.count
        }
        else
        {
            
            return self.filteredData_newCustomer.count
        }
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       
        
        if (indexPath.row < filteredData.count ) && segmentControl.selectedSegmentIndex == 0 {
            let result = filteredData[indexPath.row]
            // Build and show either a person cell or company cell depending on type
            
            if result.type == "Person" {
                let cell = tableView.dequeueReusableCell(withIdentifier: "ExistingCustomer_SearchCell", for: indexPath) as! ExistingCustomer_SearchCell
                cell.SearchLabel.text = " "+result.name+" \u{200c}"
                cell.typeView.image = UIImage(named: "SearchPersonIcon")
                // TODO: need to adjust constraints here too
                cell.statusLabel.isHidden = true;
                cell.statusWidth.constant = 0
                cell.statusLabel.isHidden = true;
                cell.statusLabel.text = "";
                return cell
                
            } else if result.type == "Company" {
                let cell = tableView.dequeueReusableCell(withIdentifier: "ExistingCustomer_SearchCell", for: indexPath) as! ExistingCustomer_SearchCell
                cell.SearchLabel.text = result.name
                cell.statusLabel.text = " "+result.label_text+" \u{200c}";
                cell.statusWidth.constant = 120.0
                cell.statusLabel.backgroundColor = UIColor(hex:result.label_color)
                cell.statusLabel.isHidden = false;
                cell.typeView.image = UIImage(named: "SearchCompanyIcon")
                
                return cell
            }
        }
        if (indexPath.row < filteredData_newCustomer.count ) && segmentControl.selectedSegmentIndex == 1 {
            let result = filteredData_newCustomer[indexPath.row]
           
            // Build and show either a person cell or company cell depending on type
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "NewCustomer_SearchCell", for: indexPath) as! NewCustomer_SearchCell
            var eligibilityLabel = "Ineligible"
            var eligibilityColor = ineligible_grey
           
            if(result.is_company)
                
            {
                cell.persondetailsLabel.isHidden = true
                cell.persondetailsLabel.text = ""
                cell.typeView.image=UIImage(named: "SearchCompanyIcon")
                if(result.is_ineligible)
                {
                    eligibilityLabel = "Ineligible"
                    eligibilityColor = ineligible_grey
                }
                else
                {
                    eligibilityLabel = "Eligible"
                    eligibilityColor = eastern_green
                }
                cell.eligibilityLabel.text = eligibilityLabel
                cell.eligibilityLabel.backgroundColor = UIColor(hex:eligibilityColor)
                
            }
            else if(result.is_company == false)
            {
                cell.persondetailsLabel.isHidden = false
                cell.persondetailsLabel.text = result.related_to
                cell.typeView.image=UIImage(named: "SearchPersonIcon")
            }
            
            
            if(result.is_ineligible)
            {
                eligibilityLabel = "Ineligible"
                eligibilityColor = ineligible_grey
            }
            else
            {
                eligibilityLabel = "Eligible"
                eligibilityColor = eastern_green
            }
            
            // if the city is just an empty string or whitespace don't bother displaying it
            let cityTrimmed = result.city.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            var cityLabel = ""
            
            if cityTrimmed == "" {
                cityLabel = ""
            } else {
                cityLabel = " (" + cityTrimmed + ")"
            }
            
            cell.SearchLabel.text = result.name + cityLabel
            cell.eligibilityLabel.text = eligibilityLabel
            cell.eligibilityLabel.backgroundColor = UIColor(hex:eligibilityColor)
            
            return cell
            
        }
        return UITableViewCell()
    }
   
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        
        if(segmentControl.selectedSegmentIndex == 0)
        {
            switch self.resultSearchController.searchBar.selectedScopeButtonIndex {
            case SearchScope.all.rawValue:
                scope = "All"
            case SearchScope.companiesOnly.rawValue:
                scope = "Company"
            case SearchScope.individualsOnly.rawValue:
                scope = "Person"
            default:
                scope = "All"
            }
        } else {
            switch self.resultNewSearchController.searchBar.selectedScopeButtonIndex {
            case SearchScope.all.rawValue:
                scope = "All"
            case SearchScope.companiesOnly.rawValue:
                scope = "Company"
            case SearchScope.individualsOnly.rawValue:
                scope = "Person"
            default:
                scope = "All"
            }
        }
      
        // Refilter data based on newly selected scope
        if(segmentControl.selectedSegmentIndex == 0)
        {
        if let tableData = self.tableData {
            
            
            self.filteredData = tableData.filter({[unowned self] (result: SearchResult) -> Bool in
                return self.scope == "All" || result.type == self.scope
                })
        }
        }
        else
        {
        //Refilter data based on newly selected scope
        if let tableData_newCustomer = self.tableData_newCustomer {
            self.filteredData_newCustomer = tableData_newCustomer.filter({[unowned self] (result: SearchResult_newCustomer) -> Bool in
                return self.scope == "All" || result.is_company == (self.scope == "Company")
                })
        }
        }
        self.actInd.stopAnimating()
        tableView.reloadData()
        tableView.setNeedsDisplay()
        
    }
    
    
    
    // Timer to keep track of time after user types
    fileprivate var timer = Timer()
    
    // called when user types in search bar
    func updateSearchResults(for searchController: UISearchController) {
        // Invalidates active timer, preventing call to runQuery
        if timer.isValid {
            timer.invalidate()
        }
        
        if(segmentControl.selectedSegmentIndex == 1)
        {
            query = self.resultNewSearchController.searchBar.text!
            if(query.characters.count > 5)
            {
                // calls runQuery if user does not type within 0.3 seconds
                timer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(SearchTableViewController.runQuery), userInfo: nil, repeats: false)
            }
            
        }
            // && self.resultSearchController.searchBar.text != query)
       else if(segmentControl.selectedSegmentIndex == 0)
        {
                           // calls runQuery if user does not type within 0.3 seconds
                timer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(SearchTableViewController.runQuery), userInfo: nil, repeats: false)
                
              }
       else
        {
            print("I am doing nothing")
        }
        
    }
    
    
    
    // Timer callback to get data
    @objc func runQuery() {
        // When user changes search query, refresh data
        if (!isDisplayingLoginAlert) {
            getData()
        }
        
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if(segmentControl.selectedSegmentIndex==1 &&  self.filteredData_newCustomer[indexPath.row].is_company == true )
        {
            return NewCustomer_SearchCell.defaultHeight
        }
        if(segmentControl.selectedSegmentIndex==1 && self.filteredData_newCustomer[indexPath.row].is_company == false )
        {
        
            return NewCustomer_SearchCell.expandableHeight
        }
                  else
        {
            return 40.0
        }
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // NC Search
        if segmentControl.selectedSegmentIndex == 1 {
            
            // new customer segues
//            self.company_url_uuid = self.filteredData_newCustomer[indexPath.row].uuid
            
            // if the company is ineligible OR the go_to_company_details flag is true perform the company selected segue to go to company details page
            if(self.filteredData_newCustomer[indexPath.row].is_ineligible == true || self.filteredData_newCustomer[indexPath.row].go_to_company_details == true)
            {
                
                 self.performSegue(withIdentifier: "companySelected", sender: self)
            }
            // if the company is eligible and they don't have an app (so go_to_company_details is false...navigate to NC start app url)
            else
            {
                // else attempt to start an application
                self.performSegue(withIdentifier: "startNCApp", sender: self)
            }
        }
        else
        {
            // Existing Customer Segues
            
            let typeofSegue=self.filteredData[tableView.indexPathForSelectedRow!.row].type
            
            if(typeofSegue=="Person")
            {
                self.performSegue(withIdentifier: "personSelected", sender: self)
            }
            else if(typeofSegue=="Company")
            {
                self.performSegue(withIdentifier: "companySelected", sender: self)
            }
        }
        
    }
    
    //Custom Table View Componenets
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if segmentControl.selectedSegmentIndex == 1{
            (cell as! NewCustomer_SearchCell).watchFrameChanges()
        }
        
        
    }
    
    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if segmentControl.selectedSegmentIndex == 1{
            (cell as! NewCustomer_SearchCell).ignoreFrameChanges()
        }
        
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
       
        if segmentControl.selectedSegmentIndex == 1{
            for cell in tableView.visibleCells as! [NewCustomer_SearchCell] {
                cell.ignoreFrameChanges()
            }
        }
        
        
    }
    
    
    
    // MARK: - Navigation: Segues occur after selcting the row...so uuid/company_url_uuid will be set
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        
      
        // Cancel any pending requests
        dataRequest?.cancel()
        
        // Get and set up next view controller
        if segue.identifier == "personSelected" {
            let destVC = segue.destination as! RelatedCompaniesViewController
            
            let result = self.filteredData[tableView.indexPathForSelectedRow!.row]
            
            destVC.uuid = result.uuid
            
            destVC.title = result.name
            
        }
        
        if segue.identifier == "companySelected" {
            let destVC = segue.destination as! CompanyDetailsViewController
            
            if(segmentControl.selectedSegmentIndex == 0)
            {
            let result = self.filteredData[tableView.indexPathForSelectedRow!.row]
            
            destVC.uuid = result.uuid
            destVC.title = result.name
            }
            // else NC
            else
            {
                destVC.uuid = self.filteredData_newCustomer[tableView.indexPathForSelectedRow!.row].uuid
                
                // for setting the company name on the company details VC...if entry is a person select related_to field
                if self.filteredData_newCustomer[tableView.indexPathForSelectedRow!.row].is_company == true {
                    destVC.title = self.filteredData_newCustomer[tableView.indexPathForSelectedRow!.row].name
                } else {
                    destVC.title = self.filteredData_newCustomer[tableView.indexPathForSelectedRow!.row].related_to
                }
                
                
            }
        }
        
        
        // for NC app starting
        if segue.identifier == "startNCApp" {
        
            let destVC = segue.destination as! WebViewController
            
            destVC.initialUrl = self.filteredData_newCustomer[tableView.indexPathForSelectedRow!.row].start_app_url
            
            
        }
        
    }
    
    
}
