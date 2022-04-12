//
//  JamfPro.swift
//  jamfStatus
//
//  Created by Leslie Helou on 12/11/19.
//  Copyright © 2019 Leslie Helou. All rights reserved.
//

import Foundation

class JamfPro: NSObject, URLSessionDelegate {
    
    var renewQ = DispatchQueue(label: "com.jamfstatus.token_refreshQ", qos: DispatchQoS.utility)   // running background process for refreshing token
    let defaults = UserDefaults.standard
    
    func jsonAction(theServer: String, theEndpoint: String, theMethod: String, theArray: [Int], retryCount: Int, completion: @escaping (_ result: [String:Any]) -> Void) {

        let getRecordQ = OperationQueue() // DispatchQueue(label: "com.jamfie.getRecordQ", qos: DispatchQoS.background)
    
        URLCache.shared.removeAllCachedResponses()
        var existingDestUrl = ""
        
        switch theEndpoint {
        case "computer-prestages":
            existingDestUrl = "\(theServer)/api/v2/\(theEndpoint)"
            existingDestUrl = existingDestUrl.replacingOccurrences(of: "//api/v2", with: "/api/v2")
        default:
            existingDestUrl = "\(theServer)/JSSResource/\(theEndpoint)"
            existingDestUrl = existingDestUrl.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
        }
        
        WriteToLog().message(stringOfText: ["\(theMethod) - existing endpoint URL: \(existingDestUrl)"])
        let destEncodedURL = URL(string: existingDestUrl)
        let jsonRequest    = NSMutableURLRequest(url: destEncodedURL! as URL)
        
        let semaphore = DispatchSemaphore(value: 0)
        getRecordQ.maxConcurrentOperationCount = 2
        getRecordQ.addOperation {
            
            jsonRequest.httpMethod = theMethod
            let destConf = URLSessionConfiguration.default
            destConf.httpAdditionalHeaders = ["Authorization" : "\(JamfProServer.authType) \(JamfProServer.authCreds)", "Content-Type" : "application/json", "Accept" : "application/json", "User-Agent" : appInfo.userAgentHeader]
            
            let destSession = Foundation.URLSession(configuration: destConf, delegate: self, delegateQueue: OperationQueue.main)
            let task = destSession.dataTask(with: jsonRequest as URLRequest, completionHandler: {
                (data, response, error) -> Void in
                destSession.finishTasksAndInvalidate()
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode >= 200 && httpResponse.statusCode <= 299 {
                        do {
                            let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                            if let endpointJSON = json as? [String:AnyObject] {
                                completion(endpointJSON)
                            } else {
                                completion([:])
                            }
                        }
                    } else {
                        WriteToLog().message(stringOfText: ["error during GET, HTTP Status Code: \(httpResponse.statusCode)"])
                        if "\(httpResponse.statusCode)" == "401" && retryCount < 1 {
                            if JamfProServer.authType == "Bearer" {
                                WriteToLog().message(stringOfText: ["authentication failed.  Trying to gneerate a new token"])
                                self.getToken(serverUrl: Preferences.jamfServerUrl, whichServer: "source", base64creds: JamfProServer.base64Creds) {
                                    (result: String) in
                                    if result != "failed" {
                                        self.jsonAction(theServer: theServer, theEndpoint: theEndpoint, theMethod: theMethod, theArray: theArray, retryCount: retryCount+1) {
                                        (result: [String:Any]) in
                                            completion(result)
                                        }
                                    } else {
                                        WriteToLog().message(stringOfText: ["authentication failed"])
                                        completion(["Message":"Failed to authenticate" as Any])
                                    }
                                }
                            } else {
                                completion(["Message":"Failed to authenticate" as Any])
                            }
                        } else if httpResponse.statusCode > 499 && retryCount < 1 {
                            sleep(5)
                            WriteToLog().message(stringOfText: ["Retry \(existingDestUrl)"])
                            self.jsonAction(theServer: theServer, theEndpoint: theEndpoint, theMethod: theMethod, theArray: theArray, retryCount: retryCount+1) {
                                (result: [String:Any]) in
                                completion(result)
                            }
                        } else {
                            completion([:])
                        }
                    }
                } else {
                    WriteToLog().message(stringOfText: ["error parsing JSON for \(existingDestUrl)"])
                    WriteToLog().message(stringOfText: ["error: \(String(describing: error))"])
                    completion([:])
                }   // if let httpResponse - end
                semaphore.signal()
                if error != nil {
                }
            })  // let task = destSession - end
            //print("GET")
            task.resume()
            semaphore.wait()
        }   // getRecordQ - end
    }
    
    func xmlAction(theServer: String, theEndpoint: String, theMethod: String, theData: String, completion: @escaping (_ result: [Int:String]) -> Void) {

        let getRecordQ = OperationQueue() // DispatchQueue(label: "com.jamfie.getRecordQ", qos: DispatchQoS.background)
    
        URLCache.shared.removeAllCachedResponses()
        var existingDestUrl = ""
        
        existingDestUrl = "\(theServer)/JSSResource/\(theEndpoint)"
        existingDestUrl = existingDestUrl.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
        
        WriteToLog().message(stringOfText: ["\(theMethod) - existing endpoint URL: \(existingDestUrl)"])
        let destEncodedURL = URL(string: existingDestUrl)
        let xmlRequest    = NSMutableURLRequest(url: destEncodedURL! as URL)
        
        let semaphore = DispatchSemaphore(value: 0)
        getRecordQ.maxConcurrentOperationCount = JamfProServer.maxThreads
        getRecordQ.addOperation {
            
            xmlRequest.httpMethod = theMethod
            let destConf = URLSessionConfiguration.default
            destConf.httpAdditionalHeaders = ["Authorization" : "\(JamfProServer.authType) \(JamfProServer.authCreds)", "Content-Type" : "application/xml", "Accept" : "application/xml", "User-Agent" : appInfo.userAgentHeader]
            if theMethod == "POST" || theMethod == "PUT" {
                let encodedXML = theData.data(using: String.Encoding.utf8)
                xmlRequest.httpBody = encodedXML!
            }
            
            let destSession = Foundation.URLSession(configuration: destConf, delegate: self, delegateQueue: OperationQueue.main)
            let task = destSession.dataTask(with: xmlRequest as URLRequest, completionHandler: {
                (data, response, error) -> Void in
                destSession.finishTasksAndInvalidate()
                if let httpResponse = response as? HTTPURLResponse {
//                    print("[JamfPro.xmlAction] httpResponse: \(String(describing: httpResponse))")
                    if httpResponse.statusCode >= 200 && httpResponse.statusCode <= 299 {
                        
                        completion([httpResponse.statusCode:"success"])
                        
                    } else {
                        WriteToLog().message(stringOfText: ["error during \(theMethod), HTTP Status Code: \(httpResponse.statusCode)"])
                        if "\(httpResponse.statusCode)" == "401" {
//                            Alert().display(header: "Alert", message: "Verify username and password.")
                            WriteToLog().message(stringOfText: ["authentication failure"])
                        }
                        if httpResponse.statusCode > 500 {
                            WriteToLog().message(stringOfText: ["momentary pause"])
                            sleep(2)
                            WriteToLog().message(stringOfText: ["back to work"])
                        }

                        completion([httpResponse.statusCode:"failed"])
                    }
                } else {

                    completion([0:""])
                }   // if let httpResponse - end
                semaphore.signal()
                if error != nil {
                }
            })  // let task = destSession - end
            //print("GET")
            task.resume()
            semaphore.wait()
        }   // getRecordQ - end
    }
    
    func getVersion(jpURL: String, base64Creds: String, completion: @escaping (_ jpversion: String) -> Void) {
        var versionString  = ""
        let semaphore      = DispatchSemaphore(value: 0)
        
        WriteToLog().message(stringOfText: ["Attempting to retrieve Jamf Pro version from \(jpURL)"])
        OperationQueue().addOperation {
//            print("jpURL: \(jpURL)")
            let encodedURL     = NSURL(string: "\(jpURL)/JSSCheckConnection")
            let request        = NSMutableURLRequest(url: encodedURL! as URL)
            request.httpMethod = "GET"
            let configuration  = URLSessionConfiguration.default
            let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
            let task = session.dataTask(with: request as URLRequest, completionHandler: { [self]
                (data, response, error) -> Void in
                if let httpResponse = response as? HTTPURLResponse {
//                    print("httpResponse: \(httpResponse)")
                    versionString = String(data: data!, encoding: .utf8) ?? ""
//                    print("httpResponse: \(httpResponse)")
//                    print("raw versionString: \(versionString)")
                    if versionString != "" {
                        let tmpArray = versionString.components(separatedBy: ".")
                        if tmpArray.count > 2 {
                            for i in 0...2 {
                                switch i {
                                case 0:
                                    JamfProServer.majorVersion = Int(tmpArray[i]) ?? 0
                                case 1:
                                    JamfProServer.minorVersion = Int(tmpArray[i]) ?? 0
                                case 2:
                                    let tmp = tmpArray[i].components(separatedBy: "-")
                                    JamfProServer.patchVersion = Int(tmp[0]) ?? 0
                                    if tmp.count > 1 {
                                        JamfProServer.build = tmp[1]
                                    }
                                default:
                                    break
                                }
                            }
                        }
                    }
                } else {
//                    Alert().display(header: "Attention", message: """
//                    Did not get a response from \(jpURL)
//                    Verify the server URL
//                    """)
                    WriteToLog().message(stringOfText: ["unable to connect to \(jpURL)"])
                    completion("failed")
                    return
                }
                WriteToLog().message(stringOfText: ["Jamf Pro Version: \(versionString)"])
                JamfProServer.base64Creds = base64Creds
                Preferences.jamfServerUrl = jpURL
                if ( JamfProServer.majorVersion > 9 && JamfProServer.minorVersion > 34 ) {
                    JamfProServer.authType  = "Bearer"
                    getToken(serverUrl: jpURL, whichServer: "source", base64creds: JamfProServer.base64Creds) {
                        (result: String) in
                        if result == "failed" {
                            JamfProServer.authType = "Basic"
                        }
                        completion("\(result)")
                    }
                } else {
                    JamfProServer.authType  = "Basic"
                    JamfProServer.authCreds = base64Creds
                    completion("success")
                }
            })  // let task = session - end
            task.resume()
            semaphore.wait()
        }
    }
    
    func getToken(serverUrl: String, whichServer: String, base64creds: String, completion: @escaping (_ result: String) -> Void) {
        
//        print("\(serverUrl.prefix(4))")
        if serverUrl.prefix(4) != "http" {
            completion("skipped")
            return
        }
        URLCache.shared.removeAllCachedResponses()
                
        var tokenUrlString = "\(serverUrl)/api/v1/auth/token"
        tokenUrlString     = tokenUrlString.replacingOccurrences(of: "//api", with: "/api")
    //        print("\(tokenUrlString)")
        
        let tokenUrl       = URL(string: "\(tokenUrlString)")
        let configuration  = URLSessionConfiguration.ephemeral
        var request        = URLRequest(url: tokenUrl!)
        request.httpMethod = "POST"
        
        WriteToLog().message(stringOfText: ["Attempting to retrieve token from \(String(describing: tokenUrl!))"])
        
        configuration.httpAdditionalHeaders = ["Authorization" : "Basic \(base64creds)", "Content-Type" : "application/json", "Accept" : "application/json"]
        let session = Foundation.URLSession(configuration: configuration, delegate: self as URLSessionDelegate, delegateQueue: OperationQueue.main)
        let task = session.dataTask(with: request as URLRequest, completionHandler: {
            (data, response, error) -> Void in
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode >= 200 && httpResponse.statusCode <= 299 {
                    let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                    if let endpointJSON = json! as? [String: Any], let _ = endpointJSON["token"], let _ = endpointJSON["expires"] {
                        JamfProServer.authCreds = endpointJSON["token"] as! String
                        token.sourceExpires  = "\(endpointJSON["expires"] ?? "")"
                        
//                      print("[JamfPro] result of token request: \(endpointJSON)")
//                      print("[JamfPro] Bearer type: \(JamfProServer.authType)")
                        WriteToLog().message(stringOfText: ["New token created"])
                        if JamfProServer.authType == "Bearer" {
                            WriteToLog().message(stringOfText: ["Call token refresh"])
                            self.refresh(server: serverUrl, whichServer: whichServer, b64Creds: base64creds, interval: token.refreshInterval)
                        }
                        completion("success")
                        return
                    } else {    // if let endpointJSON error
                        WriteToLog().message(stringOfText: ["JSON error.\n\(String(describing: json))"])
                        self.refresh(server: serverUrl, whichServer: whichServer, b64Creds: base64creds, interval: 60)
                        completion("failed")
                        return
                    }
                } else {    // if httpResponse.statusCode <200 or >299
                    WriteToLog().message(stringOfText: ["response error: \(httpResponse.statusCode)"])
                    self.refresh(server: serverUrl, whichServer: whichServer, b64Creds: base64creds, interval: 60)
                    completion("failed")
                    return
                }
            } else {
                WriteToLog().message(stringOfText: ["token response error.  Verify url and port"])
                self.refresh(server: serverUrl, whichServer: whichServer, b64Creds: base64creds, interval: 60)
                completion("failed")
                return
            }
        })
        task.resume()
    }
    
    func refresh(server: String, whichServer: String, b64Creds: String, interval: UInt32) {
        renewQ.async { [self] in
//        sleep(1200) // 20 minutes
            sleep(interval)
            getToken(serverUrl: server, whichServer: whichServer, base64creds: b64Creds) {
                (result: String) in
//                print("[JamfPro.refresh] returned: \(result)")
            }
        }
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping(  URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
    
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        // this catches errors
        if let err = error {
//            print("Error localizedDescription: \(err.localizedDescription)")
//            print("Error debugDescription: \(error.debugDescription)")
            WriteToLog().message(stringOfText: ["connection error: \(err.localizedDescription)"])
//            print("URLSessionTask description: \(String(describing: failedPackage!))")
//            Parameters.failedUploads.append("\(String(describing: failedPackage!))")
        } //else {
//            print("Error. Giving up")
//        }
    }
}

private func tagValue(xmlString:String, startTag:String, endTag:String, includeTags: Bool) -> String {
    var rawValue = ""
    if let start = xmlString.range(of: startTag),
        let end  = xmlString.range(of: endTag, range: start.upperBound..<xmlString.endIndex) {
        rawValue.append(String(xmlString[start.upperBound..<end.lowerBound]))
    }
    if includeTags {
        return "\(startTag)\(rawValue)\(endTag)"
    } else {
        return rawValue
    }
}
