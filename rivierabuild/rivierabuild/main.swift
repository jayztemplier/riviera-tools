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

CLI.debugGoWithArgumentString("rivierabuild upload AnimalCrush /Users/jayztemplier/Dev/FrenchDay.ipa --verbose --disablegitlog --apikey 2f0b99e163dead532a18582dae5d05227b310ff4 --availability 10_minutes")

exit(result)

