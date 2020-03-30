//
//  NewCustomer_SearchCell.swift
//  opportunity_express_client
//
//  Created by Miles Clark on 10/08/18.
//  Copyright (c) 2018 Eastern Labs. All rights reserved.
//

import UIKit

class NewCustomer_SearchCell: UITableViewCell {
    var isObserving=false;
    
    @IBOutlet weak var SearchLabel: UILabel!
    @IBOutlet weak var typeView: UIImageView!
    @IBOutlet weak var persondetailsLabel: UILabel!
    @IBOutlet weak var eligibilityLabel: UILabel!
    @IBOutlet weak var companyIcon: UIImageView!
    @IBOutlet weak var companyEligibilityLabel: UILabel!
    class var expandableHeight : CGFloat { get {return 75} }
    class var defaultHeight: CGFloat {
        get {return 45}
    }
    func watchFrameChanges() {
        if !isObserving {
            addObserver(self, forKeyPath: "frame", options: [NSKeyValueObservingOptions.new, NSKeyValueObservingOptions.initial], context: nil)
            isObserving = true;
        }
    }
    
    func ignoreFrameChanges() {
        if isObserving {
            removeObserver(self, forKeyPath: "frame")
            isObserving = false;
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "frame" {
            checkHeight()
        }
    }

    func checkHeight() {
        persondetailsLabel.isHidden = (frame.size.height < NewCustomer_SearchCell.expandableHeight)
        companyIcon.isHidden = (frame.size.height < NewCustomer_SearchCell.expandableHeight)
        //companyEligibilityLabel.hidden = (frame.size.height < NewCustomer_SearchCell.expandableHeight)
    
    
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
