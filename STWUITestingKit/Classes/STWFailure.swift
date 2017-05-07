//
//  STWFailure.swift
//  Glamour
//
//  Created by Tal Zion on 01/05/2017.
//  Copyright © 2017 Stanwood GmbH. All rights reserved.
//

import Foundation

struct STWFailure {
    let testID: String
    let navigationID:Int
    let errorMessage:String
    
    init(testID: String, navigationID: Int, message: String) {
        self.testID = testID
        self.navigationID = navigationID
        self.errorMessage = message
    }
    
    init(message: String) {
        self.init(testID: "0", navigationID: 0, message: message)
    }
}