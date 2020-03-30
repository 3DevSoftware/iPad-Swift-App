//
//  Custom_ActionCell.swift
//  opportunity_express_client
//
//  Created by Miles Clark on 10/08/18.
//  Copyright (c) 2018 Eastern Labs. All rights reserved.
//

import UIKit

class Custom_ActionCell: UITableViewCell {

   @IBOutlet weak var actionButton: UIButton!
    var url=""
    override func awakeFromNib() {
        super.awakeFromNib()
         actionButton.layer.cornerRadius=5.0
         actionButton.backgroundColor = UIColor(hex: eastern_green)
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
   
}
