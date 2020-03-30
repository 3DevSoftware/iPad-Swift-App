//
//  CompanyDetailsViewController.swift
//  opportunity_express_client
//
//  Created by Miles Clark on 10/08/18.
//  Copyright (c) 2018 Eastern Labs. All rights reserved.
//

import UIKit
import SwiftyJSON
import Alamofire
import DropDown


/// Struct for encapsulating data about an action
private struct Action {
    
    /**
     Builds Action from json
     
     :param: json JSON object containing action details
     */
    init(json:JSON) {
        self.json = json
        self.url = json["url"].string ?? ""
        self.title = json["title"].string ?? ""
        self.shouldOpenWebView = json["shouldOpenWebView"].bool ?? true
    }

    
    var json: JSON?
    var url = ""
    var title  = ""
    var shouldOpenWebView = true
}

//Json for seperating th eincoming json into keys and values and sort them by index
private struct KeysValues {
    
    /**
     Build Loan_App from json
     
     :param: json JSON object containing loan_app details
     **/
    
    init(json:JSON) {
        self.json = json
        self.keys = json["keys"].string ?? ""
        self.value = json["value"].string ?? ""
        self.index = json["index"].string ?? ""
       
    }
    
    var json: JSON?
    var keys = ""
    var value = ""
    var index = ""
    
}
//AppStrings - strings to display in the drop down
private struct AppStrings {
    
    /**
     Build Loan_App from json
     
     :param: json JSON object containing loan_app details
     **/
    
    init(json:JSON) {
        self.json = json
        self.id = json["id"].string ?? ""
        self.value = json["value"].string ?? ""
    }
    
    var json: JSON?
    var id = ""
    var value = ""
    
}

//JSON for getting loan app details
private struct LoanAppObjects {
    
    /**
     Build Loan_App from json
     
     :param: json JSON object containing loan_app details
     **/
    
    init(app_id:String,app_object:[KeysValues]) {
        self.ID=app_id
        self.value = app_object
    }
    
    var json: JSON?
    var ID = ""
    var value:[KeysValues]=[KeysValues]()
    
}

//Build Offer Objects from json - store them by id -for searching the array of offer objects by id
private struct OfferObjects {
    
    
    
    init(app_id:String,offer_object:[KeysValues]) {
        self.id=app_id
        self.value = offer_object
    }
    
    var json: JSON?
    var id = ""
    var value:[KeysValues]=[KeysValues]()
    
}


class CompanyDetailsViewController: UIViewController,UITableViewDataSource,UITableViewDelegate {
    //Incoming Segue variables
    var uuid = ""
    var signerUuid=""

    //Outlet declarations
    @IBOutlet weak var company_tableView: UITableView!
    
    //Variable declaration
    var dropdownlist: [String] = []
    
    // save request so they can be canceled later on
    var dataRequest:Request?
    
    //Section Headers
    fileprivate var section_headers = ["Company & People","","Actions","Selected Application","Offer Information"]
    fileprivate var paddingHeight:CGFloat = 10
    fileprivate var section_headerHeights:[CGFloat] = [26,10,20,26,26]
    fileprivate var section_footerHeights:[CGFloat] = [20,20,20,20,20]
    fileprivate var section_rowHeights:[CGFloat] = [36,50,60,36,36]
    fileprivate var rowHeight_default = 36
    fileprivate var rowHeight_increase = 50
    fileprivate var rowHeights:[CGFloat] = []
    fileprivate var rowHeights_application:[CGFloat] = []
    fileprivate var section_headerBackground:[String]=[light_grey_hex_color,light_grey_hex_color,white_hex_color,light_grey_hex_color,light_grey_hex_color]
    fileprivate var section_headerText:[String]=[black_hex_color,black_hex_color,black_hex_color,black_hex_color,black_hex_color]
    fileprivate var section_Padding:[String]=[white_hex_color,white_hex_color,white_hex_color,white_hex_color,white_hex_color]
    fileprivate var section_headerView = UIView()
    fileprivate var section_headerLabel = UILabel()
    
    
    //Ofer status string is for the company info section to display a summary of the loan application
    var offer_status_string = "No Offers Available for the Selected Application"
    var action_button_row=0
    fileprivate var hasAttemptedToGetData = false
    var loan_app_index = 0
    
