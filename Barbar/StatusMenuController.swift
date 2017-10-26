//
//  StatusMenuController.swift
//  Barbar
//
//  Created by Dai Hovey on 27/05/2016.
//  Copyright © 2016 Coinbase. All rights reserved.
//

import Cocoa
import ServiceManagement
import AppKit

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
    var interval:TimeInterval!
    var timer: Timer!
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
	var font:  [String : NSObject]!
	var useColouredSymbols = true
	
    let statusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)
    let defaults = Foundation.UserDefaults.standard
    let pairsURL = "https://api.gdax.com/products"
    let green = NSColor.init(red: 22/256, green: 206/255, blue: 0/256, alpha: 1)
    let red = NSColor.init(red: 255/256, green: 73/255, blue: 0/256, alpha: 1)
	let white = NSColor.init(red: 255, green: 255, blue: 255, alpha: 1)
    
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
		
		// Check for dark menubar
		if defaults.string(forKey: "AppleInterfaceStyle") == "Dark" {
			font = [NSFontAttributeName: NSFont.systemFont(ofSize: 15), NSForegroundColorAttributeName: white]
		} else {
			font = [NSFontAttributeName: NSFont.menuBarFont(ofSize: 15)]
		}
		
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
        })
    }
    
    func updateTitle() {
        if (chosenPairs.count == 1 && chosenPairs[0].price != nil) ||
            (chosenPairs.count == 2 && chosenPairs[0].price != nil && chosenPairs[1].price != nil) {
            
            DispatchQueue.main.async(execute: {
                
                let firstPair = self.chosenPairs[0]
                let secondPair = self.chosenPairs[1]
                
                var firstSymbol: String! = ""
                var secondSymbol: String! = ""
                
                if let first = self.chosenPairs[0].price,
                    let quote = self.chosenPairs[0].quoteCurrency,
                    let base = self.chosenPairs[0].baseCurrency {
                    self.firstPrice = CurrencyFormatter.sharedInstance.formatAmountString(first, currency: quote, options: nil)
                    
                    if base == "BTC" {
                        firstSymbol = "Ƀ"
                    } else if base == "ETH" {
                        firstSymbol = "Ξ"
					} else if base == "LTC" {
						secondSymbol = "L"
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
						secondSymbol = "L"
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

                mutableAttributedString.append(firstSymbolAtt)
				mutableAttributedString.append(NSAttributedString(string:" "))
                mutableAttributedString.append(firstPriceAtt)
                mutableAttributedString.append(NSAttributedString(string:" "))
                mutableAttributedString.append(secondSymbolAtt)
				mutableAttributedString.append(NSAttributedString(string:" "))
                mutableAttributedString.append(secondPriceAtt)
                
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
    
    func updatePair(_ isFirstPair:Bool, title: String) {
        if isFirstPair == true {
            defaults.set(title, forKey: UserDefaults.firstPair.rawValue)
            firstPairID = title
        } else {
            defaults.set(title, forKey: UserDefaults.secondPair.rawValue)
            secondPairID = title
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
