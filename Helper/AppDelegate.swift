//
//  AppDelegate.swift
//  Helper
//
//  Created by David Hovey on 17/06/2016.
//  Copyright © 2016 Coinbase. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        
        let mainAppIdentifier = "com.coinbase.bar.Barbar"
        let running = NSWorkspace.sharedWorkspace().runningApplications
        var alreadyRunning = false
        
        for app in running {
            if app.bundleIdentifier == mainAppIdentifier {
                alreadyRunning = true
                break
            }
        }
        
        if alreadyRunning == false {
            NSDistributedNotificationCenter.defaultCenter().addObserver(self, selector: "terminate", name: "killme", object: mainAppIdentifier)
            
            let path = NSBundle.mainBundle().bundlePath as NSString
            var components = path.pathComponents
            components.removeLast()
            components.removeLast()
            components.removeLast()
            components.append("MacOS")
            components.append("Barbar") //main app name
            
            let newPath = NSString.pathWithComponents(components)
            
            NSWorkspace.sharedWorkspace().launchApplication(newPath)
        }
        else {
            self.terminate()
        }
    }
    
    func terminate() {
        NSApp.terminate(nil)
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
}

