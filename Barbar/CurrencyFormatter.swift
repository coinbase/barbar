//
//  CurrencyFormatter.swift
//  Barbar
//
//  Created by Dai Hovey on 3/06/2016.
//  Copyright © 2016 Coinbase. All rights reserved.
//

import Foundation

class CurrencyFormatterOptions: NSObject {
    var addCurrencySymbol = true
    var showPositivePrefix = false
    var showNegativePrefix = true
    var locale: Locale? = nil
    var allowTruncation = false
}

class CurrencyFormatter: NSObject {
    
    static let sharedInstance = CurrencyFormatter()
    
    let formatter = NumberFormatter()
    let stringFromNumberFormatter = NumberFormatter()
    let truncatingFormatter = NumberFormatter()
    let percentFormatter = NumberFormatter()
    
    let currencies = [
        "USD": "$",
        "EUR": "€",
        "JPY": "¥",
        "GBP": "₤",
        "CAD": "$",
        "KRW": "₩",
        "CNY": "¥",
        "AUD": "$",
        "BRL": "R$",
        "IDR": "Rp",
        "MXN": "$",
        "SGD": "$",
        "CHF": "Fr."
    ]
    
    override init() {
        
        // Setup non standard formatters
        truncatingFormatter.usesSignificantDigits = true
        truncatingFormatter.maximumSignificantDigits = 5
        truncatingFormatter.minimumSignificantDigits = 0
        truncatingFormatter.maximumFractionDigits = 8
        truncatingFormatter.minimumFractionDigits = 2
        truncatingFormatter.locale = nil
        truncatingFormatter.minimumIntegerDigits = 1

        stringFromNumberFormatter.locale = Locale(identifier: "en_US")
        stringFromNumberFormatter.minimumIntegerDigits = 1
        stringFromNumberFormatter.maximumFractionDigits = 8
        
        percentFormatter.minimumIntegerDigits = 1
        percentFormatter.maximumFractionDigits = 2
    }
    
    func stringFromNumber(_ amount: Double) -> String {
        return stringFromNumberFormatter.string(from: NSNumber(value: amount))!
    }
    
    func formatAmountString(_ amount: String, currency: String, options: CurrencyFormatterOptions?) -> String {
        return formatAmount((amount as NSString).doubleValue, currency: currency, options: options)
    }
    
    func formatAmount(_ amount: Double, currency: String, options: CurrencyFormatterOptions?) -> String {
        
        var formatOptions = CurrencyFormatterOptions()
        
        if let options = options {
            formatOptions = options
        }
        
        let amount = amount
        let currency = currency
        
        if let locale = formatOptions.locale {
            formatter.locale = locale
            formatter.usesGroupingSeparator = true
        } else {
            formatter.locale = Locale(identifier: "en_US")
        }
        
        formatter.minimumIntegerDigits = 1
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        
        if formatOptions.allowTruncation == true {
            return formatTruncating(amount, currency: currency, options: formatOptions)
        }
        
        return formatSymbolAndPrefix(amount, currency: currency, numFormatter: formatter, options: formatOptions)
    }
    
    fileprivate func formatTruncating(_ amount: Double, currency: String, options: CurrencyFormatterOptions) -> String {
        
        formatter.currencySymbol = ""
        
        let tempOutput = formatter.string(from: NSNumber(value: amount))!
        let dotIndex = tempOutput.range(of: ".")?.lowerBound
        let currentNumberOfFractionDigits = dotIndex == nil ? 0 : (tempOutput[dotIndex!...].count - 1)
        
        if options.allowTruncation && (currentNumberOfFractionDigits > 2) {
            return formatSymbolAndPrefix(amount, currency: currency, numFormatter: truncatingFormatter, options: options)
        }
        
        return formatSymbolAndPrefix(amount, currency: currency, numFormatter: formatter, options: options)
    }
    
    fileprivate func formatSymbolAndPrefix(_ amount: Double, currency: String, numFormatter: NumberFormatter, options: CurrencyFormatterOptions) -> String {
        var output = ""
        output = formatSymbol(amount, currency: currency, numFormatter: numFormatter, options: options)
        output = formatPrefix(amount, output: output, options: options)
        return output
    }
    
    fileprivate func formatSymbol(_ amount: Double, currency: String, numFormatter: NumberFormatter, options: CurrencyFormatterOptions) -> String {
        var output = ""
        if options.addCurrencySymbol {
            if let currencyCode = currencies[currency] {
                numFormatter.numberStyle = NumberFormatter.Style.currency
                numFormatter.currencySymbol = currencyCode
                output = numFormatter.string(from: NSNumber(value: amount))!
            } else {
                if currency.count > 0 {
                    numFormatter.numberStyle = NumberFormatter.Style.decimal
                    output = "\(numFormatter.string(from: NSNumber(value: amount))!) \(currency)"
                } else {
                    numFormatter.numberStyle = NumberFormatter.Style.decimal
                    output = "\(numFormatter.string(from: NSNumber(value: amount))!)"
                }
            }
        } else {
            numFormatter.numberStyle = NumberFormatter.Style.decimal
            output = numFormatter.string(from: NSNumber(value: amount))!
        }
        return output
    }
    
    fileprivate func formatPrefix(_ amount: Double, output: String, options: CurrencyFormatterOptions) -> String {
        var formattedOutput = output
        if options.showPositivePrefix && amount > 0 {
            formattedOutput = "\(formatter.plusSign!)\(formattedOutput)"
        }
        if options.showNegativePrefix == false && amount < 0 {
            // Setting formatter.negativePrefix messes up currency symbols so just chop off first character
            let index = formattedOutput.index(formattedOutput.startIndex, offsetBy: 1)
            formattedOutput = String(formattedOutput[index...])
        }
        return formattedOutput
    }
}
