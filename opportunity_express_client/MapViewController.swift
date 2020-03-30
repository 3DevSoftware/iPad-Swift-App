//
//  ViewController.swift
//  MapKit
//
//  Created by Miles Clark on 10/08/18.
//  Copyright (c) 2018 Eastern Labs. All rights reserved.

import UIKit



class MapViewController : UIViewController {
    

    @IBOutlet weak var webView: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Google Maps"
        let url_to_request = URL(string: "https://maps.google.com")
        let requestObj = URLRequest(url: url_to_request!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15.0);
        webView.loadRequest(requestObj);
        
    }
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews();
        
        webView.scrollView.contentInset = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0);
        //Web_View.frame = self.view.bounds
    }

}
