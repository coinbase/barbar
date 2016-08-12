//
//  StatusMenuController.swift
//  Barbar
//
//  Created by Dai Hovey on 27/05/2016.
//  Copyright © 2016 Coinbase. All rights reserved.
//

import Cocoa
import ServiceManagement


class StatusMenuController: NSObject, PreferencesWindowDelegate {

    struct URL {
        static let btcUSD = "BTC-USD"
        static let ethUSD = "ETH-USD"
    }
    
    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var firstDetailView: DetailView!
    @IBOutlet weak var secondDetailView: DetailView!

    var firstPairViewMenuItem: NSMenuItem!
    var secondPairViewMenuItem: NSMenuItem!
    var interval:NSTimeInterval!
    var timer: NSTimer!
    var firstPrice = ""
    var secondPrice = ""
    var pairs: [Pair] = []
    var firstPairID: String!
    var secondPairID: String!
    var chosenPairs: [Pair] = []
    var preferencesWindow: PreferencesWindow!
    var reachability: Reachability?
    var fontPosistive: [String : NSObject]!
    var fontNegative: [String : NSObject]!
    var useColouredSymbols = true
    
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSVariableStatusItemLength)
    let defaults = NSUserDefaults.standardUserDefaults()
    let font = [NSFontAttributeName: NSFont.systemFontOfSize(15)]
    let pairsURL = "https://api.gdax.com/products"
    let green = NSColor.init(red: 22/256, green: 206/255, blue: 0/256, alpha: 1)
    let red = NSColor.init(red: 255/256, green: 73/255, blue: 0/256, alpha: 1)
    
    override func awakeFromNib() {
        
        setup()
        setupViews()
        fetchPairs()
        
        // Start reachability without a hostname intially
        setupReachability(useHostName: false)
        startNotifier()
        
        // After 5 seconds, stop and re-start reachability, this time using a hostname
        let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(UInt64(5) * NSEC_PER_SEC))
        dispatch_after(dispatchTime, dispatch_get_main_queue()) {
            self.stopNotifier()
            self.setupReachability(useHostName: true)
            self.startNotifier()
        }
    }

    //MARK: SETUP
    func setup() {
        
        fontPosistive = [NSFontAttributeName: NSFont.systemFontOfSize(15), NSForegroundColorAttributeName: green]
        fontNegative = [NSFontAttributeName: NSFont.systemFontOfSize(15), NSForegroundColorAttributeName: red]
        
        if let interval = defaults.objectForKey(UserDefaults.interval.rawValue) as? NSTimeInterval {
            self.interval = interval
        } else {
            self.interval = NSTimeInterval(60)  // Default is 60 seconds
            defaults.setObject(self.interval, forKey: UserDefaults.interval.rawValue)
        }
        
        if let firstPair = defaults.objectForKey(UserDefaults.firstPair.rawValue) as? String {
            firstPairID = firstPair
        } else {
            firstPairID = URL.btcUSD // Default
            defaults.setObject(firstPairID, forKey: UserDefaults.firstPair.rawValue)
        }
        
        if let secondPair = defaults.objectForKey(UserDefaults.secondPair.rawValue) as? String {
            secondPairID = secondPair
        } else {
            secondPairID = URL.ethUSD // Default
            defaults.setObject(secondPairID, forKey: UserDefaults.secondPair.rawValue)
        }
        
        var startAtLogin = false
        if defaults.objectForKey(UserDefaults.launchFromStart.rawValue) == nil {
            startAtLogin = true // Default
            defaults.setBool(true, forKey: UserDefaults.launchFromStart.rawValue)
        } else {
            startAtLogin = defaults.boolForKey(UserDefaults.launchFromStart.rawValue)
        }
        
        toggleStartAtLogin(startAtLogin)
        
        if defaults.objectForKey(UserDefaults.colorSymbols.rawValue) == nil {
            useColouredSymbols = true // Default
            defaults.setBool(true, forKey: UserDefaults.colorSymbols.rawValue)
        } else {
            useColouredSymbols = defaults.boolForKey(UserDefaults.colorSymbols.rawValue)
        }

        defaults.synchronize()
    }
    
    func setupViews() {
        statusItem.menu = statusMenu
        showStatusItemImage(true)
        
        firstPairViewMenuItem = statusMenu.itemWithTitle("FirstPairView")
        firstPairViewMenuItem.view = firstDetailView
        
        secondPairViewMenuItem = statusMenu.itemWithTitle("SecondPairView")
        secondPairViewMenuItem.view = secondDetailView
        
        preferencesWindow = PreferencesWindow()
        preferencesWindow.delegate = self
    }
    
    func updateTimer() {
        if timer != nil {
            if timer.valid == true {
                timer.invalidate()
            }
        }
        
        timer = NSTimer(timeInterval: interval, target: self, selector: #selector(update), userInfo: nil, repeats: true)
        NSRunLoop.mainRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)
    }
    
    func update() {
        fetchPairsPrice()
    }
    
    func showStatusItemImage(show: Bool) {
        if show == true {
            statusItem.image = NSImage(named: "iconTemplate") // Just show while loading
        } else {
            statusItem.image = nil
        }
    }
    
    func updateOfflineTitle() {
        dispatch_async(dispatch_get_main_queue(), {
            self.firstDetailView.updateOffline()
            self.secondDetailView.updateOffline()
        })
    }
    
    func updateTitle() {
        if (chosenPairs.count == 1 && chosenPairs[0].price != nil) ||
            (chosenPairs.count == 2 && chosenPairs[0].price != nil && chosenPairs[1].price != nil) {
            
            dispatch_async(dispatch_get_main_queue(), {
                
                let firstPair = self.chosenPairs[0]
                let secondPair = self.chosenPairs[1]
                
                var firstSymbol: String!
                var secondSymbol: String!
                
                if let first = self.chosenPairs[0].price,
                    quote = self.chosenPairs[0].quoteCurrency,
                    base = self.chosenPairs[0].baseCurrency {
                    self.firstPrice = CurrencyFormatter.sharedInstance.formatAmountString(first, currency: quote, options: nil)
                    
                    if base == "BTC" {
                        firstSymbol = "Ƀ"
                    } else if base == "ETH" {
                        firstSymbol = "Ξ"
                    }
                }
                
                if let second = self.chosenPairs[1].price,
                    quote = self.chosenPairs[1].quoteCurrency,
                    base = self.chosenPairs[1].baseCurrency {
                    self.secondPrice = CurrencyFormatter.sharedInstance.formatAmountString(second, currency: quote, options: nil)
                    
                    if base == "BTC" {
                        secondSymbol = "Ƀ"
                    } else if base == "ETH" {
                        secondSymbol = "Ξ"
                    }
                }
                
                let mutableAttributedString = NSMutableAttributedString()
                
                var firstFont: [String : NSObject]!
                if firstPair.percent() < 0 {
                    firstFont = self.fontNegative
                } else {
                    firstFont = self.fontPosistive
                }
                
                var secondFont: [String : NSObject]!
                if secondPair.percent() < 0 {
                    secondFont = self.fontNegative
                } else {
                    secondFont = self.fontPosistive
                }
                
                let firstSymbolAtt =  NSAttributedString(string:firstSymbol, attributes: self.useColouredSymbols ? firstFont: self.font)
                let firstPriceAtt = NSAttributedString(string:self.firstPrice, attributes: self.font)

                let secondSymbolAtt =  NSAttributedString(string:secondSymbol, attributes: self.useColouredSymbols ? secondFont: self.font)
                let secondPriceAtt = NSAttributedString(string:self.secondPrice, attributes: self.font)

                mutableAttributedString.appendAttributedString(firstSymbolAtt)
                mutableAttributedString.appendAttributedString(firstPriceAtt)
                mutableAttributedString.appendAttributedString(NSAttributedString(string:" "))
                mutableAttributedString.appendAttributedString(secondSymbolAtt)
                mutableAttributedString.appendAttributedString(secondPriceAtt)
                
                self.statusItem.attributedTitle = mutableAttributedString
                self.firstDetailView.update(firstPair, price: self.firstPrice, pairID: self.firstPairID)
                self.secondDetailView.update(secondPair, price: self.secondPrice, pairID: self.secondPairID)
                self.preferencesWindow.exampleString = self.statusItem.attributedTitle
                
                self.showStatusItemImage(false)
            })
        }
    }
    
    func fetchPairsPrice() {
        for pair in chosenPairs {
            
            fetchStats(pair.id!, callback:  { (open, volume) in
                pair.open = open
                pair.volume = volume
            })
            
            fetchPrice(pair.id!, callback: { (price) in
                pair.price = price
                self.updateTitle()
            })
        }
    }
    
    func fetchPrice(pricePair:String, callback: (String?) -> Void) {
        let request = NSMutableURLRequest(URL: NSURL(string: "\(pairsURL)/\(pricePair)/ticker")!)
        Client.shared.getPrice(request) { (price) in
            callback(price)
        }
    }
    
    func fetchStats(pricePair:String, callback: (String?, String?) -> Void) {
        let request = NSMutableURLRequest(URL: NSURL(string: "\(pairsURL)/\(pricePair)/stats")!)
        Client.shared.getStats(request) { (open, volume) in
            callback(open, volume)
        }
    }

    func fetchPairs() {
        let request = NSMutableURLRequest(URL: NSURL(string: pairsURL)!)
        
        chosenPairs.removeAll()
        
        Client.shared.getPairs(request) { (pairs) in
            self.pairs = pairs!
            
            var firstPair: Pair!
            var secondPair: Pair!
            
            for pair in self.pairs {
                
                if pair.id == self.firstPairID {
                    firstPair = pair
                }
                if pair.id == self.secondPairID {
                    secondPair = pair
                }
            }
            
            self.chosenPairs.append(firstPair)
            self.chosenPairs.append(secondPair)
            
            self.preferencesWindow.pairs = self.pairs
            self.update()
            self.updateTimer()
        }
    }
    
    @IBAction func quitClicked(sender: NSMenuItem) {
        NSApplication.sharedApplication().terminate(self)
    }
    
    func showPreference(sender: NSMenuItem) {
        preferencesWindow.showWindow(nil)
    }
    
    func quit() {
        NSApp.performSelector(#selector(NSApp.terminate(_:)))
    }
    
    //MARK: PreferencesWindowDelegate
    func preferencesDidUpdate() {
        update()
    }
    
    func updateColourSymbols(on: Bool) {
        useColouredSymbols = on
        updateTitle()
    }
    
    func updateInterval(interval: NSTimeInterval) {
        self.interval = interval
        
        defaults.setObject(self.interval, forKey: UserDefaults.interval.rawValue)
        defaults.synchronize()
    
        updateTimer()
    }
    
    func updatePair(isFirstPair:Bool, title: String) {
        if isFirstPair == true {
            defaults.setObject(title, forKey: UserDefaults.firstPair.rawValue)
            firstPairID = title
        } else {
            defaults.setObject(title, forKey: UserDefaults.secondPair.rawValue)
            secondPairID = title
        }
        
        defaults.synchronize()
        fetchPairs()
    }
    
    //MARK: START AT LOGIN
    func toggleStartAtLogin(start:Bool) {
        let launcherAppIdentifier = "com.coinbase.bar.Barbar"
        
        SMLoginItemSetEnabled(launcherAppIdentifier, start)
        
        var startedAtLogin = false
        for app in NSWorkspace.sharedWorkspace().runningApplications {
            if app.bundleIdentifier == launcherAppIdentifier {
                startedAtLogin = true
            }
        }
        
        if startedAtLogin == true {
            NSDistributedNotificationCenter.defaultCenter().postNotificationName("killme", object: NSBundle.mainBundle().bundleIdentifier!)
        }
        
        defaults.setBool(start, forKey: UserDefaults.launchFromStart.rawValue)
        defaults.synchronize()
    }
    
    //MARK: Reachability
    func setupReachability(useHostName useHostName: Bool) {
        let hostName = "gdax.com"
        
        do {
            let reachability = try useHostName ? Reachability(hostname: hostName) : Reachability.reachabilityForInternetConnection()
            self.reachability = reachability
        } catch ReachabilityError.FailedToCreateWithAddress(let address) {
            print("Unable to create Reachability with address \(address)")
            return
        } catch {}
        
        reachability?.whenReachable = { reachability in
            self.showStatusItemImage(false)
            self.fetchPairs()
        }
        reachability?.whenUnreachable = { reachability in
            self.showStatusItemImage(true)
            self.statusItem.title = ""
            self.updateOfflineTitle()
        }
    }
    
    func startNotifier() {
        do {
            try reachability?.startNotifier()
        } catch {
            return
        }
    }
    
    func stopNotifier() {
        reachability!.stopNotifier()
        reachability = nil
    }
}
