//
//  RivieraBuildClient.swift
//  swiftclient
//
//  Created by Jeremy Templier on 2/27/15.
//  Copyright (c) 2015 Riviera Build LLC. All rights reserved.
//

import Foundation


extension Dictionary {
    mutating func merge(other:Dictionary) {
        for (key,value) in other {
            self.updateValue(value, forKey:key)
        }
    }
}


class RivieraBuildClient {
    
    private let baseURL = "http://beta.rivierabuild.com"
    var apiKey: String?
    
    init(apiKey: String?) {
        self.apiKey = apiKey
    }
    
    func latestBuildUploaded (appID: Int, completionHandler: (responseObject: AnyObject?, error: String?) -> Void ) {
        if let apiKey = self.apiKey {
            let url = baseURL + "/api/applications/" + String(appID) + "/builds/latest"
            request(.GET, url, parameters: ["api_key": apiKey])
                .responseJSON { (_, _, JSON, _) in
                    completionHandler(responseObject: JSON, error: nil)
            }
        } else {
            completionHandler(responseObject: nil, error: "You have to specify an API Key")
        }
    }
    
    func uploadBuild(buildURL: NSURL, params: Dictionary<String, AnyObject>, completionHandler: (responseObject: AnyObject?, error: String?) -> Void) {
        if let apiKey = self.apiKey {
            let url = baseURL + "/api/upload?api_key=" + apiKey
            let fileData = NSData(contentsOfURL: buildURL)
            
            let urlRequest = urlRequestWithComponents(url, parameters: params, fileData: fileData!)
            upload(urlRequest.0, urlRequest.1)
                .progress { (bytesWritten, totalBytesWritten, totalBytesExpectedToWrite) in
                    println("\(totalBytesWritten) / \(totalBytesExpectedToWrite)")
                }
                .responseJSON { (request, response, JSON, error) in
                    println("REQUEST \(request)")
                    println("RESPONSE \(response)")
                    println("JSON \(JSON)")
                    println("ERROR \(error)")
                    completionHandler(responseObject: JSON, error: error?.localizedDescription)
            }
        } else {
            completionHandler(responseObject: nil, error: "You have to specify an API Key")
        }
    }
    
    // this function creates the required URLRequestConvertible and NSData we need to use Alamofire.upload
    func urlRequestWithComponents(urlString:String, parameters:Dictionary<String, AnyObject>, fileData:NSData) -> (URLRequestConvertible, NSData) {
        
        // create url request to send
        var mutableURLRequest = NSMutableURLRequest(URL: NSURL(string: urlString)!)
        mutableURLRequest.HTTPMethod = Method.POST.rawValue
        let boundaryConstant = "myRandomBoundary12345";
        let contentType = "multipart/form-data;boundary="+boundaryConstant
        mutableURLRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
        
        
        
        // create upload data to send
        let uploadData = NSMutableData()
        
        // add image
        uploadData.appendData("\r\n--\(boundaryConstant)\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        uploadData.appendData("Content-Disposition: form-data; name=\"file\"; filename=\"build.ipa\"\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        uploadData.appendData("Content-Type: image/png\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        uploadData.appendData(fileData)
        
        // add parameters
        for (key, value) in parameters {
            uploadData.appendData("\r\n--\(boundaryConstant)\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
            uploadData.appendData("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)".dataUsingEncoding(NSUTF8StringEncoding)!)
        }
        uploadData.appendData("\r\n--\(boundaryConstant)--\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        
        
        
        // return URLRequestConvertible and NSData
        return (ParameterEncoding.URL.encode(mutableURLRequest, parameters: nil).0, uploadData)
    }
}