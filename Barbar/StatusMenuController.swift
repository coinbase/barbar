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
        static let ltcUSD = "LTC-USD"
    }
    
    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var firstDetailView: DetailView!
    @IBOutlet weak var secondDetailView: DetailView!
    @IBOutlet weak var thirdDetailView: DetailView!

    var firstPairViewMenuItem: NSMenuItem!
    var secondPairViewMenuItem: NSMenuItem!
    var thirdPairViewMenuItem: NSMenuItem!
    var interval:TimeInterval!
    var timer: Timer!
    var firstPrice = ""
    var secondPrice = ""
    var thirdPrice = ""
    var pairs: [Pair] = []
    var firstPairID: String!
    var secondPairID: String!
    var thirdPairID: String!
    var chosenPairs: [Pair] = []
    var preferencesWindow: PreferencesWindow!
    var reachability: Reachability?
    var fontPosistive: [String : NSObject]!
    var fontNegative: [String : NSObject]!
    var useColouredSymbols = true
    
    let statusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)
    let defaults = Foundation.UserDefaults.standard
    let font = [NSFontAttributeName: NSFont.systemFont(ofSize: 15)]
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
        let dispatchTime = DispatchTime.now() + Double(Int64(UInt64(5) * NSEC_PER_SEC)) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: dispatchTime) {
            self.stopNotifier()
            self.setupReachability(useHostName: true)
            self.startNotifier()
        }
    }

    //MARK: SETUP
    func setup() {
        
        fontPosistive = [NSFontAttributeName: NSFont.systemFont(ofSize: 15), NSForegroundColorAttributeName: green]
        fontNegative = [NSFontAttributeName: NSFont.systemFont(ofSize: 15), NSForegroundColorAttributeName: red]
        
        if let interval = defaults.object(forKey: UserDefaults.interval.rawValue) as? TimeInterval {
            self.interval = interval
        } else {
            self.interval = TimeInterval(60)  // Default is 60 seconds
            defaults.set(self.interval, forKey: UserDefaults.interval.rawValue)
        }
        
        if let firstPair = defaults.object(forKey: UserDefaults.firstPair.rawValue) as? String {
            firstPairID = firstPair
        } else {
            firstPairID = URL.btcUSD // Default
            defaults.set(firstPairID, forKey: UserDefaults.firstPair.rawValue)
        }
        
        if let secondPair = defaults.object(forKey: UserDefaults.secondPair.rawValue) as? String {
            secondPairID = secondPair
        } else {
            secondPairID = URL.ethUSD // Default
            defaults.set(secondPairID, forKey: UserDefaults.secondPair.rawValue)
        }
        
        if let thirdPair = defaults.object(forKey: UserDefaults.thirdPair.rawValue) as? String {
            thirdPairID = thirdPair
        } else {
            thirdPairID = URL.ltcUSD // Default
            defaults.set(thirdPairID, forKey: UserDefaults.thirdPair.rawValue)
        }
        
        var startAtLogin = false
        if defaults.object(forKey: UserDefaults.launchFromStart.rawValue) == nil {
            startAtLogin = true // Default
            defaults.set(true, forKey: UserDefaults.launchFromStart.rawValue)
        } else {
            startAtLogin = defaults.bool(forKey: UserDefaults.launchFromStart.rawValue)
        }
        
        toggleStartAtLogin(startAtLogin)
        
        if defaults.object(forKey: UserDefaults.colorSymbols.rawValue) == nil {
            useColouredSymbols = true // Default
            defaults.set(true, forKey: UserDefaults.colorSymbols.rawValue)
        } else {
            useColouredSymbols = defaults.bool(forKey: UserDefaults.colorSymbols.rawValue)
        }

        defaults.synchronize()
    }
    
    func setupViews() {
        statusItem.menu = statusMenu
        showStatusItemImage(true)
        
        firstPairViewMenuItem = statusMenu.item(withTitle: "FirstPairView")
        firstPairViewMenuItem.view = firstDetailView
        
        secondPairViewMenuItem = statusMenu.item(withTitle: "SecondPairView")
        secondPairViewMenuItem.view = secondDetailView
        
        thirdPairViewMenuItem = statusMenu.item(withTitle: "ThirdPairView")
        thirdPairViewMenuItem.view = thirdDetailView
        
        preferencesWindow = PreferencesWindow()
        preferencesWindow.delegate = self
    }
    
    func updateTimer() {
        if timer != nil {
            if timer.isValid == true {
                timer.invalidate()
            }
        }
        
        timer = Timer(timeInterval: interval, target: self, selector: #selector(update), userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: RunLoopMode.commonModes)
    }
    
    func update() {
        fetchPairsPrice()
    }
    
    func showStatusItemImage(_ show: Bool) {
        if show == true {
            statusItem.image = NSImage(named: "iconTemplate") // Just show while loading
        } else {
            statusItem.image = nil
        }
    }
    
    func updateOfflineTitle() {
        DispatchQueue.main.async(execute: {
            self.firstDetailView.updateOffline()
            self.secondDetailView.updateOffline()
            self.thirdDetailView.updateOffline()
        })
    }
    
    func updateTitle() {
        if (chosenPairs.count == 1 && chosenPairs[0].price != nil) ||
            (chosenPairs.count == 2 && chosenPairs[0].price != nil && chosenPairs[1].price != nil) ||
             (chosenPairs.count == 3 && chosenPairs[0].price != nil && chosenPairs[1].price != nil && chosenPairs[2].price != nil){
            
            DispatchQueue.main.async(execute: {
                
                let firstPair = self.chosenPairs[0]
                let secondPair = self.chosenPairs[1]
                let thirdPair = self.chosenPairs[2]
                
                var firstSymbol: String!
                var secondSymbol: String!
                var thirdSymbol: String!
                
                if let first = self.chosenPairs[0].price,
                    let quote = self.chosenPairs[0].quoteCurrency,
                    let base = self.chosenPairs[0].baseCurrency {
                    self.firstPrice = CurrencyFormatter.sharedInstance.formatAmountString(first, currency: quote, options: nil)
                    
                    if base == "BTC" {
                        firstSymbol = "Ƀ"
                    } else if base == "ETH" {
                        firstSymbol = "Ξ"
                    } else if base == "LTC" {
                        firstSymbol = "Ł"
                    }
                }
                
                if let second = self.chosenPairs[1].price,
                    let quote = self.chosenPairs[1].quoteCurrency,
                    let base = self.chosenPairs[1].baseCurrency {
                    self.secondPrice = CurrencyFormatter.sharedInstance.formatAmountString(second, currency: quote, options: nil)
                    
                    if base == "BTC" {
                        secondSymbol = "Ƀ"
                    } else if base == "ETH" {
                        secondSymbol = "Ξ"
                    } else if base == "LTC" {
                        secondSymbol = "Ł"
                    }
                }
                
                if let third = self.chosenPairs[2].price,
                    let quote = self.chosenPairs[2].quoteCurrency,
                    let base = self.chosenPairs[2].baseCurrency {
                    self.thirdPrice = CurrencyFormatter.sharedInstance.formatAmountString(third, currency: quote, options: nil)
                    
                    if base == "BTC" {
                        thirdSymbol = "Ƀ"
                    } else if base == "ETH" {
                        thirdSymbol = "Ξ"
                    } else if base == "LTC" {
                        thirdSymbol = "Ł"
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
                
                var thirdFont: [String : NSObject]!
                if thirdPair.percent() < 0 {
                    thirdFont = self.fontNegative
                } else {
                    thirdFont = self.fontPosistive
                }
                
                let firstSymbolAtt =  NSAttributedString(string:firstSymbol, attributes: self.useColouredSymbols ? firstFont: self.font)
                let firstPriceAtt = NSAttributedString(string:self.firstPrice, attributes: self.font)

                let secondSymbolAtt =  NSAttributedString(string:secondSymbol, attributes: self.useColouredSymbols ? secondFont: self.font)
                let secondPriceAtt = NSAttributedString(string:self.secondPrice, attributes: self.font)
                
                let thirdSymbolAtt =  NSAttributedString(string:thirdSymbol, attributes: self.useColouredSymbols ? thirdFont: self.font)
                let thirdPriceAtt = NSAttributedString(string:self.thirdPrice, attributes: self.font)

                mutableAttributedString.append(firstSymbolAtt)
                mutableAttributedString.append(firstPriceAtt)
                mutableAttributedString.append(NSAttributedString(string:" "))
                mutableAttributedString.append(secondSymbolAtt)
                mutableAttributedString.append(secondPriceAtt)
                mutableAttributedString.append(NSAttributedString(string:" "))
                mutableAttributedString.append(thirdSymbolAtt)
                mutableAttributedString.append(thirdPriceAtt)
                
                self.statusItem.attributedTitle = mutableAttributedString
                self.firstDetailView.update(firstPair, price: self.firstPrice, pairID: self.firstPairID)
                self.secondDetailView.update(secondPair, price: self.secondPrice, pairID: self.secondPairID)
                self.thirdDetailView.update(thirdPair, price: self.thirdPrice, pairID: self.thirdPairID)
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
    
    func fetchPrice(_ pricePair:String, callback: @escaping (String?) -> Void) {
        let request = URLRequest(url: Foundation.URL(string: "\(pairsURL)/\(pricePair)/ticker")!)
        Client.shared.getPrice(request) { (price) in
            callback(price)
        }
    }
    
    func fetchStats(_ pricePair:String, callback: @escaping (String?, String?) -> Void) {
        let request = URLRequest(url: Foundation.URL(string: "\(pairsURL)/\(pricePair)/stats")!)
        Client.shared.getStats(request) { (open, volume) in
            callback(open, volume)
        }
    }

    func fetchPairs() {
        let request = URLRequest(url: Foundation.URL(string: pairsURL)!)
        
        chosenPairs.removeAll()
        
        Client.shared.getPairs(request) { (pairs) in
            self.pairs = pairs!
            
            var firstPair: Pair!
            var secondPair: Pair!
            var thirdPair: Pair!
            
            for pair in self.pairs {
                
                if pair.id == self.firstPairID {
                    firstPair = pair
                }
                if pair.id == self.secondPairID {
                    secondPair = pair
                }
                if pair.id == self.thirdPairID {
                    thirdPair = pair
                }
                
            }
            
            self.chosenPairs.append(firstPair)
            self.chosenPairs.append(secondPair)
            self.chosenPairs.append(thirdPair)
            
            self.preferencesWindow.pairs = self.pairs
            self.update()
            self.updateTimer()
        }
    }
    
    @IBAction func quitClicked(_ sender: NSMenuItem) {
        NSApplication.shared().terminate(self)
    }
    
    func showPreference(_ sender: NSMenuItem) {
        preferencesWindow.showWindow(nil)
    }
    
    func quit() {
        NSApp.perform(#selector(NSApp.terminate(_:)))
    }
    
    //MARK: PreferencesWindowDelegate
    func preferencesDidUpdate() {
        update()
    }
    
    func updateColourSymbols(_ on: Bool) {
        useColouredSymbols = on
        updateTitle()
    }
    
    func updateInterval(_ interval: TimeInterval) {
        self.interval = interval
        
        defaults.set(self.interval, forKey: UserDefaults.interval.rawValue)
        defaults.synchronize()
    
        updateTimer()
    }
    
    func updatePair(_ pairNum:Int, title: String) {
        if pairNum == 1 {
            defaults.set(title, forKey: UserDefaults.firstPair.rawValue)
            firstPairID = title
        } else if pairNum == 2 {
            defaults.set(title, forKey: UserDefaults.secondPair.rawValue)
            secondPairID = title
        } else if pairNum == 3 {
            defaults.set(title, forKey: UserDefaults.thirdPair.rawValue)
            thirdPairID = title
        }
        
        defaults.synchronize()
        fetchPairs()
    }
    
    //MARK: START AT LOGIN
    func toggleStartAtLogin(_ start:Bool) {
        let launcherAppIdentifier = "com.coinbase.bar.Barbar"
        
        SMLoginItemSetEnabled(launcherAppIdentifier as CFString, start)
        
        var startedAtLogin = false
        for app in NSWorkspace.shared().runningApplications {
            if app.bundleIdentifier == launcherAppIdentifier {
                startedAtLogin = true
            }
        }
        
        if startedAtLogin == true {
			
			DistributedNotificationCenter.default().postNotificationName(NSNotification.Name(rawValue: "killme"),
			                                                             object: Bundle.main.bundleIdentifier!,
			                                                             userInfo: nil,
			                                                             deliverImmediately: true)
        }
        
        defaults.set(start, forKey: UserDefaults.launchFromStart.rawValue)
        defaults.synchronize()
    }
    
    //MARK: Reachability
    func setupReachability(useHostName: Bool) {
        let hostName = "gdax.com"
		
		self.reachability = useHostName ? Reachability(hostname: hostName) : Reachability()
		
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
