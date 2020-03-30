//
//  SearchScope.swift
//  opportunity_express_client
//
//  Created by Miles Clark on 10/08/18.
//  Copyright (c) 2018 Eastern Labs. All rights reserved.
//

/**
    Different search scopes

    - All: search both companies and individuals. Raw value = 0
    - CompaniesOnly: search only companies. Raw value = 1
    - IndividualsOnly: search only individuals. Raw value = 2
*/
enum SearchScope: Int {
    case all = 0, companiesOnly, individualsOnly
}
