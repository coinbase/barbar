//
//  Pair.swift
//  Barbar
//
//  Created by Dai Hovey on 27/05/2016.
//  Copyright © 2016 Coinbase. All rights reserved.
//

import Foundation

class Pair: NSObject {
    var id: String?
    var baseCurrency: String?
    var quoteCurrency: String?
    var displayName: String?
    var price: String?
    var open: String?
    var volume: String?
    
    let zero = 0.0
    
    func difference () -> Double {
        guard let price = self.price else {
            return zero
        }
        
        guard let doublePrice = Double(price) else {
            return zero
        }
        
        guard let open = self.open else {
            return zero
        }
        
        guard let openDouble = Double(open) else {
            return zero
        }
        let diff = doublePrice - openDouble
        return diff
    }
    
    func percent() -> Double {
        guard let price = self.price else {
            return zero
        }
        
        guard let doublePrice = Double(price) else {
            return zero
        }
        
        guard let open = self.open else {
            return zero
        }
        
        guard let openDouble = Double(open) else {
            return zero
        }

        let percent =  ((1/(openDouble / doublePrice)) - 1) * 100
        return percent
    }
}