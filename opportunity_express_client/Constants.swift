//
//  Constants.swift
//  opportunity_express_client
//
//  Created by Miles Clark on 10/08/18.
//  Copyright (c) 2018 Eastern Labs. All rights reserved.
//

import Foundation
import UIKit
import WebKit

let EasternBankHomeUrl = "https://www.easternbank.com/"

// Hex Colors to use with UIColor(hex: ) extension from Spring
let eb_primary_blue: String = "#003366";
let eb_light_blue: String = "#007791";
let dark_eb_blue: String = "#062651";
let login_success_green: String = "#10d200";
let hexwhite: String = "#FFFFFF";
let hexRed: String = "#DD0000";
let eastern_red:String = "#A30609";
let eastern_orange: String = "#E4843E";
let eastern_green: String = "#5F8E2F";

let eligible_green: String = "#085205";
let ineligible_grey: String = "#b8b8b8";

let sysblue: String = "#007AFF";
let white_hex_color: String = "#FFFFFF";
let black_hex_color: String = "#000000";
let light_grey_hex_color: String = "#EFEFF4";

let device_name = UIDevice.current.name + " ( " + UIDevice.current.systemName + " ver. " + UIDevice.current.systemVersion + " )"

let versionString = Bundle.main.infoDictionary!["CFBundleShortVersionString"]
let buildString = Bundle.main.infoDictionary!["CFBundleVersion"]


// extension to charset to allow printing
extension CharacterSet {
    var characters:[String] {
        var chars = [String]()
        for plane:UInt8 in 0...16 {
            if self.hasMember(inPlane: plane) {
                let p0 = UInt32(plane) << 16
                let p1 = (UInt32(plane) + 1) << 16
                for c:UTF32Char in p0..<p1 {
                    if self.contains(UnicodeScalar(c)!) {
                        var c1 = c.littleEndian
                        let s = NSString(bytes: &c1, length: 4, encoding: String.Encoding.utf32LittleEndian.rawValue)!
                        chars.append(String(s))
                    }
                }
            }
        }
        return chars
    }
}



