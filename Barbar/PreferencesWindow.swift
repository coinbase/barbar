//
//  PreferencesWindow.swift
//  Barbar
//
//  Created by Dai Hovey on 27/05/2016.
//  Copyright © 2016 Coinbase. All rights reserved.
//

import Cocoa

protocol PreferencesWindowDelegate {
    func updateInterval(interval: NSTimeInterval)
    func updatePair(isFirstPair:Bool, title: String)
    func preferencesDidUpdate()
    func toggleStartAtLogin(start:Bool)
    func updateColourSymbols(on:Bool)
}

struct Interval {
    var title: String!
    var interval: NSTimeInterval
}

struct Site {
    var title: String!
    var host: String!
}

enum UserDefaults: String {
    case interval = "interval"
    case firstPair = "firstPair"
    case secondPair = "secondPair"
    case launchFromStart = "launchFromStart"
    case colorSymbols = "colorSymbols"
}

class PreferencesWindow: NSWindowController, NSWindowDelegate, NSMenuDelegate {

    @IBOutlet weak var firstPair: NSPopUpButton!
    @IBOutlet weak var secondPair: NSPopUpButton!
    @IBOutlet weak var updateInterval: NSPopUpButton!
    @IBOutlet weak var colorSymbols: NSButton!
    @IBOutlet weak var exampleText: NSTextField!
    @IBOutlet weak var startAtLaunch: NSButton!
    @IBOutlet weak var sitePicker: NSPopUpButton!
    
    @IBAction func startAtLoginPressed(sender: NSButton) {
        var isOn:Bool = false
        if sender.state == NSOffState {
            isOn = false
        } else if sender.state == NSOnState {
            isOn = true
        }
        self.delegate!.toggleStartAtLogin(isOn)
    }
    
    @IBAction func secondPairUpdated(sender: NSPopUpButton) {
        self.delegate!.updatePair(false, title:sender.titleOfSelectedItem!)
    }
    
    @IBAction func firstPairUpdated(sender: NSPopUpButton) {
        self.delegate!.updatePair(true, title:sender.titleOfSelectedItem!)
    }
    
    @IBAction func intervalUpdated(sender: NSPopUpButton) {
        let index = updateInterval.indexOfItemWithTitle(sender.titleOfSelectedItem!)
        let interval = intervals[index]
        
        self.delegate!.updateInterval(interval.interval)
    }
    
    @IBAction func sitePickerUpdated(sender: NSPopUpButton) {
        let index = sitePicker.indexOfItemWithTitle(sender.titleOfSelectedItem!)
        let site = sites[index]
        
        defaults.setObject(site.title, forKey: siteUserDefault)
        defaults.synchronize()
    }
    
    @IBAction func colourSymbolsUpdated(sender: NSButton) {
        var isOn:Bool = false
        if sender.state == NSOffState {
            isOn = false
        } else if sender.state == NSOnState {
            isOn = true
        }
        
        defaults.setBool(isOn, forKey: UserDefaults.colorSymbols.rawValue)
        defaults.synchronize()

        delegate!.updateColourSymbols(isOn)
    }
    
    var pairs: [Pair] = []
    var delegate: PreferencesWindowDelegate?
    var exampleString: NSAttributedString? {
        didSet {
            if exampleText != nil {
                exampleText.attributedStringValue = exampleString!
            }
        }
    }
    
    let defaults = NSUserDefaults.standardUserDefaults()
    
    let intervals = [Interval(title:"5 Seconds", interval: 5),
                    Interval(title:"60 Seconds", interval: 60),
                    Interval(title:"5 Minutes", interval: 300),
                    Interval(title:"30 Minutes", interval: 1800),
                    Interval(title:"1 Hour", interval: 3600),
                    Interval(title:"24 Hours", interval: 86400)]
    var selectedInterval: Interval!
    
    let sites = [Site(title: "Coinbase", host: "https://coinbase.com/"),
                 Site(title: "GDAX", host: "https://gdax.com/")]
    var selectedSite: Site!
    let siteUserDefault = "site"
    
    override func windowDidLoad() {
        super.windowDidLoad()

        window?.center()
        window?.makeKeyAndOrderFront(nil)
        window?.level = Int(CGWindowLevelForKey(.MaximumWindowLevelKey))
        NSApp.activateIgnoringOtherApps(true)
    }
    
    override func awakeFromNib() {
        
        let savedInterval = defaults.objectForKey(UserDefaults.interval.rawValue) as! NSTimeInterval
        let savedFirstPair = defaults.objectForKey(UserDefaults.firstPair.rawValue) as! String
        let savedSecondPair = defaults.objectForKey(UserDefaults.secondPair.rawValue) as! String
        let savedLaunchFromStart = defaults.boolForKey(UserDefaults.launchFromStart.rawValue)
        let savedColourSymbols = defaults.boolForKey(UserDefaults.colorSymbols.rawValue)
        let savedSitePicker: String!
        
        if let sitePicker = defaults.objectForKey(siteUserDefault) as? String {
            savedSitePicker = sitePicker
        } else {
            savedSitePicker = sites[0].title
            defaults.setObject(savedSitePicker, forKey: siteUserDefault)
        }
        
        // Intervals
        updateInterval.menu?.delegate = self
        for interval in intervals {
            if interval.interval == savedInterval {
                selectedInterval = interval
            }
            updateInterval.addItemWithTitle(interval.title)
        }
        updateInterval.selectItemWithTitle(selectedInterval.title)
        
        // Pairs
        for pair in pairs {
            if let displayName = pair.id! as String? {
                firstPair.addItemWithTitle(displayName)
                secondPair.addItemWithTitle(displayName)
            }
        }
        
        firstPair.selectItemWithTitle(savedFirstPair)
        secondPair.selectItemWithTitle(savedSecondPair)

        // Example
        if exampleString != nil {
            exampleText.attributedStringValue = exampleString!
        }
        
        // Start are launch
        startAtLaunch.state = Int(savedLaunchFromStart)
        
        // Colour symbols
        colorSymbols.state = Int(savedColourSymbols)
        
        // Site picker
        
        sitePicker.menu?.delegate = self
        for site in sites {
            if site.title == savedSitePicker {
                selectedSite = site
            }
            sitePicker.addItemWithTitle(site.title)
        }
        sitePicker.selectItemWithTitle(selectedSite.title)
    }
    
    override var windowNibName : String! {
        return "PreferencesWindow"
    }
    
    func windowWillClose(notification: NSNotification) {
        delegate?.preferencesDidUpdate()
    }
}
