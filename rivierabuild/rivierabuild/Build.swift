//
//  RivieraBuild.swift
//  rivierabuild
//
//  Created by Jeremy Templier on 3/7/15.
//  Copyright (c) 2015 TheHolyGrail. All rights reserved.
//

import Foundation

struct Build {
    var ipa: String?
    var displayName: String?
    var availability: String?
    var passcode: String?
    var appID: String?
    var note: String?
    var version: String?
    var buildNumber: String?
    var commitSha: String?
    var stringURL: String?
    
    init(displayName: String, ipa: String, availability: String, options: Dictionary<String,String>?) {
        self.ipa = ipa
        self.displayName = displayName
        self.availability = availability
        if let params = options{
            if let v = params["passcode"] {
                self.passcode = v
            }
            if let v = params["appid"] {
                self.appID = v
            }
            if let v = params["note"] {
                self.note = v
            }
            if let v = params["version"] {
                self.version = v
            }
            if let v = params["build_number"] {
                self.buildNumber = v
            }
            if let v = params["commit_sha"] {
                self.commitSha = v
            }
        }
    }
    
    func descriptionForSharing () -> String? {
        if let displayName = self.displayName, let url = self.stringURL {
            var description: String = String(format: "_*%@*_\nInstall URL: %@", displayName, url)
            if let passcode = passcode {
                description = description.stringByAppendingFormat("\nPasscode: %@", passcode)
            }
            if let version = version {
                description = description.stringByAppendingFormat("\nVersion: %@", version)
            }
            if let buildNumber = buildNumber {
                description = description.stringByAppendingFormat("\nBuild Number: %@", buildNumber)
            }
            if let note = note {
                description = description.stringByAppendingFormat("\nNotes:\n\n %@", note)
            }
            return description
        } else {
            return nil
        }
    }
}
