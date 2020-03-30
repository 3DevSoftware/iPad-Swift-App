//
//  ExistingCustomer_SearchCell.swift
//  opportunity_express_client
//
//  Created by Miles Clark on 10/08/18.
//  Copyright (c) 2018 Eastern Labs. All rights reserved.
//

import UIKit

class ExistingCustomer_SearchCell: UITableViewCell {
    var isObserving=false
    
    @IBOutlet weak var statusWidth: NSLayoutConstraint!
    @IBOutlet weak var SearchLabel: UILabel!
    @IBOutlet weak var typeView: UIImageView!
    @IBOutlet weak var statusLabel: UILabel!
   // @IBOutlet weak var labelView: UIView!
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
       
               // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }

    
}
