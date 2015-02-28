//
//  ViewController.swift
//  swiftclient
//
//  Created by Jeremy Templier on 2/27/15.
//  Copyright (c) 2015 Riviera Build LLC. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    let apiKey = "2f0b99e163dead532a18582dae5d05227b310ff4"
    let appID = 9
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func latestAppPressed(sender: AnyObject) {
        let client = RivieraBuildClient(apiKey: self.apiKey)
        client.latestBuildUploaded(self.appID) { (responseObject, error) -> Void in
            if let error = error {
                println(error)
            }
            if let responseObject = responseObject {
                println(responseObject)
            }
        }
        
        let fileURL = NSBundle.mainBundle().URLForResource("AnimalCrush", withExtension: "ipa")
        if let url = fileURL {
            client.uploadBuild(url, params: ["availability" : "10_minutes", "app_id" : 9]) { (responseObject, error) -> Void in
                println(error)
            }
        }
    }

}

