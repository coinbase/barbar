//
//  DetailView.swift
//  Barbar
//
//  Created by Dai Hovey on 3/06/2016.
//  Copyright © 2016 Coinbase. All rights reserved.
//

import Cocoa

class DetailView: NSView {

    @IBOutlet weak var volume: NSTextField!
    @IBOutlet weak var currentprice: NSTextField!
    @IBOutlet weak var priceDifference: NSTextField!
    @IBOutlet weak var currencyPair: NSTextField!
    
    let green = NSColor.init(red: 22/256, green: 206/255, blue: 0/256, alpha: 1)
    let red = NSColor.init(red: 255/256, green: 73/255, blue: 0/256, alpha: 1)
    
    var pairID: String!
    
    override init(frame: NSRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder);
    }
    
    func update(pair: Pair?, price: String?, pairID: String?) {
        
        dispatch_async(dispatch_get_main_queue()) {
            
            self.pairID = pairID

            if let price = price  {
                self.currentprice.stringValue = "\(price)"
            } else {
                self.currentprice.stringValue = ""
                self.priceDifference.stringValue = ""
            }
            
            guard let pair = pair else {
                self.currencyPair.stringValue = "Loading..."
                return
            }
            
            if let currencyPair = pair.displayName {
                self.currencyPair.stringValue = currencyPair
            }
            
            guard let _ = pair.open else {
                return
            }

            let percentString = "\(CurrencyFormatter.sharedInstance.percentFormatter.stringFromNumber(pair.percent())!)%"
            
            let diffString = "\(pair.difference())"
            
            let options = CurrencyFormatterOptions()
            options.showPositivePrefix = true
            options.showNegativePrefix = true
            
            self.priceDifference.stringValue = "\(CurrencyFormatter.sharedInstance.formatAmountString(diffString, currency: "USD", options: options))  \(percentString)"
            
            if pair.difference() < 0 {
                self.priceDifference.textColor = self.red
            } else {
                self.priceDifference.textColor = self.green
            }
        }
    }
    
    func updateOffline() {
        dispatch_async(dispatch_get_main_queue()) {
            
            self.priceDifference.stringValue = "No Internet!"
            self.priceDifference.textColor = self.red
            
            self.currencyPair.stringValue = "DERP/LOL"
            self.currentprice.stringValue = "🤔"
        }
    }
    
    override func mouseUp(theEvent: NSEvent) {
        if let sitePicker = NSUserDefaults.standardUserDefaults().objectForKey("site") as? String {
            if sitePicker == "Coinbase" {
                NSWorkspace.sharedWorkspace().openURL(NSURL(string: "https://www.coinbase.com/trade")!)
                return
            }
        }
        NSWorkspace.sharedWorkspace().openURL(NSURL(string: "http://www.gdax.com/trade/\(pairID)")!)
    }
    
    override func acceptsFirstMouse(theEvent: NSEvent?) -> Bool {
        return true
    }
}
