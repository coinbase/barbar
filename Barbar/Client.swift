//
//  Client.swift
//  Barbar
//
//  Created by Dai Hovey on 9/08/2016.
//  Copyright © 2016 Coinbase. All rights reserved.
//

import Foundation

class Client: NSObject {
    
    static let shared = Client()
    
    func getPrice(request: NSMutableURLRequest, callback: (String?) -> Void) {
        httpGet(request){
            (response, error) -> Void in
            if error != nil {
                print(error)
            } else {
                if error != nil {
                    // ignore
                } else {
                    guard let result = response as? [String: AnyObject] else {
                        // ignore
                        return
                    }
                    guard let price = result["price"] as? String else {
                        // ignore
                        return
                    }
                    callback(price)
                }
            }
        }
    }
    
    func getStats(request: NSMutableURLRequest, callback: (open: String?, volume: String?) -> Void) {
        httpGet(request){
            (response, error) -> Void in
            if error != nil {
                print(error)
            } else {
                if error != nil {
                    // ignore
                } else {
                    guard let result = response as? [String: AnyObject] else {
                        // ignore
                        return
                    }
                    guard let open = result["open"] as? String else {
                        // ignore
                        return
                    }
                    guard let volume = result["volume"] as? String else {
                        // ignore
                        return
                    }
                    callback(open: open, volume: volume)
                }
            }
        }
    }

    func getPairs(request: NSMutableURLRequest , callback: ([Pair]?) -> Void) {
        httpGet(request){
            (response, error) -> Void in
            if error != nil {
                print(error)
            } else {
                if error != nil {
                    // ignore
                } else {
                    guard let result = response as? [[String: AnyObject]] else {
                        // ignore
                        return
                    }
                    var pairs: [Pair] = []
                    for aPair in result {
                        let pair = Pair()
                        if let id = aPair["id"] as? String {
                            pair.id = id
                        }
                        if let baseCurrency = aPair["base_currency"] as? String {
                            pair.baseCurrency = baseCurrency
                        }
                        if let quoteCurrency = aPair["quote_currency"] as? String {
                            pair.quoteCurrency = quoteCurrency
                        }
                        if let displayName = aPair["display_name"] as? String {
                            pair.displayName = displayName
                        }
                        pairs.append(pair)
                    }
                    callback(pairs)
                }
            }
        }
    }
    
    func httpGet(request: NSURLRequest!, callback: (AnyObject?, String?) -> Void) {
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request){
            (data, response, error) -> Void in
            if error != nil {
                callback(nil, error!.localizedDescription)
            } else {
                if let data = data {
                    if data.length == 0 {
                        callback(nil, nil)
                    }
                    do {
                        let object:AnyObject? = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
                        callback(object, nil)
                    } catch let caught as NSError {
                        callback("", caught.localizedDescription)
                    } catch {
                        // Something else happened.
                        let error = NSError(domain: "BARBAR", code: 1, userInfo: nil)
                        callback("", error.localizedDescription)
                    }
                }
            }
        }
        task.resume()
    }
}