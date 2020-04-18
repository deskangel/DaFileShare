//
//  AppDelegate.swift
//  dafileshare
//
//  Created by William Xue on 4/14/20.
//  Copyright © 2020 Deskangel. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
//    let task = Process()


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        ProcessInfo.processInfo.disableSuddenTermination()
        
        signal(SIGTERM, SIG_IGN) // Make sure the signal does not terminate the application.
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        print("applicationWillTerminate")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        print("applicationShouldTerminateAfterLastWindowClosed")
        return true
    }
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        print("applicationShouldTerminate")
        
//        if task.isRunning {
//            task.terminate()
//        }
        
        return .terminateNow
    }
}

