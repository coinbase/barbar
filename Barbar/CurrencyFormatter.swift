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
    var locale: NSLocale? = nil
    var allowTruncation = false
}

class CurrencyFormatter: NSObject {
    
    static let sharedInstance = CurrencyFormatter()
    
    let formatter = NSNumberFormatter()
    let stringFromNumberFormatter = NSNumberFormatter()
    let truncatingFormatter = NSNumberFormatter()
    let percentFormatter = NSNumberFormatter()
    
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

        stringFromNumberFormatter.locale = NSLocale(localeIdentifier: "en_US")
        stringFromNumberFormatter.minimumIntegerDigits = 1
        stringFromNumberFormatter.maximumFractionDigits = 8
        
        percentFormatter.minimumIntegerDigits = 1
        percentFormatter.maximumFractionDigits = 2
    }
    
    func stringFromNumber(amount: Double) -> String {
        return stringFromNumberFormatter.stringFromNumber(amount)!
    }
    
    func formatAmountString(amount: String, currency: String, options: CurrencyFormatterOptions?) -> String {
        return formatAmount((amount as NSString).doubleValue, currency: currency, options: options)
    }
    
    func formatAmount(amount: Double, currency: String, options: CurrencyFormatterOptions?) -> String {
        
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
            formatter.locale = NSLocale(localeIdentifier: "en_US")
        }
        
        formatter.minimumIntegerDigits = 1
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        
        if formatOptions.allowTruncation == true {
            return formatTruncating(amount, currency: currency, options: formatOptions)
        }
        
        return formatSymbolAndPrefix(amount, currency: currency, numFormatter: formatter, options: formatOptions)
    }
    
    private func formatTruncating(amount: Double, currency: String, options: CurrencyFormatterOptions) -> String {
        
        formatter.currencySymbol = ""
        
        let tempOutput = formatter.stringFromNumber(amount)!
        let dotIndex = tempOutput.rangeOfString(".")?.startIndex
        let currentNumberOfFractionDigits = dotIndex == nil ? 0 : (tempOutput.substringFromIndex(dotIndex!).characters.count - 1)
        
        if options.allowTruncation && (currentNumberOfFractionDigits > 2) {
            return formatSymbolAndPrefix(amount, currency: currency, numFormatter: truncatingFormatter, options: options)
        }
        
        return formatSymbolAndPrefix(amount, currency: currency, numFormatter: formatter, options: options)
    }
    
    private func formatSymbolAndPrefix(amount: Double, currency: String, numFormatter: NSNumberFormatter, options: CurrencyFormatterOptions) -> String {
        var output = ""
        output = formatSymbol(amount, currency: currency, numFormatter: numFormatter, options: options)
        output = formatPrefix(amount, output: output, options: options)
        return output
    }
    
    private func formatSymbol(amount: Double, currency: String, numFormatter: NSNumberFormatter, options: CurrencyFormatterOptions) -> String {
        var output = ""
        if options.addCurrencySymbol {
            if let currencyCode = currencies[currency] {
                numFormatter.numberStyle = NSNumberFormatterStyle.CurrencyStyle
                numFormatter.currencySymbol = currencyCode
                output = numFormatter.stringFromNumber(amount)!
            } else {
                if currency.characters.count > 0 {
                    numFormatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
                    output = "\(numFormatter.stringFromNumber(amount)!) \(currency)"
                } else {
                    numFormatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
                    output = "\(numFormatter.stringFromNumber(amount)!)"
                }
            }
        } else {
            numFormatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
            output = numFormatter.stringFromNumber(amount)!
        }
        return output
    }
    
    private func formatPrefix(amount: Double, output: String, options: CurrencyFormatterOptions) -> String {
        var formattedOutput = output
        if options.showPositivePrefix && amount > 0 {
            formattedOutput = "\(formatter.plusSign)\(formattedOutput)"
        }
        if options.showNegativePrefix == false && amount < 0 {
            // Setting formatter.negativePrefix messes up currency symbols so just chop off first character
            formattedOutput = formattedOutput
                .substringFromIndex(formattedOutput.startIndex.advancedBy(1))
        }
        return formattedOutput
    }
}
