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
    
    func getPrice(_ request: URLRequest, callback: @escaping (String?) -> Void) {
        httpGet(request){
            (response, error) -> Void in
			
			if let error = error {
                print(error)
				return
            }
		
			guard let result = response as? [String: AnyObject],
				let price = result["price"] as? String else { return }
			
			callback(price)
        }
    }
    
    func getStats(_ request: URLRequest, callback: @escaping (_ open: String?, _ volume: String?) -> Void) {
        httpGet(request){
            (response, error) -> Void in
			
			if let error = error {
				print(error)
				return
			}
			
			guard let result = response as? [String: AnyObject],
				let open = result["open"] as? String,
				let volume = result["volume"] as? String else { return }
			
			callback(open, volume)
        }
    }

    func getPairs(_ request: URLRequest , callback: @escaping ([Pair]?) -> Void) {
        httpGet(request){
            (response, error) -> Void in
			if let error = error {
				print(error)
				return
			}
			
			guard let result = response as? [[String: AnyObject]] else { return }
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
    
    func httpGet(_ request: URLRequest, callback: @escaping (AnyObject?, String?) -> Void) {
        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: {
            (data, response, error) -> Void in
            if let error = error {
                callback(nil, error.localizedDescription)
				return
            }
			guard let data = data else { return }
				
			if data.count == 0 {
				callback(nil, nil)
			}
			do {
				let object: Any? = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
				callback(object as AnyObject?, nil)
			} catch let caught as NSError {
				callback("" as AnyObject?, caught.localizedDescription)
			} catch {
				// Something else happened.
				let error = NSError(domain: "BARBAR", code: 1, userInfo: nil)
				callback("" as AnyObject?, error.localizedDescription)
			}
        })
        task.resume()
    }
}
