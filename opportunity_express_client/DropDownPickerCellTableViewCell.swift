//
//  DropDownPickerCellTableViewCell.swift
//  opportunity_express_client
//
//  Created by Miles Clark on 10/08/18.
//  Copyright (c) 2018 Eastern Labs. All rights reserved.
//

import UIKit

class DropDownPickerCellTableViewCell: UITableViewCell {

    @IBOutlet weak var dropdown_button: UIButton!
    override func awakeFromNib() {
        super.awakeFromNib()
        dropdown_button.layer.borderWidth=1
        dropdown_button.layer.borderColor=UIColor.black.cgColor
        dropdown_button.layer.cornerRadius=5
        
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
