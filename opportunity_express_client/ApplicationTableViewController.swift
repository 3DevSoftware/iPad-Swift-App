//
//  ApplicationTableViewController.swift
//  opportunity_express_client
//
//  Created by Miles Clark on 10/08/18.
//  Copyright (c) 2018 Eastern Labs. All rights reserved.
//

import UIKit

import Alamofire
import SwiftyJSON

//let cellID = "cell"

///  Table view controller for displaying a "dashboard" or queue of the logged in banker's applications
class ApplicationTableViewController: UITableViewController, UISearchResultsUpdating, UISearchBarDelegate {
    var selectedIndexPath : IndexPath?
    var tag_to_segue: Int = 0
    // For storing complete list of applications returned by server
    // Its optional value is used to indicate connection/DB return failures
    var tableData: [Application]? = [Application]()
    
    // Used to store filtered values from searching
    var filteredData = [Application]()
    
    // handles searching
    var resultSearchController = UISearchController()
    
    // save requests to cancel old ones
    var dataRequest:Request?
    
    fileprivate var hasAttemptedToGetData = false
    
    var isDisplayingLoginAlert = false
    
    
    // start loading data before view appears
    override func viewWillAppear(_ animated: Bool) {
        getData()
       
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        //Registering Custom Table cell with the table view
        let nib = UINib(nibName: "Custom_AppQueueCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "Custom_AppQueueCell")
        hasAttemptedToGetData = false
        
        // Set the title in the NavBar
        self.title = "Applications"
        
        // Needed to remove dividers from empty cells at the bottom of the table
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        // Let this view define presentation context
        self.definesPresentationContext = true
        self.resultSearchController.loadViewIfNeeded()
        // Build and style a search controller and its search bar
        self.resultSearchController = ({
            [unowned self] in
            let controller = UISearchController(searchResultsController: nil)
            controller.searchResultsUpdater = self
            controller.dimsBackgroundDuringPresentation = false
            controller.hidesNavigationBarDuringPresentation = false
            
            let searchBar = controller.searchBar
            
            searchBar.placeholder = "Filter by company or applicant name or company CIS"
            searchBar.searchBarStyle = .default
            searchBar.returnKeyType = .search
            searchBar.tintColor = UIColor(hex: eb_primary_blue)
            searchBar.delegate = self
            searchBar.sizeToFit()
            
            return controller
            })()
        
        self.resultSearchController.reloadInputViews()
        
        // Refresh control to allow pull to refresh
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.backgroundColor = UIColor(hex: eb_primary_blue)
        self.refreshControl?.tintColor = UIColor.white
        
        // Adds action to refresh controller
        // The method retry is called when tableview is pulled down
        self.refreshControl?.addTarget(self, action: #selector(ApplicationTableViewController.retry), for: UIControl.Event.valueChanged)
        
//         getData()
        // Refresh views
        self.tableView.reloadData()
        self.tableView.setNeedsDisplay()
        self.view.layoutIfNeeded()
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
    
    /// Method for refreshing with refresh control
    /// Note: Do not make private
    @objc func retry() {
        getData()
    }
   
    /**
     Gets data from url and builds tableview data as appropriate
     
     - parameter filter: optional boolean to indicate whether data should be filtered
     */
    fileprivate func getData(_ filter:Bool = false) {
          let activityIndicator = UIActivityIndicatorView(frame:  CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height))
        if !self.hasAttemptedToGetData {
            // Show activity indicator when fetching data
          
            activityIndicator.style = UIActivityIndicatorView.Style.gray
            activityIndicator.sizeToFit()
            self.tableView.backgroundView = activityIndicator
            activityIndicator.hidesWhenStopped = true
            activityIndicator.startAnimating()
            self.tableView.setNeedsDisplay()
        }
        
        // Cancel old data request
        dataRequest?.cancel()
        
        
        // build query string and escape characters with %
        let appQueueRoute: String = LoginManager.getBaseURL() + "api/get-app-queue/".addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        // make async request and wait on response
          self.dataRequest = request(appQueueRoute, method: .get, parameters: nil, encoding: URLEncoding.default, headers: nil)
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
             if response.result.error != nil {
                
                self.tableData = nil
                return
            }
            
            // if data is returned
            if let data = response.result.value {
                
                // create JSON object from raw data
                var json = JSON(data)
                
                // Verify status code
                if let statusCode = json["status_code"].int, statusCode == 403 {
                    // Token has expired, prompt to login again
                    LoginViewManager.refreshToken(self, errorMessage: json["error_message"].string, completion:({[unowned self] (logInSuccessful:Bool) in
                        self.hasAttemptedToGetData = false
                        
                        if logInSuccessful {
                            self.getData(filter)
                        }
                        }))
                    
                    
                } else if let statusCode = json["status_code"].int, statusCode == 200 {
                    
                    // get payload within json
                    let payload = json["payload"]
                    
                    // empty tableData if it exists
                    self.tableData = self.tableData ?? []
                    self.tableData?.removeAll(keepingCapacity: false)
                    
                    // get array of applications in json from payload
                    let applications = payload.array ?? []
                    
                    // iterate through JSON
                    for appJSON in applications {
                        
                        // create applications and add them to table data
                        self.tableData?.append(Application(json: appJSON))
                    }
                    
                    
                    self.filteredData = self.tableData ?? []
                    
                    // if search bar is active, filter data based on search string
                    if filter {
                        
                        let searchText = self.resultSearchController.searchBar.text
                        
                        self.filteredData = self.tableData?.filter({(app:Application) -> Bool in
                            
                            // filter by company name, cis, and applicant name
                            let compNameMatch = app.companyName.range(of: searchText!) != nil
                            let cisMatch = app.cis.range(of: searchText!) != nil
                            var applicantMatch = false
                            for applicant in app.allApplicants {
                                applicantMatch = applicantMatch || applicant.name.range(of: searchText!) != nil
                            }
                            
                            return compNameMatch || cisMatch || applicantMatch
                        }) ?? []
                    }
                }
            } else {
                self.tableData = nil
            }
            activityIndicator.stopAnimating()
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
        messageLabel.textColor = UIColor(hex: "#003366")
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.font = UIFont.systemFont(ofSize: 20.0)
        messageLabel.sizeToFit()
        
        // Check a variety of states and display error message if appropriate
        if !self.hasAttemptedToGetData {
            
            self.tableView.separatorStyle = .none
            
            self.view.layoutIfNeeded()
            
            return 0
            
        } else if tableData == nil {
            messageLabel.text = "Unable to connect to server. Please pull down to retry."
            messageLabel.sizeToFit()
            
            self.tableView.backgroundView = messageLabel
            self.tableView.separatorStyle = .none
            
            self.tableView.tableHeaderView = nil
            self.view.layoutIfNeeded()
            
            return 0
        } else if filteredData.isEmpty && !self.resultSearchController.isActive {
            messageLabel.text = "No results found"
            messageLabel.sizeToFit()
            
            self.tableView.backgroundView = messageLabel
            self.tableView.separatorStyle = .none
            
            self.tableView.tableHeaderView = nil
            self.view.layoutIfNeeded()
            
            return 0
        } else {
            
            // no error found so show search bar and display 1 section
            
            self.tableView.separatorStyle = .singleLine
            self.tableView.backgroundView?.isHidden = true
            
            if self.tableView.tableHeaderView == nil {
                self.tableView.tableHeaderView = self.resultSearchController.searchBar
                self.view.layoutIfNeeded()
            }
            
            return 1
        }
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // Return the number of rows in the section.
        return self.filteredData.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // build and return cell
        
        let cell:Custom_AppQueueCell = self.tableView.dequeueReusableCell(withIdentifier: "Custom_AppQueueCell") as! Custom_AppQueueCell
        if (indexPath.row < filteredData.count) {
            let app = filteredData[indexPath.row]
            cell.companyName.text = app.companyName + "  ( \(app.app_type_text) )"
            cell.primaryApplicant.text = (app.primaryApplicantName)
            cell.otherApplicants.text = (app.otherApplicantNames)
            cell.lastModified.text = (app.lastModified)
            cell.statusLabel.text = (app.statusMessage)
            cell.statusLabel.textColor = UIColor(hex: app.state_label_color)
            
        }
        return cell
    }
   
    
    func updateSearchResults(for searchController: UISearchController) {
        
        // if search is empty, reset filtered data
        if searchController.searchBar.text!.isEmpty {
            self.filteredData = self.tableData ?? []
        } else {
            
            // filter
            let searchText = self.resultSearchController.searchBar.text!.uppercased()
            
            self.filteredData = self.tableData?.filter({(app:Application) -> Bool in
                
                // filter by company name, cis, and applicant name
                let compNameMatch = app.companyName.range(of: searchText) != nil
                let cisMatch = app.cis.range(of: searchText) != nil
                var applicantMatch = false
                for applicant in app.allApplicants {
                    applicantMatch = applicantMatch || applicant.name.uppercased().range(of: searchText) != nil
                }
                
                return compNameMatch || cisMatch || applicantMatch
            }) ?? []
        }
        
        // refresh tableView
        self.tableView.reloadData()
        self.tableView.setNeedsDisplay()
    }
    
   
    // MARK: - Navigation
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            tag_to_segue=indexPath.row
            tableView.deselectRow(at: indexPath, animated: true)
            self.performSegue(withIdentifier: "applicationSelected", sender: self)
    }
    
   
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // Cancel any pending request
        dataRequest?.cancel()
        
        // prepare for transition to next VC
        if segue.identifier == "applicationSelected" {
            let destVC = segue.destination as! CompanyDetailsViewController
            
            let selectedResult = self.filteredData[tag_to_segue]
            
            destVC.title = selectedResult.companyName
            destVC.uuid = selectedResult.uuid
            
        }
        
    }
    
    
}
