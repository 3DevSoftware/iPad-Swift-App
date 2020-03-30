//
//  HelpWebViewController
//

import UIKit
import WebKit
import Spring
//TODO: Change Name to WebBrowserViewController
///  View controller for displaying different help pages
class HelpWebViewController: UIViewController, UITextFieldDelegate, WKNavigationDelegate {
    
    @IBOutlet weak var addressbar: DesignableTextField!
    @IBOutlet weak var search_button: UIButton!
    
    @IBOutlet weak var bottomToolbar: UIToolbar!
    @IBOutlet weak var backbutton: UIBarButtonItem!
    @IBOutlet weak var forwardButton: UIBarButtonItem!
//    @IBOutlet weak var HomeButton: DesignableButton!
    
    
    @IBOutlet weak var swipey_button: UIBarButtonItem!
    @IBOutlet weak var homeButton: UIBarButtonItem!
    @IBOutlet weak var clearButton: DesignableButton!
   
    static let homeURL = EasternBankHomeUrl
    var url: String = ""
    
    var showSearch = false
    var baseGoogleSearchURL = "https://google.com/search?q="
    var Web_View =  WKWebView()
    
    var actInd : UIActivityIndicatorView = UIActivityIndicatorView(frame: CGRect(x: 0,y: 0, width: 300, height: 300)) as UIActivityIndicatorView
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // add webview
        self.Web_View = WKWebView(frame: CGRect(x: 0, y: 107, width: self.view.bounds.width, height: self.view.bounds.height-200))
        self.view.addSubview(Web_View)
        
        switch LoginManager.getEnvironment() {
        case .prod:
            break
        case .staging:
            let width = self.view.frame.width;
            let height = CGFloat(200);
            let xpos = CGFloat(0.0);
            let ypos = self.view.frame.height / 3.0;
            let rect = CGRect(x: xpos,y: ypos,width: width, height: height);
            let envLabel = LoginManager.getTestEnvironmentLabel(rect);
            self.view.addSubview(envLabel);
        }
        
        // activity indicator
        self.actInd.transform = CGAffineTransform(scaleX: 2, y: 2);
        self.actInd.center = self.view.center;
        self.actInd.hidesWhenStopped = true;
        self.actInd.style = UIActivityIndicatorView.Style.whiteLarge
        self.actInd.color = UIColor.gray
        
        // add the activity indicator to the Web View
        self.Web_View.addSubview(self.actInd)
        
        self.addressbar.delegate = self
        self.Web_View.navigationDelegate = self
        
        if self.url == "" {
            load_url(HelpWebViewController.homeURL)
        } else {
            load_url(url) }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews();
        
        Web_View.scrollView.contentInset = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0);
        
        //Web_View.frame = self.view.bounds
    }
    
    @IBAction func load_swipey(_ sender: AnyObject) {
        // needs a rename
        let bankers_lead_url = LoginManager.getLeadURL()!
        
        // this view should only be hitting express...if it's pointing somewhere else direct to base url
        if bankers_lead_url.contains(LoginManager.getBaseURL()) {
          
            load_url(bankers_lead_url);
            
        } else {
            load_url(LoginManager.getBaseURL());
            
        }
    }
    
    @IBAction func search_action(_ sender: AnyObject) {
        
        if let entered_url = self.addressbar.text {
            load_url(entered_url)
            
        } else {
            // present alert? or direct to google?
            return
        }
    }
    
    
    @IBAction func clearAddressBar(_ sender: AnyObject) {
        self.addressbar.text = ""
    }
    
    @IBAction func goRefresh(_ sender: AnyObject) {
        self.Web_View.reload()
    }
    
    @IBAction func goHome(_ sender: AnyObject) {
        load_url(HelpWebViewController.homeURL)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.addressbar.text = String(describing: self.Web_View.url!)
        self.actInd.stopAnimating()
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        
        let alert = UIAlertController(title: "Error Loading Page", message: nil, preferredStyle: UIAlertController.Style.alert)
        
        let errorAction = UIAlertAction(title: "Go Home", style: UIAlertAction.Style.default, handler: {[unowned self] (alert) in
            self.goHome(self);
            })
        
        alert.addAction(errorAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        self.actInd.startAnimating()
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    @IBAction func goNext(_ sender: AnyObject) {
        self.Web_View.goForward()
    }
    @IBAction func goPrevious(_ sender: AnyObject) {
        self.Web_View.goBack()
    }
    
    func load_url(_ entered_url_str:String) {
        
        var request_string = ""
        
        // if the entered text looksl ike a search forward to google
        if looksLikeSearchTerm(entered_url_str) {
            let google_search = entered_url_str.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
            let google_search_url = self.baseGoogleSearchURL + google_search!
            request_string = google_search_url
        } else {
            if !entered_url_str.hasPrefix("http") {
                request_string = "http://" + entered_url_str;
            } else {
                request_string = entered_url_str }
        }
        
        // after some checking/adding http let's try to create an NSURL object and load it
        if let url_to_request = URL(string: request_string) {
            // build an NSURL object and try to load it
            let requestObj = URLRequest(url: url_to_request, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15.0);
            Web_View.load(requestObj);
            self.addressbar.text = url_to_request.absoluteString
        }
        
        else {
            
            // something went wrong as to go to google or cancel
            let ac = UIAlertController(title: "URL Error", message: "Could not request URL: Go to Google?", preferredStyle: .alert)
            
            let okAction: UIAlertAction = UIAlertAction(title: "OK", style: .default) {
                
                [unowned self] action -> Void in
                self.load_url("https://google.com/")
            }
            
            let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { action -> Void in })
            
            ac.addAction(okAction)
            ac.addAction(cancelAction)
            // pop alert
            self.present(ac, animated: true, completion: nil)
            
        }
    }
    
    
    func looksLikeSearchTerm(_ entered_text: String) -> Bool {
        // this will cover the large majority of the logic in figuring out whether the person is searching
        // or trying to navigate to a url
        if entered_text.contains(" ") || entered_text == "" {
            return true }
        else if !entered_text.contains(".") && entered_text.contains("http") {
            return false
        }
        else if !entered_text.contains(".") && !entered_text.contains(" ") {
            return true
        }
        return false
    }
    
    
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        // set keyboard params when editing
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == addressbar {
            search_button.sendActions(for: UIControl.Event.touchUpInside)
            textField.resignFirstResponder()
            return false
        }
        return true
    }
    

}
