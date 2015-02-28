//
//  String.swift
//  rivierabuild
//
//  Created by Brandon Sneed on 2/27/15.
//  Copyright (c) 2015 TheHolyGrail. All rights reserved.
//

import Foundation

extension String {
    
    func escapedForCommandLine(escapeCRs: Bool) -> String {
        var tempString = self
        
        tempString = tempString.stringByReplacingOccurrencesOfString("\"", withString: "\\\"")
        
        if escapeCRs {
            tempString = tempString.stringByReplacingOccurrencesOfString("\n", withString: "\\n")
        }
        
        return tempString
    }
}