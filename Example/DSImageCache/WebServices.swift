//
//  WebServices.swift
//  DSImageCache
//
//  Created by dsonara on 04/01/2017.
//  Copyright (c) 2017 dsonara. All rights reserved.
//

import Foundation

class WebServices: NSObject, URLSessionDelegate, URLSessionTaskDelegate {

    class func executeRequest(_ request: URLRequest, WithCompletion completionBlock: @escaping (_ json: AnyObject?, _ connectionError: NSError?) -> Void) {
        
        let session = URLSession.shared
                // New
        let task = session.dataTask(with: request, completionHandler: {
            (data, response, error) in
        
            if error != nil {
                completionBlock(nil, error as NSError?)
            } else {
                do {
                    var json: AnyObject!
                    json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as AnyObject?
                        //Implement your logic
                        completionBlock(json, nil)

                } catch {
                    completionBlock(nil, error as NSError)
                }
            }
        })
        task.resume()
        
    }
    
    //MARK: ---
    
    class func getData(Completion completionBlock: @escaping (_ json: AnyObject?, _ connectionError: NSError?) -> Void) {
        DispatchQueue.global().async {
            // qos' default value is ´DispatchQoS.QoSClass.default`
            let request: NSMutableURLRequest = NSMutableURLRequest()
            request.url = URL(string: "https://pastebin.com/raw/wgkJgazE")
            request.httpMethod = "GET"
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            executeRequest(request as URLRequest, WithCompletion: completionBlock)
        }
    }
    
}
