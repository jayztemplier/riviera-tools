//
//  UploadCommand.swift
//  rivierabuild
//
//  Created by Brandon Sneed on 2/24/15.
//  Copyright (c) 2015 TheHolyGrail. All rights reserved.
//

//  Definitely *not* my best code, but with Testflight shutting down, I had 2 days
//  to get something working with Jenkins. :(  Bad Brandon, Bad!  I look forward
//  to your improvements, community!

import Foundation

class UploadCommand: Command {

    // command params
    private var flags: Dictionary<String, Dictionary<String, Any>> = Dictionary<String, Dictionary<String, Any>>()
    private var parameters: Dictionary<String, String> = Dictionary<String, String>()
    private var paramValues: Dictionary<String, String> = Dictionary<String, String>()
    
    // internal vars
    private var commitHash: String? = nil
    
    var rivieraClient: RivieraBuildAPI? = nil
    lazy var rivieraBuild: Build = { [unowned self] in
            return Build(displayName: self.arguments["displayname"] as! String, ipa: self.arguments["ipa"] as! String, availability: self.arguments["availability"] as! String, options: self.paramValues)
        }()
    
    override func commandName() -> String {
        return "upload"
    }
    
    override func commandShortDescription() -> String {
        return "Uploads IPAs to RivieraBuild.\nSpecifies the availablility of the build.\nUse the following values:\n\n 10_minutes\n 1_hour\n 3_hours\n 6_hours\n 12_hours\n 24_hours\n 1_week\n 2_weeks\n 1_month\n 2_months"
    }
    
    override func commandSignature() -> String {
        return "<displayname> <ipa> <availability>"
    }
    
    override func handleOptions() {
        flags = Dictionary<String, Dictionary<String, Any>>()
        flags["verbose"] = ["usage" : "Show more details about what's happening.", "value" : false]
        flags["disablegitlog"] = ["usage" : "Disables appending the git log to the notes.", "value" : false]
        flags["randompasscode"] = ["usage" : "Generate a random passcode.", "value" : false]
        for (name, attributes) in flags {
            let arg = "--" + name
            if let usage = attributes["usage"] as? String {
                onFlags([arg], block: { (flag) -> () in
                    var attr = attributes
                    attr["value"] = true
                    self.flags[name] = attr
                    }, usage: usage)
            }
        }
        
        parameters = Dictionary<String, String>()
        parameters["passcode"] = "Specify the passcode to use for the build."
        parameters["apikey"] = "Your RivieraBuild API key."
        parameters["appid"] = "Your App ID in RivieraBuild."
        parameters["note"] = "The note to show in RivieraBuild."
        parameters["projectdir"] = "The directory of your project, for Git logs."
        parameters["slackhookurl"] = "Your Slack webhook URL."
        parameters["slackchannel"] = "The Slack channel to post to."
        parameters["hipchatauthtoken"] = "Your Hipchat auth token. To get it: https://www.hipchat.com/account/api."
        parameters["hipchatroom"] = "The Hipchat room id or name to post to."
        parameters["hipchatcolor"] = "Optional color for the notification posted on Hipchat."
        for (name, usage) in parameters {
            let arg = "--" + name
            onKeys([arg], block: { (key, value) -> () in
                self.paramValues[name] = value
                }, usage: usage , valueSignature: name)
        }
    }
    
    func setProjectDirectory() -> CommandResult {
        if let projectDir = self.paramValues["projectdir"] {
            let fileManager = NSFileManager.defaultManager()
            var isDir: ObjCBool = false
            let exists = fileManager.fileExistsAtPath(projectDir, isDirectory: &isDir)
            return exists && isDir ? .Success : .Failure("The specified value for project dir is not a directory or invalid.")
        }
        return .Success
    }
    
