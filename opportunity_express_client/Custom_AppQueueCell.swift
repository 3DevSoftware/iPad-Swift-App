//
//  Custom_AppQueueCell.swift
//  opportunity_express_client
//
//  Created by Miles Clark on 10/08/18.
//  Copyright (c) 2018 Eastern Labs. All rights reserved.
//

import UIKit

class Custom_AppQueueCell: UITableViewCell {
    var isObserving = false;
  
    @IBOutlet weak var companyName: UILabel!
    @IBOutlet weak var primaryApplicant: UILabel!
    @IBOutlet weak var otherApplicants: UILabel!
    @IBOutlet weak var lastModified: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
  
   
}
