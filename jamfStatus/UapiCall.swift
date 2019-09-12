//
//  UapiCall.swift
//  jamfStatus
//
//  Created by Leslie Helou on 9/1/19.
//  Copyright © 2019 Leslie Helou. All rights reserved.
//

// get notifications from https://jamf.pro.server/uapi/notifications/alerts


import Foundation

class UapiCall: NSObject, URLSessionDelegate, URLSessionDataDelegate, URLSessionTaskDelegate {
    
    let defaults = UserDefaults.standard
    var theUapiQ = OperationQueue() // create operation queue for API calls
//    let jps      = Preferences().jamfServerUrl
//    let b64user  = Preferences().username.data(using: .utf8)?.base64EncodedString() ?? ""
//    let b64pass  = Preferences().password.data(using: .utf8)?.base64EncodedString() ?? ""
    
    
    func get(endpoint: String, completion: @escaping (_ notificationAlerts: [Dictionary<String,Any>]) -> Void) {
        
        var b64user = ""
        var b64pass = ""
        
        let jps        = defaults.string(forKey:"jamfServerUrl") ?? ""
        let urlRegex   = try! NSRegularExpression(pattern: "http(.*?)://", options:.caseInsensitive)
        let serverFqdn = urlRegex.stringByReplacingMatches(in: jps, options: [], range: NSRange(0..<jps.utf16.count), withTemplate: "")
        
        // search the keychain for credentials
        let credentialsArray = Credentials2().retrieve(service: "jamfStatus: \(serverFqdn)")
        if credentialsArray.count == 2 {
            b64user = credentialsArray[0]
            b64pass = credentialsArray[1]
        } else {
            print("credentials not found")
            completion([])
            return
        }
        
        let b64creds = ("\(b64user):\(b64pass)".data(using: .utf8)?.base64EncodedString())!
        
        token(serverUrl: jps, creds: b64creds) {
            (returnedToken: String) in
            if returnedToken == "" {
                print("unable to get token")
                completion([])
                return
            }
            
            URLCache.shared.removeAllCachedResponses()
            
            var workingUrlString = "\(jps)/uapi/\(endpoint)"
            workingUrlString     = workingUrlString.replacingOccurrences(of: "//uapi", with: "/uapi")
            
            self.theUapiQ.maxConcurrentOperationCount = 1
            let semaphore = DispatchSemaphore(value: 0)
            
            self.theUapiQ.addOperation {
                
                let encodedURL = NSURL(string: workingUrlString)
                let request = NSMutableURLRequest(url: encodedURL! as URL)
                
                let configuration  = URLSessionConfiguration.default
                request.httpMethod = "GET"
                
                configuration.httpAdditionalHeaders = ["Authorization" : "Bearer \(returnedToken)", "Content-Type" : "application/json", "Accept" : "application/json"]
                let session = Foundation.URLSession(configuration: configuration, delegate: self as URLSessionDelegate, delegateQueue: OperationQueue.main)
                let task = session.dataTask(with: request as URLRequest, completionHandler: {
                    (data, response, error) -> Void in
                    if let httpResponse = response as? HTTPURLResponse {
                        if httpResponse.statusCode >= 200 && httpResponse.statusCode <= 299 {
                            let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                            if let notificationsDictArray = json! as? [Dictionary<String, Any>] {
                                completion(notificationsDictArray)
                                return
                            } else {    // if let endpointJSON error
                                print("[UapiCall] get JSON error")
                                completion([])
                                return
                            }
                        } else {    // if httpResponse.statusCode <200 or >299
                            print("[UapiCall] get response error: \(httpResponse.statusCode)")
                            completion([])
                            return
                        }
                        
                    }
                })
                task.resume()
                semaphore.wait()
            }   // theUapiQ.addOperation - end
        }
        
    }   // func get - end
    
    func token(serverUrl: String, creds: String, completion: @escaping (_ returnedToken: String) -> Void) {
        
        URLCache.shared.removeAllCachedResponses()
        
        var token          = ""
        
        var tokenUrlString = "\(serverUrl)/uapi/auth/tokens"
        tokenUrlString     = tokenUrlString.replacingOccurrences(of: "//uapi", with: "/uapi")
        
        let tokenUrl       = URL(string: "\(tokenUrlString)")
        let configuration  = URLSessionConfiguration.default
        var request        = URLRequest(url: tokenUrl!)
        request.httpMethod = "POST"
        
        configuration.httpAdditionalHeaders = ["Authorization" : "Basic \(creds)", "Content-Type" : "application/json", "Accept" : "application/json"]
        let session = Foundation.URLSession(configuration: configuration, delegate: self as URLSessionDelegate, delegateQueue: OperationQueue.main)
        let task = session.dataTask(with: request as URLRequest, completionHandler: {
            (data, response, error) -> Void in
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode >= 200 && httpResponse.statusCode <= 299 {
                    let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                    if let endpointJSON = json! as? Dictionary<String, Any> {
                        token = endpointJSON["token"] as! String
                        completion(token)
                        return
                    } else {    // if let endpointJSON error
                        print("JSON error")
                        completion("")
                        return
                    }
                } else {    // if httpResponse.statusCode <200 or >299
                    print("response error: \(httpResponse.statusCode)")
                    completion("")
                    return
                }
                
            }
        })
        task.resume()
        
    }   // func token - end
    
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping(  URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
        print("[UapiCall] allow self signed ceerts")
    }
    
}
