//
//  PreferencesWindow.swift
//  Barbar
//
//  Created by Dai Hovey on 27/05/2016.
//  Copyright © 2016 Coinbase. All rights reserved.
//

import Cocoa

protocol PreferencesWindowDelegate {
    func updateInterval(_ interval: TimeInterval)
    func updatePair(_ isFirstPair:Bool, title: String)
    func preferencesDidUpdate()
    func toggleStartAtLogin(_ start:Bool)
    func updateColourSymbols(_ on:Bool)
}

struct Interval {
    var title: String!
    var interval: TimeInterval
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
	case darkMenuBar = "darkMenuBar"
    case colorSymbols = "colorSymbols"
}

class PreferencesWindow: NSWindowController, NSWindowDelegate, NSMenuDelegate {

    @IBOutlet weak var firstPair: NSPopUpButton!
    @IBOutlet weak var secondPair: NSPopUpButton!
    @IBOutlet weak var updateInterval: NSPopUpButton!
    @IBOutlet weak var colorSymbols: NSButton!
	@IBOutlet weak var darkMenuBar: NSButton!
    @IBOutlet weak var exampleText: NSTextField!
    @IBOutlet weak var startAtLaunch: NSButton!
    @IBOutlet weak var sitePicker: NSPopUpButton!
    
    @IBAction func startAtLoginPressed(_ sender: NSButton) {
        var isOn:Bool = false
        if sender.state == NSOffState {
            isOn = false
        } else if sender.state == NSOnState {
            isOn = true
        }
        self.delegate!.toggleStartAtLogin(isOn)
    }
    
    @IBAction func secondPairUpdated(_ sender: NSPopUpButton) {
        self.delegate!.updatePair(false, title:sender.titleOfSelectedItem!)
    }
    
    @IBAction func firstPairUpdated(_ sender: NSPopUpButton) {
        self.delegate!.updatePair(true, title:sender.titleOfSelectedItem!)
    }
    
    @IBAction func intervalUpdated(_ sender: NSPopUpButton) {
        let index = updateInterval.indexOfItem(withTitle: sender.titleOfSelectedItem!)
        let interval = intervals[index]
        
        self.delegate!.updateInterval(interval.interval)
    }
    
    @IBAction func sitePickerUpdated(_ sender: NSPopUpButton) {
        let index = sitePicker.indexOfItem(withTitle: sender.titleOfSelectedItem!)
        let site = sites[index]
        
        defaults.set(site.title, forKey: siteUserDefault)
        defaults.synchronize()
    }
    
    @IBAction func colourSymbolsUpdated(_ sender: NSButton) {
        var isOn:Bool = false
        if sender.state == NSOffState {
            isOn = false
        } else if sender.state == NSOnState {
            isOn = true
        }
        
        defaults.set(isOn, forKey: UserDefaults.colorSymbols.rawValue)
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
    
    let defaults = Foundation.UserDefaults.standard
    
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
        window?.level = Int(CGWindowLevelForKey(.maximumWindow))
        NSApp.activate(ignoringOtherApps: true)
    }
    
    override func awakeFromNib() {
        
        let savedInterval = defaults.object(forKey: UserDefaults.interval.rawValue) as! TimeInterval
        let savedFirstPair = defaults.object(forKey: UserDefaults.firstPair.rawValue) as! String
        let savedSecondPair = defaults.object(forKey: UserDefaults.secondPair.rawValue) as! String
        let savedLaunchFromStart = defaults.bool(forKey: UserDefaults.launchFromStart.rawValue)
        let savedColourSymbols = defaults.bool(forKey: UserDefaults.colorSymbols.rawValue)
        let savedSitePicker: String!
        
        if let sitePicker = defaults.object(forKey: siteUserDefault) as? String {
            savedSitePicker = sitePicker
        } else {
            savedSitePicker = sites[0].title
            defaults.set(savedSitePicker, forKey: siteUserDefault)
        }
        
        // Intervals
        updateInterval.menu?.delegate = self
        for interval in intervals {
            if interval.interval == savedInterval {
                selectedInterval = interval
            }
            updateInterval.addItem(withTitle: interval.title)
        }
        updateInterval.selectItem(withTitle: selectedInterval.title)
        
        // Pairs
        for pair in pairs {
            if let displayName = pair.id! as String? {
                firstPair.addItem(withTitle: displayName)
                secondPair.addItem(withTitle: displayName)
            }
        }
        
        firstPair.selectItem(withTitle: savedFirstPair)
        secondPair.selectItem(withTitle: savedSecondPair)

        // Example
        if exampleString != nil {
            exampleText.attributedStringValue = exampleString!
        }
        
        // Start are launch
        startAtLaunch.state = savedLaunchFromStart ? 1 : 0
        
        // Colour symbols
        colorSymbols.state = savedColourSymbols ? 1 : 0
        
        // Site picker
        
        sitePicker.menu?.delegate = self
        for site in sites {
            if site.title == savedSitePicker {
                selectedSite = site
            }
            sitePicker.addItem(withTitle: site.title)
        }
        sitePicker.selectItem(withTitle: selectedSite.title)
    }
    
    override var windowNibName : String! {
        return "PreferencesWindow"
    }
    
    func windowWillClose(_ notification: Notification) {
        delegate?.preferencesDidUpdate()
    }
}
