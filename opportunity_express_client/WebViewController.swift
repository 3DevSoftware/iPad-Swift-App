//
//  WebViewController.swift
//  opportunity_express_client
//
//  Created by Miles Clark on 10/08/18.
//  Copyright (c) 2018 Eastern Labs. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import Spring
class WebViewController: UIViewController, UIWebViewDelegate,UIScrollViewDelegate {
    
    var initialUrl = ""
    var company_uuid = ""
    
    var recentAuthedRoute = ""
    
    var refreshControl = UIRefreshControl()
    var isDisplayingLoginAlert: Bool = false
    
    var requestObj: URLRequest!
    
    @IBOutlet weak var addressBar: DesignableTextField!
    
    var actInd : UIActivityIndicatorView = UIActivityIndicatorView(frame: CGRect(x: 0,y: 0, width: 300, height: 300)) as UIActivityIndicatorView
    
    @IBOutlet weak var webView: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        self.view.backgroundColor = UIColor(hex:"#1B3D69")
        
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
        
        // add ability to pull down to refresh
        let refreshController:UIRefreshControl = UIRefreshControl()
        refreshController.bounds = CGRect(x: 0, y: 50, width: refreshController.bounds.size.width, height: refreshController.bounds.size.height) // Change position of refresh view
        refreshController.addTarget(self, action: #selector(WebViewController.refreshWebView(_:)) , for: UIControl.Event.valueChanged)
        refreshController.attributedTitle = NSAttributedString(string: "Pull down to refresh...")
        self.webView.scrollView.addSubview(refreshController)
        
        //attempt to disable caching
        URLCache.shared.removeAllCachedResponses()
        URLCache.shared.diskCapacity = 0
        URLCache.shared.memoryCapacity = 0
       
        // activity indicator
        self.actInd.transform = CGAffineTransform(scaleX: 2, y: 2);
        self.actInd.center = self.view.center;
        self.actInd.hidesWhenStopped = true;
        self.actInd.style = UIActivityIndicatorView.Style.whiteLarge
        self.actInd.color = UIColor.gray
        
        // add the activity indicator to the webview
        self.webView.addSubview(self.actInd)
        
        let url = URL (string: initialUrl)
        self.requestObj = URLRequest(url: url!, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 10.0)
        self.webView.scrollView.delegate = self
        
        load_request()
        
    }
    

    @objc func refreshWebView(_ refresh:UIRefreshControl){
        self.webView.reload()
        refresh.endRefreshing()
    }
    
    
    func load_request() {
        self.webView.loadRequest(self.requestObj)
    }
    
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        // set text of the label/bar here to this value below that we're printing out
        self.addressBar.text = self.webView.request?.url?.absoluteString ?? ""
        self.actInd.startAnimating()
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        // set text of the label/bar here to this value below that we're printing out
        self.addressBar.text = self.webView.request?.url?.absoluteString ?? ""
        self.actInd.stopAnimating()
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        
        
        // Alert user of failure to load request
        let alert = UIAlertController(title: "Error Loading Page", message: "\(self.initialUrl)", preferredStyle: UIAlertController.Style.alert)
        
        let errorAction = UIAlertAction(title: "Go Back", style: UIAlertAction.Style.default, handler: {[unowned self] (alert) in
            
            self.actInd.stopAnimating()
            self.navigationController?.popViewController(animated: true);
            })
        
        alert.addAction(errorAction)
        self.present(alert, animated: true, completion: nil)
        
    }
    
    
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebView.NavigationType) -> Bool {
        
        // If we get a redirect to the company detail page (which is on the banker app)
        if request.url?.absoluteString.lowercased().range(of: "/company/details") != nil {
            
            let urlRequested = request.url?.absoluteString ?? ""
            
            self.company_uuid = getUUIDFromURL(urlRequested )
            
            if let vcStack = self.navigationController?.viewControllers {
                
                // pop the WebViewController (this goes back to search which kicks off a search task)
                self.navigationController?.popViewController(animated: true)
                
                // if you got to the WV controller directly from search (NC) create a CompDetailsVC for
                // the NC and push it to the VC stack
                if vcStack[vcStack.count - 2] is SearchTableViewController {
                    
                    let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "compDetails") as! CompanyDetailsViewController
                    
                    if self.company_uuid != "" {
                        vc.uuid = self.company_uuid
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                }
            }
        }
        
        // if the requested URL does not contain company/details try to load
       return true
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews();
    }
    

    func getUUIDFromURL(_ url_requested: String) -> String {
return ""
//        let detailsInd = url_requested.range(of: "details/")?.upperBound
//        let uuidURL = String(url_requested.characters.suffix(from: detailsInd!))
//        let slashRange = String.CharacterView.index((uuidURL.range(of: "/")?.upperBound)!, offsetBy: -1)
//        let uuid = String(uuidURL.characters.prefix(upTo: slashRange))
//
//        return uuid
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
