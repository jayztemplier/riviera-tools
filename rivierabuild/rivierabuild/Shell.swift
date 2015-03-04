//
//  Shell.swift
//  rivierabuild
//
//  Created by Brandon Sneed on 2/24/15.
//  Copyright (c) 2015 TheHolyGrail. All rights reserved.
//

import Foundation

func shellCommand(command: String, parseClosure: ((status: Int32, output: String) -> Void)? = nil) -> Int32 {
    let tempFile = NSFileManager.temporaryFile()
    var tempCommand: NSString = command
    
    
    if (parseClosure != nil) {
        tempCommand = tempCommand.stringByAppendingFormat(" > %@", tempFile)
    }
    
    let status = system(tempCommand.cStringUsingEncoding(NSUTF8StringEncoding))
    
    if (parseClosure != nil) {
        let outputString = NSString(contentsOfFile: tempFile as String, encoding: NSUTF8StringEncoding, error: nil)
        parseClosure!(status: status, output: outputString as! String)
        NSFileManager.defaultManager().removeItemAtPath(tempFile as String, error: nil)
    }
    
    return status
}