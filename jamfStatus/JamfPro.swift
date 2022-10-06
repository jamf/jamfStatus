//
//  JamfPro.swift
//  jamfStatus
//
//  Created by Leslie Helou on 12/11/19.
//  Copyright © 2019 Leslie Helou. All rights reserved.
//

import Foundation

class JamfPro: NSObject, URLSessionDelegate {
    
    var renewQ2  = OperationQueue()
    var renewQ   = DispatchQueue(label: "com.jamfstatus.token_refreshQ", qos: DispatchQoS.utility)   // running background process for refreshing token
    let defaults = UserDefaults.standard
    
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
        
        let components = Calendar.current.dateComponents([.minute], from: token.startTime, to: Date())
        let timeDifference = Int(components.minute!)
        if !token.isValid || (timeDifference > 20) {
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
    //        var decodedString = ""
    //        if let decodedData = Data(base64Encoded: base64creds) {
    //            decodedString = String(data: decodedData, encoding: .utf8)!
    //        }
    //        print("base64creds: \(decodedString)")
            
            configuration.httpAdditionalHeaders = ["Authorization" : "Basic \(base64creds)", "Content-Type" : "application/json", "Accept" : "application/json", "User-Agent" : appInfo.userAgentHeader]
            let session = Foundation.URLSession(configuration: configuration, delegate: self as URLSessionDelegate, delegateQueue: OperationQueue.main)
            let task = session.dataTask(with: request as URLRequest, completionHandler: {
                (data, response, error) -> Void in
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode >= 200 && httpResponse.statusCode <= 299 {
                        let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                        if let endpointJSON = json! as? [String: Any], let _ = endpointJSON["token"], let _ = endpointJSON["expires"] {
                            JamfProServer.authCreds = endpointJSON["token"] as! String
                            token.sourceExpires     = "\(endpointJSON["expires"] ?? "")"
                            token.startTime         = Date()
                            token.isValid           = true
                            
    //                      print("[JamfPro] result of token request: \(endpointJSON)")
    //                      print("[JamfPro] Bearer type: \(JamfProServer.authType)")
                            WriteToLog().message(stringOfText: ["New token created"])
                            completion("success")
                            return
                        } else {    // if let endpointJSON error
                            WriteToLog().message(stringOfText: ["JSON error.\n\(String(describing: json))"])
                            token.isValid = false
                            completion("failed")
                            return
                        }
                    } else {    // if httpResponse.statusCode <200 or >299
                        WriteToLog().message(stringOfText: ["response error: \(httpResponse.statusCode)"])
                        token.isValid = false
                        completion("failed")
                        return
                    }
                } else {
                    WriteToLog().message(stringOfText: ["token response error.  Verify url and port"])
                    token.isValid = false
                    completion("failed")
                    return
                }
            })
            task.resume()
        } else {
//            WriteToLog().message(stringOfText: ["existing token is \(timeDifference) minutes old, use existing"])
            completion("use existing token")
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