    func commitsSinceLastBuildNotes (currentCommitHash: String?) -> String {
        // get the last commit hash, we need it later if it's there.
        if let commitHash = currentCommitHash, let appID = self.paramValues["appid"] {
            if count(commitHash) == 0 {
                println("WARNING: we were not able to get a commit sha. Are you using git? If yes, please indicate the root directory with the option --projectdir")
            }
            if let h = self.flags["disablegitlog"], let useGitLogs = h["value"] {
                var json = self.rivieraClient!.lastUploadedBuildInfo(appID)
                if let json = json {
                    var lastCommitHash = json["commit_sha"].asString
                    if lastCommitHash != nil {
                        if let gitNotes = gitLogs(lastCommitHash!) {
                            return gitNotes
                        }
                    }
                }
            }
        } else {
            println("WARNING: no application ID specified. If you want to add and application id, use the option --appid")
        }
        return "";
    }
    
    override func execute() -> CommandResult {
        var result: CommandResult = .Success
        
        if let apiKey = self.paramValues["apikey"] {
            self.rivieraClient = RivieraBuildAPI(apiKey: apiKey)
            
            result = self.setProjectDirectory()
            switch result {
            case .Failure(let string):
                return result
            case .Success:
                0
            }
            
            commitHash = currentCommitHash()
            self.rivieraBuild.commitSha = commitHash
            let gitLogs = self.commitsSinceLastBuildNotes(commitHash)
            if let note = self.rivieraBuild.note {
                var noteWithGitLogs =  note.stringByAppendingString(gitLogs)
                self.rivieraBuild.note = noteWithGitLogs
            } else {
                self.rivieraBuild.note = gitLogs
            }
            
            // set random passcode if flag on
            if let h = self.flags["randompasscode"], let v = h["value"] as? Bool{
                if v == true {
                    let randomPassword = PasswordGenerator().generateHex()
                    self.rivieraBuild.passcode = randomPassword
                }
            }

            // try to send it to riviera
            result = sendToRiviera()
            switch result {
            case .Failure(let string):
                return result
            case .Success:
                println("Riviera: download your app at this URL " + self.rivieraBuild.stringURL!)
            }
            
            // get the version and build from the one we just uploaded so we can use it for slack.
            fillLastVersionAndBuildNumber()
            
            // try to post it to slack
            result = postToSlack()
            switch result {
            case .Success:
                0
            case .Failure(let string):
                return result
            }
            
            result = postToHipchat()
            switch result {
            case .Success:
                0
            case .Failure(let string):
                return result
            }
            
            return result
        } else {
            return .Failure("You have to provide an API key, use the option --apiKey.")
        }
    }
    
    func sendToRiviera() -> CommandResult {
        let ipa = arguments["ipa"] as! String
        // see if the file exists.
        let fileManager = NSFileManager.defaultManager()
        let exists = fileManager.fileExistsAtPath(ipa)
        
        if exists {          
            println("Uploading build ....")
            if let riviera = self.rivieraClient {
                let json = riviera.uploadBuild(ipa, build: self.rivieraBuild)
                if let json = json {
                    if let resultURL = json["file_url"].asString {
                        self.rivieraBuild.stringURL = resultURL
                    }
                }
            }
            
            if self.rivieraBuild.stringURL == nil {
                return .Failure("Failed to get the result URL from RivieraBuild.")
            }
            
            println("Build uplooded to riviera with success!")
            return .Success
        } else {
            return .Failure("The IPA specified does not exist.")
        }
    }
    
    func currentCommitHash() -> String? {
        var commitHash: String = ""
        
        let currentPath = NSFileManager.defaultManager().currentDirectoryPath
        if let projectDir = self.paramValues["projectdir"] {
            NSFileManager.defaultManager().changeCurrentDirectoryPath(projectDir)
        }
        
        let command = "git log --format='%H' -n 1"
        if let h = self.flags["verbose"], let verbose = h["value"] {
            println(command)
        }
        let status: Int32 = shellCommand(command) { (status, output) -> Void in
            if status == 0 {
                commitHash = output.stringByReplacingOccurrencesOfString("\n", withString: "")
            }
        }
        
        if let projectDir = self.paramValues["projectdir"] {
            NSFileManager.defaultManager().changeCurrentDirectoryPath(currentPath)
        }
        
        return commitHash
    }
    
