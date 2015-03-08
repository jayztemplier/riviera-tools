//
//  main.swift
//  rivierabuild
//
//  Created by Brandon Sneed on 2/24/15.
//  Copyright (c) 2015 TheHolyGrail. All rights reserved.
//

import Foundation

CLI.setup(name: "rivierabuild", version: "1.0", description: "Command line tool to automate RivieraBuild from CI servers.")

let uploadCommand = UploadCommand()
CLI.registerCommand(uploadCommand)

let result = CLI.go()
exit(1)

