//
//  RivieraBuildAPI.swift
//  rivierabuild
//
//  Created by Brandon Sneed on 2/27/15.
//  Copyright (c) 2015 TheHolyGrail. All rights reserved.
//

import Foundation

public struct RivieraBuildAPI {
    
    private let baseURL: String = "http://beta.rivierabuild.com"
    private let apiKey: String
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    public func lastUploadedBuildInfo(appID: String) -> JSON? {
        var json: JSON? = nil;
        
        let session = NSURLSession.sharedSession()
        
        let urlString = baseURL + "/api/applications/" + appID + "/builds/latest?api_key=" + apiKey
        let url = NSURL(string: urlString)!
        
        // we want this call to be synchronous
        let semaphore = dispatch_semaphore_create(0)
        
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "GET"
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) -> Void in
            if data != nil {
                let dataString: String = NSString(data: data, encoding: NSUTF8StringEncoding)! as String
                json = JSON(string: dataString)
            }
            
            dispatch_semaphore_signal(semaphore)
        }
        
        task.resume()
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        
        return json
    }
    
//    http://jayztemplier.github.io/RivieraBuild-API/
//    curl -XPOST "http://beta.rivierabuild.com/api/upload"
//    -F file=@"${TMP_FILE_PATH}"
//    -F availability="${AVAILABILITY}"
//    -F passcode="${PASSWORD}"
//    -F app_id="${PASSWORD}"
//    -F api_key="${API_KEY}"
//    -F commit_sha="${COMMIT_SHA}"
//    -F note="${NOTE}"
//    -F version="${VERSION}"
//    -F build_number="${BUILD_NUMBER}"

    func uploadBuild(filePath: String, build: Build) -> JSON? {
        var params = Dictionary<String, String>()
        if let v = build.availability {
            params["availability"] = v
        }
        if let v = build.passcode {
            params["passcode"] = v
        }
        if let v = build.appID {
            params["app_id"] = v
        }
        if let v = build.commitSha {
            params["commit_sha"] = v
        }
        if let v = build.note {
            params["note"] = v
        }
        if let v = build.version {
            params["version"] = v
        }
        if let v = build.buildNumber {
            params["build_number"] = v
        }
        return self.uploadBuild(filePath, parameters: params)
    }
    
    public func uploadBuild(filePath: String, parameters: Dictionary<String, AnyObject>) -> JSON? {
        var json: JSON? = nil;
        
        let session = NSURLSession.sharedSession()
        
        let urlString = baseURL + "/api/upload?api_key=" + apiKey
        let url = NSURL(string: urlString)!
        
        // we want this call to be synchronous
        let semaphore = dispatch_semaphore_create(0)
        
        let request = NSMutableURLRequest(URL: url)
        let boundaryConstant = "myRandomBoundary12345";
        let contentType = "multipart/form-data;boundary=" + boundaryConstant
        
        request.HTTPMethod = "POST"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        
        // see if the file exists.
        let fileManager = NSFileManager.defaultManager()
        let exists = fileManager.fileExistsAtPath(filePath)
        
        if exists {

            let fileData = NSData(contentsOfFile: filePath)
            
            // create upload data to send
            let uploadData = NSMutableData()
            
            // add image
            uploadData.appendData("\r\n--\(boundaryConstant)\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
            uploadData.appendData("Content-Disposition: form-data; name=\"file\"; filename=\"build.ipa\"\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
            uploadData.appendData("Content-Type: image/png\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
            uploadData.appendData(fileData!)
            
            // add parameters
            for (key, value) in parameters {
                uploadData.appendData("\r\n--\(boundaryConstant)\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
                uploadData.appendData("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)".dataUsingEncoding(NSUTF8StringEncoding)!)
            }
            uploadData.appendData("\r\n--\(boundaryConstant)--\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)

            let task = session.uploadTaskWithRequest(request, fromData: uploadData) { (data, response, error) -> Void in
                if data != nil {
                    let dataString: String = NSString(data: data, encoding: NSUTF8StringEncoding)! as String
                    json = JSON(string: dataString)
                }
                
                dispatch_semaphore_signal(semaphore)
            }
            
            task.resume()
            
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        }
        
        return json
        
    }
}