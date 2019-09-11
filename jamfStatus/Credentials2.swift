//
//  Credentials2.swift
//  jamfStatus
//
//  Created by Leslie Helou on 9/11/19.
//  Copyright © 2019 Leslie Helou. All rights reserved.
//

import Foundation
import Security

let kSecValueDataString            = NSString(format: kSecValueData)
let kSecClassGenericPasswordString = NSString(format: kSecClassGenericPassword)

class Credentials2 {
    
    func save(service: String, account: String, data: String) {
        
        if let password = data.data(using: String.Encoding.utf8) {
            let keychainQuery: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                                kSecAttrService as String: service,
                                                kSecAttrAccount as String: account,
                                                kSecValueData as String: password]
            
            // try to add new credentials, if account exists we'll try updating it
            let addStatus = SecItemAdd(keychainQuery as CFDictionary, nil)
            if (addStatus != errSecSuccess) {
                if let addErr = SecCopyErrorMessageString(addStatus, nil) {
                    print("[addStatus] Write failed: \(addErr)")
                    
                    // try to update an existing account password
                    let updateStatus = SecItemUpdate(keychainQuery as CFDictionary, [kSecValueDataString:password] as CFDictionary)
                    print("status: \(updateStatus)")
                    print("errSecSuccess: \(errSecSuccess)")
                    
                    if (updateStatus != errSecSuccess) {
                        if let updateErr = SecCopyErrorMessageString(updateStatus, nil) {
                            print("[updateStatus] Read failed: \(updateErr)")
                        }
                    }
                }   // if let addErr - end
            }   // if (addStatus != errSecSuccess) - end
            
        }
    }   // func save - end
    
    func retrieve(service: String) -> [String] {
        
        var storedCreds = [String]()
        
        let keychainQuery: [String: Any] = [kSecClass as String: kSecClassGenericPasswordString,
                                            kSecAttrService as String: service,
                                            kSecMatchLimit as String: kSecMatchLimitOne,
                                            kSecReturnAttributes as String: true,
                                            kSecReturnData as String: true]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(keychainQuery as CFDictionary, &item)
        guard status != errSecItemNotFound else { return [] }
        guard status == errSecSuccess else { return [] }
        
        guard let existingItem = item as? [String : Any],
            let passwordData = existingItem[kSecValueData as String] as? Data,
            let account = existingItem[kSecAttrAccount as String] as? String,
            let password = String(data: passwordData, encoding: String.Encoding.utf8)
            else {
                return []
        }
        storedCreds.append(account)
        storedCreds.append(password)
        return storedCreds
    }
    
}
