//
//  UapiCall.swift
//  jamfStatus
//
//  Created by Leslie Helou on 9/1/19.
//  Copyright © 2019 Leslie Helou. All rights reserved.
//

// get notifications from https://jamf.pro.server/uapi/notifications/alerts - old
// get notifications from https://jamf.pro.server/api/v1/notifications


import Foundation
import OSLog

class UapiCall: NSObject, URLSessionDelegate, URLSessionDataDelegate, URLSessionTaskDelegate {
    
    var theUapiQ = OperationQueue() // create operation queue for API calls
    
    func get(endpoint: String, completion: @escaping (_ notificationAlerts: [Dictionary<String,Any>]) -> Void) {
                
        Task {
            if await TokenManager.shared.tokenInfo?.renewToken ?? true || !JamfProServer.validToken {
                await TokenManager.shared.setToken(serverUrl: JamfProServer.url, username: JamfProServer.username.lowercased(), password: JamfProServer.password)
            }
            
            if await TokenManager.shared.tokenInfo?.authMessage ?? "" == "success" {
                
            URLCache.shared.removeAllCachedResponses()
            
            var workingUrlString = "\(JamfProServer.url)/api/\(endpoint)"
            workingUrlString     = workingUrlString.replacingOccurrences(of: "//api", with: "/api")
            
            self.theUapiQ.maxConcurrentOperationCount = 1
            
                self.theUapiQ.addOperation {
                    URLCache.shared.removeAllCachedResponses()
                    
                    let encodedURL = NSURL(string: workingUrlString)
                    let request = NSMutableURLRequest(url: encodedURL! as URL)
                    
                    let configuration  = URLSessionConfiguration.default
                    request.httpMethod = "GET"
                    
                    configuration.httpAdditionalHeaders = ["Authorization" : "Bearer \(JamfProServer.accessToken)", "Content-Type" : "application/json", "Accept" : "application/json", "User-Agent" : AppInfo.userAgentHeader]
                    
                    let session = Foundation.URLSession(configuration: configuration, delegate: self as URLSessionDelegate, delegateQueue: OperationQueue.main)
                    
                    let task = session.dataTask(with: request as URLRequest, completionHandler: {
                        (data, response, error) -> Void in
                        if let httpResponse = response as? HTTPURLResponse {
                            if httpResponse.statusCode >= 200 && httpResponse.statusCode <= 299 {
                                do {
                                    let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                                    if let notificationsDictArray = json as? [[String: Any]] {
                                        completion(notificationsDictArray)
                                        return
                                    } else {
                                        Logger.jpapi.info("An error creating notifications array")
                                        let dataString = String(data: data!, encoding: .utf8) ?? "No data"
                                        Logger.jpapi.info("returned data: \(dataString, privacy: .public)")
                                        completion([])
                                        return
                                    }
                                } catch {
                                    Logger.jpapi.info("An error parsing notification data occurred: \(error.localizedDescription, privacy: .public)")
                                }
                            } else {    // if httpResponse.statusCode <200 or >299
                                Logger.jpapi.debug("\(endpoint, privacy: .public) - get response error: \(httpResponse.statusCode, privacy: .public)")
                                if httpResponse.statusCode == 401 {
                                    JamfProServer.accessToken = ""
                                    JamfProServer.validToken = false
                                }
                                completion([])
                                return
                            }
                        } else {
                            Logger.jpapi.info("An error occurred: \(error!.localizedDescription, privacy: .public)")
                        }
                    })
                    task.resume()
                }
            }
        }
    }   // func get - end
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping(  URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
    
}

