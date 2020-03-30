//
//  Application.swift
//  opportunity_express_client
//
//  Created by Miles Clark on 10/08/18.
//  Copyright (c) 2018 Eastern Labs. All rights reserved.
//

import SwiftyJSON

/// Struct for encapsulating data of an applicant
struct Applicant {
    
    /// Creates an Applicant with default (empty) values
    init() {
        
    }
    
    /**
        Builds Applicant from json
    
        - parameter json: JSON object containing applicant details
    */
    init(json:JSON) {
        
        self.json = json
        self.name = json["full_name"].string ?? ""
        self.phone = json["primary_phone"].string ?? ""
        self.email = json["email_address"].string ?? ""
        self.isOriginalApplicant = json["is_original_applicant"].bool ?? false
    }
    
    var json: JSON?
    var name = ""
    var phone = ""
    var email = ""
    var isOriginalApplicant = false

}

/// Struct for encapsulating data of an application
struct Application {
    
    /// Creates an Applicant from json
    init(json: JSON) {
        
        self.json = json
        self.company = json["company"]
        self.companyName = self.company["name"].string ?? "Unknown name"
        self.app_type_text = self.json["app_type_text"].string ?? ""
        self.state_label_color = self.json["state_label_color"].string ?? eastern_red
        
        // Construct applicant fields
        self.primaryApplicant = Applicant()
        
        let allApplicants = json["applicants"].array ?? []
        
        for applicantJSON in allApplicants {
            
            let applicant = Applicant(json: applicantJSON)
            
            self.allApplicants.append(applicant)
            
            let fullName = applicant.name
            
            if applicant.isOriginalApplicant {
                self.primaryApplicant = applicant
                self.primaryApplicantName = fullName
            } else {
                otherApplicants.append(applicant)
                otherApplicantNames += "\(fullName), "
            }
        }
        
        if self.otherApplicantNames.length > 2 {
            self.otherApplicantNames = self.otherApplicantNames[0..<(self.otherApplicantNames.length - 2)]
        } else {
            self.otherApplicantNames = "None"
        }
        
        if let lastModified = json["last_activity"].string {
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
            formatter.timeZone = NSTimeZone(name: "UTC")! as? TimeZone
            
            if let date = formatter.date(from: lastModified) {
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                formatter.timeZone = NSTimeZone.local
                self.lastModified = formatter.string(from: date)
            } else {
                self.lastModified = "Unknown date"
            }
            
        } else {
            self.lastModified = "Unknown date"
        }
        
        self.status = json["application_state_lookup_id"].int ?? 0
        self.statusMessage = json["application_state_text"].string ?? "Unknown"
        self.cis = self.company["core_id"].string ?? ""
        self.uuid = self.company["uuid"].string ?? ""
    }
    
    var json:JSON
    var company:JSON
    var companyName = ""
    var app_type_text = ""
    var allApplicants = [Applicant]()
    var primaryApplicant: Applicant
    var primaryApplicantName = ""
    var otherApplicants = [Applicant]()
    var otherApplicantNames = ""
    var lastModified = ""
    var status = -1
    var statusMessage = ""
    var cis = ""
    var uuid = ""
    var state_label_color = ""
}