    //Refresh Control for TableView - Defining since the view controller is not  a table view controller
    var refreshControl: UIRefreshControl!
    
    
    //Drop elements initialization
    let drop = DropDown()
    fileprivate var app_strings:JSON=[]
    var active_app_id=""
    
    
    //Initializing json objects
    fileprivate var loan_apps:JSON = []
    fileprivate var actions = [Action]()
    fileprivate var companyObjects = [KeysValues]()
    fileprivate var sorted_companyObjects=[KeysValues]()
    fileprivate var applicationObjects = [KeysValues]()
    fileprivate var sorted_applicationObjects=[KeysValues]()
    fileprivate var offerObjects = [KeysValues]()
    fileprivate var sorted_offerObjects=[KeysValues]()
    fileprivate var app_picker_strings = [AppStrings]()
    fileprivate var offer_strings = [AppStrings]()
    fileprivate var LoanAppsObjects = [LoanAppObjects]()
    fileprivate var OfferAppsObjects = [OfferObjects]()
    
    var isDisplayingLoginAlert: Bool = false
    var actInd : UIActivityIndicatorView = UIActivityIndicatorView(frame: CGRect(x: 0,y: 0, width: 300, height: 300)) as UIActivityIndicatorView
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.dropdownlist.append("No Applications Available")
       
        
        //Registering nibs for custom table view cells with the view controller
        let details_nib = UINib(nibName: "Custom_CompanyDetailsCell", bundle: nil)
        company_tableView.register(details_nib, forCellReuseIdentifier: "Custom_CompanyDetailsCell")
        let dropdown_nib = UINib(nibName: "DropDownPickerCellTableViewCell", bundle: nil)
        company_tableView.register(dropdown_nib, forCellReuseIdentifier: "DropDownPickerCellTableViewCell")
        let actions_nib = UINib(nibName: "Custom_ActionCell", bundle: nil)
        company_tableView.register(actions_nib, forCellReuseIdentifier: "Custom_ActionCell")
        
        //check for if data was obtained before.
        hasAttemptedToGetData = false
        
