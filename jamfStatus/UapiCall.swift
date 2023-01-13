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
    
    func get(endpoint: String, completion: @escaping (_ notificationAlerts: [Dictionary<String,Any>]) -> Void) {
        
        let jps = defaults.string(forKey:"jamfServerUrl") ?? ""
        
        JamfPro().getToken(serverUrl: jps, whichServer: "source", base64creds: JamfProServer.base64Creds) {
            (returnedToken: String) in
                        
            if returnedToken != "failed" {
                    
                URLCache.shared.removeAllCachedResponses()
                
                var workingUrlString = "\(jps)/api/\(endpoint)"
                workingUrlString     = workingUrlString.replacingOccurrences(of: "//api", with: "/api")
                
                self.theUapiQ.maxConcurrentOperationCount = 1
                
                self.theUapiQ.addOperation {
                    URLCache.shared.removeAllCachedResponses()
                    
                    let encodedURL = NSURL(string: workingUrlString)
                    let request = NSMutableURLRequest(url: encodedURL! as URL)
                    
                    let configuration  = URLSessionConfiguration.default
                    request.httpMethod = "GET"
                    
                    configuration.httpAdditionalHeaders = ["Authorization" : "\(JamfProServer.authType) \(JamfProServer.authCreds)", "Content-Type" : "application/json", "Accept" : "application/json", "User-Agent" : appInfo.userAgentHeader]

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
                        } else {
                            print("\n HTTP error \n")
                        }
                    })
                    task.resume()
                }   // theUapiQ.addOperation - end
            }
        }
    }   // func get - end
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping(  URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
    
}
