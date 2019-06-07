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
    
    var pairID: String?
    
    override init(frame: NSRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder);
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if Foundation.UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark" {
            self.currentprice.textColor = NSColor.init(red: 255, green: 255, blue: 255, alpha: 1)
        } else {
            self.currentprice.textColor = NSColor.init(red: 0, green: 0, blue: 0, alpha: 1)
        }
    }
    
    func update(_ pair: Pair?, price: String?, pairID: String?) {
        
        DispatchQueue.main.async {
			
			if let pairID = pairID {
				self.pairID = pairID
			}
			
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

			let percentString = "\(CurrencyFormatter.sharedInstance.percentFormatter.string(from: NSNumber(value: pair.percent()))!)%"
            
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
        DispatchQueue.main.async {
            
            self.priceDifference.stringValue = "No Internet!"
            self.priceDifference.textColor = self.red
            
            self.currencyPair.stringValue = "DERP/LOL"
            self.currentprice.stringValue = "🤔"
        }
    }
    
    override func mouseUp(with theEvent: NSEvent) {
        if let sitePicker = Foundation.UserDefaults.standard.object(forKey: "site") as? String {
            if sitePicker == "Coinbase" {
                NSWorkspace.shared().open(URL(string: "https://www.coinbase.com/trade")!)
                return
            }
        }
		
		guard let pairID = pairID else {
			NSWorkspace.shared().open(URL(string: "http://api.pro.coinbase.com/trade")!)
			return
		}
		
		NSWorkspace.shared().open(URL(string: "http://api.pro.coinbase.com/trade/\(pairID)")!)
		
    }
    
    override func acceptsFirstMouse(for theEvent: NSEvent?) -> Bool {
        return true
    }
}