        // Needed to remove dividers from empty cells at the bottom of the table
        self.company_tableView.tableFooterView = UIView(frame: CGRect.zero)
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(CompanyDetailsViewController.refresh(_:)), for: UIControl.Event.valueChanged)
        self.company_tableView.addSubview(refreshControl) // not required when using UITableViewController
    
        // activity indicator
        self.actInd.transform = CGAffineTransform(scaleX: 2, y: 2);
        self.actInd.center = self.view.center;
        self.actInd.hidesWhenStopped = true;
        self.actInd.style = UIActivityIndicatorView.Style.whiteLarge
        self.actInd.color = UIColor.gray
        self.company_tableView.addSubview(actInd)
        
        self.company_tableView.reloadData()
        self.company_tableView.setNeedsDisplay()
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if !isDisplayingLoginAlert {
            self.getData()
        }
    }
    
    // Method for refreshing with refresh control
    // Note: Do not make private
    @objc func refresh(_ sender:UIRefreshControl) {
        getData()
    }
    override func viewWillDisappear(_ animated: Bool) {
        self.dataRequest?.cancel()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Data request method
     fileprivate func getData() {
       
        actInd.startAnimating()
        self.company_tableView.bringSubviewToFront(actInd)
        // Cancel old requests
        dataRequest?.cancel()
        
        // build string and escape characters with %
        let queryString: String =  LoginManager.getBaseURL() + "api/get-company-details/".addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        // drop signer_uuid eventually
        let parameters = ["uuid": self.uuid, "signer_uuid": self.signerUuid]
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        self.dataRequest = request(queryString, method: .post, parameters: parameters, encoding: URLEncoding.default, headers: nil)
            .responseJSON {
                [unowned self] response in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
               
                // return if error is found
                self.hasAttemptedToGetData = true
                
                // hide refresh control
                self.refreshControl?.endRefreshing()
            
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
            
            // other error responses clear everything
            if response.result.error != nil {
                self.applicationObjects.removeAll(keepingCapacity: false)
                self.offerObjects.removeAll(keepingCapacity: false)
                self.OfferAppsObjects.removeAll(keepingCapacity: false)
                self.companyObjects.removeAll(keepingCapacity: false)
                self.sorted_offerObjects.removeAll(keepingCapacity: false)
                self.sorted_companyObjects.removeAll(keepingCapacity: false)
                self.sorted_applicationObjects.removeAll(keepingCapacity: false)
                self.LoanAppsObjects.removeAll(keepingCapacity: false)
                self.offer_strings.removeAll(keepingCapacity: false)
                self.app_picker_strings.removeAll(keepingCapacity: false)
            
                return
            }
            
                // if data is returned
                if let data = response.result.value {
                    
                    // create JSON object from raw data
                    var json = JSON(data)
                    
                    if let statusCode = json["status_code"].int, statusCode == 403 {
                            // Token has expired, prompt to login again
                            LoginViewManager.refreshToken(self, errorMessage: json["error_message"].string, completion:({[unowned self] (logInSuccessful:Bool) in
                                
                                if logInSuccessful {
                                    self.getData()
                                }
                                }))
                            
                        
                    }
                
                    //If the data returned has 200
                    else if let statusCode = json["status_code"].int, statusCode == 200 {
                        
                        // clear the existing objects
                        self.applicationObjects.removeAll(keepingCapacity: false)
                        self.offerObjects.removeAll(keepingCapacity: false)
                        self.OfferAppsObjects.removeAll(keepingCapacity: false)
                        self.companyObjects.removeAll(keepingCapacity: false)
                        self.sorted_offerObjects.removeAll(keepingCapacity: false)
                        self.sorted_companyObjects.removeAll(keepingCapacity: false)
                        self.sorted_applicationObjects.removeAll(keepingCapacity: false)
                        self.LoanAppsObjects.removeAll(keepingCapacity: false)
                        self.offer_strings.removeAll(keepingCapacity: false)
                        self.app_picker_strings.removeAll(keepingCapacity: false)
                        
                        self.rowHeights=[]
                        
                        // get payload within json
                        let payload = json["payload"]
                        
                        // build and set tableview header
                        //Unpack loan apps from payload
                        self.loan_apps=payload["loan_apps"]

                        //If there are no loan apps - Only show Company Info and Actions
                        if(self.loan_apps.count == 0)
                        {
                            self.dropdownlist=[]
                            self.dropdownlist.append("No applications available")
                            self.companyObjects.removeAll(keepingCapacity: false)
                            for (key,value) in payload["company_info"]
                            {
                                var x =  [String: Any]()
                                x=[
                                    "keys":"",
                                    "value":"",
                                    "index":""
                                    ]
                                
                                x["keys"]=key as AnyObject
                                x["index"]=value["index"]
                                x["value"]=value["value"]
                                
                                self.companyObjects.append(KeysValues(json: JSON(x)))
                                
                            }

                            self.section_footerHeights = [20,20,20,0.01,0.01]
                            self.section_headerHeights = [26,10,20,0.01,0.01]
                            
                            self.section_headerBackground = [light_grey_hex_color,light_grey_hex_color,light_grey_hex_color,light_grey_hex_color,light_grey_hex_color]
                            self.section_headerText = [black_hex_color,black_hex_color,black_hex_color,white_hex_color,white_hex_color]
                            self.section_headers = ["Company & People","","Actions","",""]
                            self.sorted_companyObjects = self.companyObjects.sorted { $0.index.compare($1.index) == .orderedAscending }
                            

                            
                        }
                        //If there are loan apps for the given company - unpack them
                        else {
                                self.dropdownlist = []
                                self.section_footerHeights = [20,20,20,20,20]
                                self.section_headerHeights = [26,10,20,26,26]
                                self.section_headerBackground = [light_grey_hex_color, light_grey_hex_color,light_grey_hex_color, light_grey_hex_color,light_grey_hex_color]
                                self.section_headerText = [black_hex_color, black_hex_color, black_hex_color, black_hex_color, black_hex_color]
                                self.section_headers = ["Company & People","","Actions","Selected Application","Offer Information"]
                            
                            //Getting the ID for the active offer in the loan app payload
                                self.active_app_id = payload["active_app_id"].string ?? ""
                            
                                //Reading the offer string from the payload
                            self.offer_status_string = payload["Offer_String"].string ?? ""
                            
                                //Filling in company Objects and sorted it by index values
                                self.companyObjects.removeAll(keepingCapacity: false)
                                for (key,value) in payload["company_info"]
                                {
                                    var x =  [String: Any]()
                                    x=[
                                        "keys":"",
                                        "value":"",
                                        "index":""
                                    ]
                                    
                                    x["keys"]=key
                                    x["index"]=value["index"].string ?? ""
                                    x["value"]=value["value"].string ?? ""
                                    
                                    self.companyObjects.append(KeysValues(json: JSON(x)))
                                }

                                //Unpack loan apps object to the format {"id":loan_app_id,"app_object":{keys, values}}
                                for loan_app in payload["loan_apps"].array ?? []
                                {
                            
                                    var id_string=""
                                    //Initialize a dummy KeysValues array to hold loan application keys and values
                                    var dummy_applicationObjects=[KeysValues]()
                                    for (key,value) in loan_app
                                    {
                                        var x =  [String: Any]()
                                        x=[
                                            "keys":"",
                                            "value":"",
                                            "index":""
                                        ]
                                        
                                        x["keys"]=key
                                        
                                        if(key=="Loan Application #")
                                        {
                                            id_string=String(value["value"].string ?? "")
                                        }
                                        
                                        x["index"]=String(value["index"].string ?? "")
                                        x["value"]=String(value["value"].string ?? "")
                                        
                                        dummy_applicationObjects.append(KeysValues(json: JSON(x)))
                                
                                    }
                                    
                                    dummy_applicationObjects = dummy_applicationObjects.sorted { $0.index.compare($1.index) == .orderedAscending }
                                    self.LoanAppsObjects.append(LoanAppObjects(app_id:id_string,app_object:dummy_applicationObjects))
                                 }
                            
                            //Unpack offers object to the format {"id":loan_app_id,"offer_object":{keys, values} inside the offer}
                                for offer in payload["offers"].array ?? []
                                {
                            
                                    var id_string=""
                                    var dummy_OfferObjects=[KeysValues]()
                                    for (key,value) in offer
                                    {
                                        var x =  [String: Any]()
                                        x=[
                                            "keys":"",
                                            "value":"",
                                            "index":""
                                        ]
                                        
                                        x["keys"]=key
                                        
                                        if(key=="Loan Application ID")
                                        {
                                            id_string=String(value["value"].string ?? "")
                                        }
                                
                                        x["index"]=String(value["index"].string ?? "")
                                        x["value"]=String(value["value"].string ?? "")
                                        
                                        dummy_OfferObjects.append(KeysValues(json: JSON(x)))
                                
                                    }
                                    dummy_OfferObjects = dummy_OfferObjects.sorted { $0.index.compare($1.index) == .orderedAscending }
                                    self.OfferAppsObjects.append(OfferObjects(app_id:id_string,offer_object:dummy_OfferObjects))
                                }
                            
                                //Unpack app picker strings and store them in a way so that they can be accessed via ID
                                for appString in payload["app_picker_strings"].array ?? []
                                {
                                    self.app_picker_strings.append(AppStrings(json: appString))
                                }
                            
                                for offerString in payload["offer_strings"].array ?? []
                                {
                                    self.offer_strings.append(AppStrings(json: offerString))
                                }
                            
                                self.sorted_applicationObjects.removeAll(keepingCapacity: false)
                            
                                //Get the application object for the active app
                                self.active_app_id=String(payload["active_app_id"].string ?? "")
                            
                                self.sorted_companyObjects = self.companyObjects.sorted { $0.index.compare($1.index) == .orderedAscending }
                                self.loan_app_index=self.LoanAppsObjects.index{$0.ID == self.active_app_id}!
                                self.sorted_applicationObjects=self.LoanAppsObjects[self.loan_app_index].value
                                let index_active_app_string = self.app_picker_strings.index{$0.id == self.active_app_id}!
                                self.dropdownlist.append(self.app_picker_strings[index_active_app_string].value)
                            
                                for i in 0 ..< self.app_picker_strings.count
                                {
                                    if(i != index_active_app_string){
                                    self.dropdownlist.append(self.app_picker_strings[i].value)
                                    }
                                }
                                //If the offers are not zero then get the offer object associated with the active loan app
                                if(payload["offers"].count > 0)
                                {
                                    self.sorted_offerObjects = self.OfferAppsObjects[self.loan_app_index].value
                                    self.sorted_offerObjects.remove(at: 0)
                                }
                            
                                if(payload["offer_strings"].count>0)
                                {
                                   self.offer_status_string = self.offer_strings[self.offer_strings.index{$0.id == self.active_app_id}!].value
                                }
                                for i in 0 ..< self.sorted_companyObjects.count {
                                if(self.sorted_companyObjects[i].value.characters.count > 53)
                                {
                                    self.rowHeights.append(50)
                                }
                                else
                                {
                                    self.rowHeights.append(36)
                                }
                            }
                            for i in 0 ..< self.sorted_applicationObjects.count {
                                if(self.sorted_applicationObjects[i].value.characters.count > 53)
                                {
                                    self.rowHeights_application.append(50)
                                }
                                else
                                {
                                    self.rowHeights_application.append(36)
                                }
                            }
                        
                            }

                            //Unpack Actions
                            let actions = payload["actions"].array ?? []
                            self.actions.removeAll(keepingCapacity: false)
                            for action in actions {
                                self.actions.append(Action(json: action))
                            }

                        
                    }
                    // parse 500 response in payload of the task
                    else if let statusCode = json["status_code"].int, statusCode == 500 {
                    
                        let alertController = UIAlertController(title: "Error", message: "Error Loading Company Details", preferredStyle: .alert)
                        
                        let okAction = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
                        alertController.addAction(okAction)
                        self.present(alertController, animated: true, completion: nil)
                        
                    }
                    
                    self.actInd.stopAnimating()
                    self.company_tableView.reloadData()
             

                }
            

            
        };
        
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

    
    //Table view cell methods
    func tableView(_ tableView:UITableView, numberOfRowsInSection section:Int) -> Int
    {
        //0 - Company Info Section
        if (section == 0)
        {
            return self.sorted_companyObjects.count
        }
        // 1 - Drop down picker section
        else if (section == 1) {
            return 1
        }
        // 2 - Actions Section
        else if (section == 2) {
            if(self.actions.count == 0 )
            {
                self.section_headers[2] = ""
                self.paddingHeight = 0
              
            }
            else
            {
                self.section_headers[2] = "Actions"
                self.paddingHeight = 10
            }
            return self.actions.count
        }
        //3 - Application Info Section
        else if (section == 3) {
            return self.sorted_applicationObjects.count
        }
            
        //4 - Offer Info Section - If there are offers then show section else remove all rows
        else
            
        {
            if(self.sorted_offerObjects.count > 0 && self.LoanAppsObjects.count > 0)
            {
              return (self.sorted_offerObjects.count)
            }
            else if(self.sorted_offerObjects.count == 0 && self.LoanAppsObjects.count > 0)
            {
                return 1
            }
            else if(self.LoanAppsObjects.count == 0)
            {
                self.section_headerHeights[4]=0.1
                self.section_footerHeights[4]=0.1
                return 0
            }
        }
        
        return 1
        
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        //Return the number of section header ==  total number of sections in the view
        return self.section_headers.count
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
        // only allow cell selection for actions
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        //Get the height of the row for each section
       return self.section_rowHeights[indexPath.section]
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
            if (indexPath.section == 0) {
               
                let cell = tableView.dequeueReusableCell(withIdentifier: "Custom_CompanyDetailsCell", for: indexPath) as! Custom_CompanyDetailsCell
                cell.itemLabel.text=String(self.sorted_companyObjects[indexPath.row].keys)
                cell.valueLabel.text=String(self.sorted_companyObjects[indexPath.row].value)
              
                cell.valueLabel.numberOfLines = 0;
                cell.valueLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
                return cell
                
            }
            else if (indexPath.section == 1) {
                let cell = tableView.dequeueReusableCell(withIdentifier: "DropDownPickerCellTableViewCell", for: indexPath) as! DropDownPickerCellTableViewCell
                cell.dropdown_button.setTitle(self.dropdownlist[0], for: UIControl.State())
                drop.anchorView=cell.dropdown_button;
                cell.dropdown_button.addTarget(self, action: #selector(CompanyDetailsViewController.addDropDown(_:)), for: UIControl.Event.touchUpInside)
                return cell
            }
            else if (indexPath.section == 2) {
                let cell = tableView.dequeueReusableCell(withIdentifier: "Custom_ActionCell", for: indexPath) as! Custom_ActionCell
                cell.actionButton.setTitle(actions[indexPath.row].title, for: UIControl.State())
                cell.url=actions[indexPath.row].url
                cell.actionButton.addTarget(self, action: #selector(CompanyDetailsViewController.gotoUrl(_:)), for: UIControl.Event.touchUpInside)
                cell.actionButton.tag = indexPath.row
                return cell
                
            }
            else if (indexPath.section == 3) {
                
                let cell = tableView.dequeueReusableCell(withIdentifier: "Custom_CompanyDetailsCell", for: indexPath) as! Custom_CompanyDetailsCell
                cell.itemLabel.text=String(self.sorted_applicationObjects[indexPath.row].keys)
                cell.valueLabel.text=String(self.sorted_applicationObjects[indexPath.row].value)
                
                return cell
            }
            else if(indexPath.section == 4)
            {
                let cell = tableView.dequeueReusableCell(withIdentifier: "Custom_CompanyDetailsCell", for: indexPath) as! Custom_CompanyDetailsCell
                if(self.sorted_offerObjects.count > 0){
               
                cell.itemLabel.text=String(self.sorted_offerObjects[indexPath.row].keys)
                cell.valueLabel.text=String(self.sorted_offerObjects[indexPath.row].value)
                    
                }
                else
                {
                    cell.itemLabel.text=String(self.offer_status_string)
                    cell.valueLabel.text=""
                }
                
                return cell
        }
            return UITableViewCell()
        
        
    }
    
    @objc func addDropDown(_ sender: UIButton)
    {
        drop.dataSource=self.dropdownlist
        drop.show()
        drop.selectionAction = { [unowned self] (index, item) in
            self.applicationInfo(index)
        }
        
    }
    
    
    func applicationInfo(_ appIndex: Int)
    {
        if(self.LoanAppsObjects.count>0)
        {
         
        let current_picker_index = self.app_picker_strings.index{$0.id == self.active_app_id}!
        let swap_with_index = appIndex
        self.active_app_id = self.app_picker_strings[appIndex].id
        let loan_app_index=self.LoanAppsObjects.index{$0.ID == self.active_app_id}
        self.sorted_applicationObjects=self.LoanAppsObjects[loan_app_index!].value
        let offer_app_index = (self.OfferAppsObjects.index{$0.id == self.active_app_id})
            if(current_picker_index != swap_with_index)
            {
        swap(&app_picker_strings[current_picker_index],&app_picker_strings[swap_with_index])
            }
        self.dropdownlist = []
        self.dropdownlist.append(self.app_picker_strings[self.app_picker_strings.index{$0.id == self.active_app_id}!].value)
            
            for i in 0 ..< self.app_picker_strings.count
            {
                if(i != self.app_picker_strings.index{$0.id == self.active_app_id}!){
                    self.dropdownlist.append(self.app_picker_strings[i].value)
                }
            }
            //If there are no offers in the payload page for a particular app id - then load the offer status string into row 1
        if(offer_app_index != nil)
        {
            self.sorted_offerObjects =  self.OfferAppsObjects[offer_app_index!].value
            self.sorted_offerObjects.remove(at: 0)
        }
        else
        {
            self.sorted_offerObjects = []
            self.offer_status_string = "This application has no offers"
        }
            // refresh actions, app, and offer
            self.company_tableView.reloadData()
        }
    }
    
    @objc func gotoUrl(_ sender:UIButton)
    {
        action_button_row  = sender.tag
        let selectedResults = self.actions[action_button_row]
        
        if(selectedResults.shouldOpenWebView == true)
        {
            self.performSegue(withIdentifier: "showWebView", sender: self)
        }
        else if (selectedResults.title.range(of: "AAN") != nil)
        {
            
            let aanAlert: UIAlertController = UIAlertController(title: "AAN Request", message: "Please Confirm this AAN request", preferredStyle: .alert)
            
            let confirmAction = UIAlertAction(title: "Confirm", style: .default, handler: { (action) -> Void in
                
                // if the selected result is to request an AAN
                self.doAANactions(selectedResults.url)
            
            })
            
            let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .destructive, handler: { (action) -> Void in })
            
            aanAlert.addAction(confirmAction)
            aanAlert.addAction(cancelAction)
            
            self.present(aanAlert, animated: true, completion: nil)
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return self.section_footerHeights[section]
  }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return self.section_headerHeights[section]
    }
    
     func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if(section==0 || section == 3 || section == 4 ) {
            
            return returnFooterView("", labelfontSize: 0, labelHeight: self.section_footerHeights[section], backgroundColour: white_hex_color , textColour: white_hex_color, paddingColor: self.section_Padding[section])
            
        }
        else
        {
             return returnFooterView("", labelfontSize: 0, labelHeight: self.section_footerHeights[section], backgroundColour: white_hex_color , textColour: white_hex_color, paddingColor:self.section_Padding[section] )
        }
       
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if(section==0 || section == 3 || section == 4 ) {
            
            return returnView(self.section_headers[section], labelfontSize: 20, labelHeight: self.section_headerHeights[section], backgroundColour:  self.section_headerBackground[section],textColour: self.section_headerText[section])
        
        }
        if(section == 2)
        {
            return returnView(self.section_headers[section], labelfontSize: 20, labelHeight: self.section_headerHeights[section], backgroundColour:  white_hex_color, textColour: self.section_headerText[section])
        }
        
        return UIView.init(frame: CGRect.zero)
        
    }
    
    func changeOffer(_ sender:UIButton)
    {
        _=sender.tag
    }
    
    func returnView(_ labelString:String,labelfontSize:CGFloat,labelHeight:CGFloat,backgroundColour:String,textColour:String) -> UIView?
    {
        let view_create = UIView()
        let padding_label = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: labelHeight-labelfontSize/2))
        padding_label.text = ""
        let label_create = UILabel(frame: CGRect(x: 8, y: 0, width: 300, height: labelHeight))
        label_create.textAlignment = NSTextAlignment.left
        label_create.font = UIFont(name: "HelveticNeue-Bold", size: labelfontSize)
        label_create.text = labelString
        label_create.textColor = UIColor(hex:textColour)
        label_create.font = label_create.font.withSize(labelfontSize)
        //view_create.addSubview(padding_label)
        view_create.addSubview(label_create)
        view_create.backgroundColor = UIColor(hex:backgroundColour)
        return view_create
    }
    func returnFooterView(_ labelString:String,labelfontSize:CGFloat,labelHeight:CGFloat,backgroundColour:String,textColour:String,paddingColor:String) -> UIView?
    {
        let view_create = UIView()
        let label_create = UILabel(frame: CGRect(x: 8, y: self.paddingHeight, width: 300, height: labelHeight-self.paddingHeight))
        label_create.textAlignment = NSTextAlignment.left
        label_create.font = UIFont(name: "HelveticNeue-Bold", size: labelfontSize)
        label_create.text = labelString
        label_create.textColor = UIColor(hex:textColour)
        label_create.font = label_create.font.withSize(labelfontSize)
        let padding_label =  UILabel(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.paddingHeight))
        padding_label.text = ""
        padding_label.backgroundColor = UIColor(hex: paddingColor)
        view_create.addSubview(padding_label)
        view_create.addSubview(label_create)
        view_create.backgroundColor = UIColor(hex:backgroundColour)
        return view_create
    }
    
    //Segue methods
    func doAANactions(_ selectedurl:String) {
        // Do a POST request instead
        
        // TODO: Attach parameters to Action class so they can be
        let parameters = ["company_uuid": self.uuid]
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        self.dataRequest?.cancel()
        
        self.dataRequest = request(selectedurl, method: .post, parameters: parameters, encoding: URLEncoding.default, headers: nil)
            .responseJSON {
            [unowned self, weak refreshControl = self.refreshControl!] response in
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            
            self.hasAttemptedToGetData = true
            
            // hide refresh control
            refreshControl?.endRefreshing()
            
            if response.response!.statusCode == 401 {
                
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
            } // other errors
             else if response.result.error != nil {
                
                let alertController: UIAlertController = UIAlertController(title: "Error", message: "Could not request AAN. Please try again later.", preferredStyle: .alert)
                let okAction: UIAlertAction = UIAlertAction(title: "OK", style: .cancel) { action -> Void in
                    // Dismiss UIAlert
                }
                alertController.addAction(okAction)
                self.present(alertController, animated: true, completion: nil)
                return
            }
            
            // if data is returned
            if let data = response.result.value {
                
                // create JSON object from raw data
                var json = JSON(data)

                // Verify status code
                if let statusCode = json["status_code"].int, statusCode == 200 {
                    
                    let alertController: UIAlertController = UIAlertController(title: "Success", message: "Your AAN request was successfully submitted.", preferredStyle: .alert)
                    let okAction: UIAlertAction = UIAlertAction(title: "OK", style: .cancel) { action -> Void in
                       self.getData()                    }
                    alertController.addAction(okAction)
                    self.present(alertController, animated: true, completion: nil)
                    
                    return
                    
                } else {
                    
                    let alertController: UIAlertController = UIAlertController(title: "Error", message: "Could not request AAN. Please try again later.", preferredStyle: .alert)
                    let okAction: UIAlertAction = UIAlertAction(title: "OK", style: .cancel) { action -> Void in
                        self.getData()
                    }
                    alertController.addAction(okAction)
                    self.present(alertController, animated: true, completion: nil)
                    
                    return
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showWebView" {
            let destVC = segue.destination as! WebViewController
            let selectedResult = self.actions[action_button_row]
            destVC.initialUrl =  selectedResult.url
            destVC.company_uuid = self.uuid;
            destVC.hidesBottomBarWhenPushed = true
        }
    }

   

 

}