    func lastBuildCommitHash() -> String? {
        if let appID = self.paramValues["appid"], let riviera = self.rivieraClient {
            var commitHash: String? = nil
            let json = riviera.lastUploadedBuildInfo(appID)
            
            if let json = json {
                if let hash = json["commit_sha"].asString {
                    if hash != "null" {
                        commitHash = hash
                    }
                }
            }
            
            return commitHash
        } else {
            return nil
        }
        
    }
    
    func fillLastVersionAndBuildNumber() {
        if let appID = self.paramValues["appid"], let riviera = self.rivieraClient {
            let json = riviera.lastUploadedBuildInfo(appID)
            if let json = json {
                if let version = json["version"].asString {
                    if version != "null" && count(version) > 0 {
                        self.rivieraBuild.version = version
                    }
                }
                if let buildNumber = json["build_number"].asString {
                    if buildNumber != "null" && count(buildNumber) > 0 {
                        self.rivieraBuild.buildNumber = buildNumber
                    }
                }
            }
        }
    }
    
    func gitLogs(sinceHash: String) -> String? {
        
        var commitNotes: String? = nil
        
        let currentPath = NSFileManager.defaultManager().currentDirectoryPath
        if let projectDir = self.paramValues["projectdir"] {
            NSFileManager.defaultManager().changeCurrentDirectoryPath(projectDir)
        }
        
        let command = String(format: "git log --oneline --no-merges %@..HEAD --format=\"- %%s   -- %%cn\"", sinceHash)
        if let h = self.flags["verbose"], let verbose = h["value"] {
            println(command)
        }
        let status: Int32 = shellCommand(command) { (status, output) -> Void in
            if status == 0 {
                commitNotes = output
                
                // commitNotes ends up containing the log for the commit referenced and an extra \n.  I don't know
                // how to exclude it, so i'm doing this hacky thing.  :(
                
                var logs: [String] = commitNotes!.componentsSeparatedByString("\n")
                
                // escape the carriage returns
                commitNotes = "\n".join(logs)
            }
        }
        
        if let projectDir = self.paramValues["projectdir"] {
            NSFileManager.defaultManager().changeCurrentDirectoryPath(currentPath)
        }
        
        return commitNotes
    }
    
    func postToSlack() -> CommandResult {
        if let slackHookURL = self.paramValues["slackhookurl"], let slackChannel = self.paramValues["slackchannel"] {
            if let slackNote = self.rivieraBuild.descriptionForSharing() {
                let slack = SlackWebHookAPI(webHookURL: slackHookURL)
                println("Posting to Slack...")
                if slack.postToSlack(slackChannel, text: slackNote) == false {
                    return .Failure("Slack posting failed.")
                }
                println("Posted to Slack!")
                return .Success
            } else {
                return .Failure("Error with creation of the description to share for the build.")
            }
        } else {
            // we just won't be sending to slack, so don't fail.
            return .Success
        }
    }
    
    func postToHipchat() -> CommandResult {
        if let hipchatAuthToken = self.paramValues["hipchatauthtoken"], let hipchatRoom = self.paramValues["hipchatroom"] {
            var hipchatColor = "green"
            if let color = self.paramValues["hipchatcolor"] {
                hipchatColor = color
            }
            // Build the stuff we're going to display on slack...
            if let description = self.rivieraBuild.descriptionForSharing() {
                let hipchat = HipchatIntegration(authToken: hipchatAuthToken)
                println("Posting to Hipchat...")
                if hipchat.post(hipchatRoom, message: description, color: hipchatColor) == false {
                    return .Failure("Hipchat posting failed.")
                }
            } else {
                return .Failure("Error with creation of the description to share for the build.")
            }
            println("Posted to Hipchat!.")
            return .Success
        } else {
            // we just won't be sending to slack, so don't fail.
            return .Success
        }
    }
    
}


