//
//  HipchatIntegration.swift
//  rivierabuild
//
//  Created by Jeremy Templier on 3/3/15.
//  Copyright (c) 2015 TheHolyGrail. All rights reserved.
//

import Foundation


public struct HipchatIntegration {
    
    private let apiURL: String = "https://api.hipchat.com"
    private let authToken: String
    
    init(authToken: String) {
        self.authToken = authToken
    }
    
    // returns 'true' if successful, otherwise, 'false'.
    public func post(room: String, message: String, color: String) -> Bool {
        var result: Bool = false
        let session = NSURLSession.sharedSession()
        
        let url = NSURL(string: apiURL + "/v2/room/" + room + "/notification")
        if let url = url {
            // we want this call to be synchronous
            let semaphore = dispatch_semaphore_create(0)
            let request = NSMutableURLRequest(URL: url)
            request.HTTPMethod = "POST"
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer " + self.authToken, forHTTPHeaderField: "Authorization")
            
            var contents = Dictionary<String, String>()
            contents["color"] = color
            contents["message"] = message
            contents["message_format"] = "text"
            
            let jsonPayload = JSON(contents)
            let tempString = jsonPayload.toString(pretty: true)
            let data = tempString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
            
            request.HTTPBody = data
            
            let task = session.dataTaskWithRequest(request) { (data, response, error) -> Void in
                if let httpResponse = response as? NSHTTPURLResponse {
                    if httpResponse.statusCode == 204 {
                        result = true
                    } else {
                        println("Post to hipchat returned %d", httpResponse.statusCode)
                    }
                }
                
                dispatch_semaphore_signal(semaphore)
            }
            
            task.resume()
            
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        }
        
        return result;
    }
}