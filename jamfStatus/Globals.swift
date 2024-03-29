//
//  Globals.swift
//  jamfStatus
//
//  Created by Leslie Helou on 7/11/20.
//  Copyright © 2020 Leslie Helou. All rights reserved.
//

import Foundation

let httpSuccess     = 200...299
let refreshInterval: UInt32 = 25*60 // 25 minutes
var useApiClient    = 0

struct AppInfo {
    static let dict    = Bundle.main.infoDictionary!
    static let version = dict["CFBundleShortVersionString"] as! String
    static let build   = dict["CFBundleVersion"] as! String
    static let name    = dict["CFBundleExecutable"] as! String

    static let userAgentHeader = "\(String(describing: name.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!))/\(AppInfo.version)"
        
    static var bundlePath = Bundle.main.bundleURL
    static var iconFile   = bundlePath.appendingPathComponent("/Resources/AppIcon.icns")
}

struct JamfNotification {
    static let key = ["TOMCAT_SSL_CERT_EXPIRED":"CERT_EXPIRED",
                      "TOMCAT_SSL_CERT_WILL_EXPIRE":"CERT_WILL_EXPIRE",
                      "SSO_CERT_EXPIRED":"CERT_EXPIRED",
                      "SSO_CERT_WILL_EXPIRE":"CERT_WILL_EXPIRE",
                      "GSX_CERT_EXPIRED":"CERT_EXPIRED",
                      "GSX_CERT_WILL_EXPIRE":"CERT_WILL_EXPIRE",
                      "INVALID_REFERENCES_SCRIPTS":"INVALID_REFERENCES_SCRIPTS",
                      "INVALID_REFERENCES_EXT_ATTR":"INVALID_REFERENCES_EXT_ATTR",
                      "INVALID_REFERENCES_POLICIES":"INVALID_REFERENCES_POLICIES",
                      "POLICY_MANAGEMENT_ACCOUNT_PAYLOAD_SECURITY_MULTIPLE":"POLICY_MANAGEMENT_ACCOUNT_PAYLOAD_SECURITY_MULTIPLE",
                      "POLICY_MANAGEMENT_ACCOUNT_PAYLOAD_SECURITY_SINGLE":"POLICY_MANAGEMENT_ACCOUNT_PAYLOAD_SECURITY_SINGLE",
                      "USER_INITIATED_ENROLLMENT_MANAGEMENT_ACCOUNT_SECURITY_ISSUE":"USER_INITIATED_ENROLLMENT_MANAGEMENT_ACCOUNT_SECURITY_ISSUE",
                      "VPP_ACCOUNT_WILL_EXPIRE":"VPP_ACCOUNT_WILL_EXPIRE",
                      "VPP_ACCOUNT_EXPIRED":"VPP_ACCOUNT_EXPIRED",
                      "VPP_TOKEN_REVOKED":"VPP_TOKEN_REVOKED",
                      "DEP_INSTANCE_WILL_EXPIRE":"DEP_INSTANCE_WILL_EXPIRE",
                      "DEP_INSTANCE_EXPIRED":"DEP_INSTANCE_EXPIRED",
                      "PRESTAGE_IMAGING_SECURITY":"PRESTAGE_IMAGING_SECURITY",
                      "PUSH_PROXY_CERT_EXPIRED":"CERT_EXPIRED",
                      "PUSH_CERT_WILL_EXPIRE":"CERT_WILL_EXPIRE",
                      "PUSH_CERT_EXPIRED":"CERT_EXPIRED",
                      "FREQUENT_INVENTORY_COLLECTION_POLICY":"FREQUENT_INVENTORY_COLLECTION_POLICY",
                      "PATCH_UPDATE":"PATCH_MANAGEMENT_UPDATE_AVAILABLE_DESCRIPTION",
                      "PATCH_EXTENTION_ATTRIBUTE":"PATCH_EXTENSION_ATTRIBUTE_REQUIRES_ATTENTION_DESCRIPTION",
                      "DEVICE_ENROLLMENT_PROGRAM_T_C_NOT_SIGNED":"DEVICE_ENROLLMENT_PROGRAM_GLOBAL_NOTIFICATION_T_C_NOT_SIGNED_DESCRIPTION",
                      "APPLE_SCHOOL_MANAGER_T_C_NOT_SIGNED":"APPLE_SCHOOL_MANAGER_GLOBAL_NOTIFICATION_T_C_NOT_SIGNED_DESCRIPTION",
                      "NO_LONGER_DEVICE_ASSIGNABLE":"NO_LONGER_DEVICE_ASSIGNABLE_DESCRIPTION",
                      "HCL_ERROR":"HCL_ERROR_DESCRIPTION",
                      "HCL_BIND_ERROR":"HCL_BIND_ERROR_DESCRIPTION",
                      "COMPUTER_SECURITY_SSL_DISABLED":"COMPUTER_SECURITY_IS_CERTIFICATE_VALID_DESCRIPTION",
                      "JIM_ERROR":"JIM_ERROR_DESCRIPTION",
                      "EXCEEDED_LICENSE_COUNT":"EXCEEDED_LICENSE_COUNT_DESCRIPTION",
                      "MII_INVENTORY_UPLOAD_FAILED_NOTIFICATION":"MII_INVENTORY_FAILED_PROBLEM_DESCRIPTION",
                      "MII_HEARTBEAT_FAILED_NOTIFICATION":"MII_HEARTBEAT_FAILURE_PROBLEM_DESCRIPTION",
                      "MII_UNATHORIZED_RESPONSE_NOTIFICATION":"MII_UNAUTHORIZED_PROBLEM_DESCRIPTION",
                      "MDM_EXTERNAL_SIGNING_CERTIFICATE_EXPIRED":"MDM_EXTERNAL_SIGNING_CERTIFICATE_EXPIRED_DESCRIPTION",
                      "MDM_EXTERNAL_SIGNING_CERTIFICATE_EXPIRING":"MDM_EXTERNAL_SIGNING_CERTIFICATE_GOING_TO_EXPIRE_DESCRIPTION",
                      "MDM_EXTERNAL_SIGNING_CERTIFICATE_EXPIRING_TODAY":"MDM_EXTERNAL_SIGNING_CERTIFICATE_GOING_TO_EXPIRE_TODAY_DESCRIPTION",
                      "INSECURE_LDAP":"INSECURE_LDAP_DESCRIPTION",
                      "LDAP_CONNECTION_CHECK_THROUGH_JIM_SUCCESSFUL":"LDAP_CONNECTION_CHECK_THROUGH_JIM_SUCCESSFUL_DESCRIPTION",
                      "LDAP_CONNECTION_CHECK_THROUGH_JIM_FAILED":"LDAP_CONNECTION_CHECK_THROUGH_JIM_FAILED_DESCRIPTION",
                      "CLOUD_LDAP_CERT_EXPIRED":"CLOUD_LDAP_CERT_EXPIRED_DESCRIPTION",
                      "CLOUD_LDAP_CERT_WILL_EXPIRE":"CLOUD_LDAP_CERT_WILL_EXPIRE_DESCRIPTION",
                      "USER_MAID_MISMATCH_ERROR":"USER_MAID_MISMATCH_ERROR_DESCRIPTION",
                      "USER_MAID_DUPLICATE_ERROR":"USER_MAID_DUPLICATE_ERROR_DESCRIPTION",
                      "BUILT_IN_CA_EXPIRING":"BUILT_IN_CA_EXPIRING_DESCRIPTION",
                      "BUILT_IN_CA_EXPIRED":"BUILT_IN_CA_EXPIRED_DESCRIPTION",
                      "BUILT_IN_CA_RENEWAL_SUCCESS":"BUILT_IN_CA_RENEWAL_SUCCESS",
                      "BUILT_IN_CA_RENEWAL_FAILED":"BUILT_IN_CA_RENEWAL_FAILED",
                      "APNS_CERT_REVOKED":"APNS_CERT_REVOKED",
                      "APNS_CONNECTION_FAILURE":"APNS_CONNECTION_FAILURE",
                      "JAMF_PROTECT_UPDATE":"JAMF_PROTECT_UPDATE_AVAILABLE",
                      "JAMF_CONNECT_UPDATE":"JAMF_CONNECT_UPDATE_AVAILABLE",
                      "JAMF_CONNECT_MAJOR_UPDATE":"JAMF_CONNECT_MAJOR_UPDATE_AVAILABLE",
                      "DEVICE_COMPLIANCE_CONNECTION_ERROR":"DEVICE_COMPLIANCE_CONNECTION_ERROR_DESCRIPTION",
                      "CONDITIONAL_ACCESS_CONNECTION_ERROR":"CONDITIONAL_ACCESS_CONNECTION_ERROR_DESCRIPTION"]
    
    static let displayTitle = ["CERT_EXPIRED":"{{certType}} Certificate Expired",
                               "CLOUD_LDAP_CERT_EXPIRED_DESCRIPTION":"Cloud Identity Provider Certificate Expired",
                               "CERT_WILL_EXPIRE":"{{certType}} Certificate Expiring in {{days}} days",
                               "CLOUD_LDAP_CERT_WILL_EXPIRE_DESCRIPTION":"Cloud Identity Provider Certificate Expiring in {{validDays}} Days",
                               "INVALID_REFERENCES_SCRIPTS":"Scripts contain invalid references to /usr/sbin/jamf",
                               "INVALID_REFERENCES_EXT_ATTR":"Extension attributes contain invalid references to /usr/sbin/jamf",
                               "INVALID_REFERENCES_POLICIES":"Policies contain invalid references to /usr/sbin/jamf",
                               "POLICY_MANAGEMENT_ACCOUNT_PAYLOAD_SECURITY_MULTIPLE":"Multiple policies have a management account password configuration that is not recommended",
                               "POLICY_MANAGEMENT_ACCOUNT_PAYLOAD_SECURITY_SINGLE":"A policy has a management account password configuration that is not recommended",
                               "USER_INITIATED_ENROLLMENT_MANAGEMENT_ACCOUNT_SECURITY_ISSUE":"A configured management account feature is not recommended",
                               "VPP_ACCOUNT_WILL_EXPIRE":"Volume Purchasing Location {{name}} Expiring In {{days}} days",
                               "VPP_ACCOUNT_EXPIRED":"Volume Purchasing Location {{name}} Expired",
                               "VPP_TOKEN_REVOKED":"Volume Purchasing Server Token Revoked for the location {{name}}",
                               "DEP_INSTANCE_WILL_EXPIRE":"Automated Device Enrollment Instance {{name}} Expiring In {{days}} days",
                               "DEP_INSTANCE_EXPIRED":"Automated Device Enrollment Instance {{name}} Expired",
                               "PRESTAGE_IMAGING_SECURITY":"PreStage imaging and Autorun imaging requires a Jamf Pro user account with the \"Use PreStage Imaging and Autorun Imaging\" privilege.",
                               "FREQUENT_INVENTORY_COLLECTION_POLICY":"{{name}} updates inventory on all computers at recurring check-in. This may cause stability issues.",
                               "PATCH_MANAGEMENT_UPDATE_AVAILABLE_DESCRIPTION":"{{softwareTitleName}} v{{latestVersion}} is available",
                               "PATCH_EXTENSION_ATTRIBUTE_REQUIRES_ATTENTION_DESCRIPTION":"{{softwareTitleName}} has an extension attribute requiring attention",
                               "DEVICE_ENROLLMENT_PROGRAM_GLOBAL_NOTIFICATION_T_C_NOT_SIGNED_DESCRIPTION":"Device Enrollment instance out of date with Apple’s Terms and Conditions.",
                               "APPLE_SCHOOL_MANAGER_GLOBAL_NOTIFICATION_T_C_NOT_SIGNED_DESCRIPTION":"Sync failed. The associated Automated Device Enrollment instance is out of date with Apple’s Terms and Conditions. The updated agreement must be accepted to sync information. See your Apple School Manager instance to accept the updated agreement.",
                               "NO_LONGER_DEVICE_ASSIGNABLE_DESCRIPTION":"{{appName}} is no longer available for device-assigned managed distribution and any device assignments have been disabled for this app.",
                               "HCL_ERROR_DESCRIPTION":"There was an error configuring {{hclName}} Healthcare Listener on {{jsamName}}",
                               "HCL_BIND_ERROR_DESCRIPTION":"Port number of {{hclName}} Healthcare Listener is invalid on {{jsamName}}",
                               "COMPUTER_SECURITY_IS_CERTIFICATE_VALID_DESCRIPTION":"Verification of SSL certificates is disabled",
                               "JIM_ERROR_DESCRIPTION":"{{jsamName}} Infrastructure Manager instance has not checked in with Jamf Pro.",
                               "EXCEEDED_LICENSE_COUNT_DESCRIPTION":"Device Count Exceeded",
                               "MII_INVENTORY_FAILED_PROBLEM_DESCRIPTION":"Unable to send inventory information to Microsoft Intune",
                               "MII_HEARTBEAT_FAILURE_PROBLEM_DESCRIPTION":"Unable to connect to Microsoft Intune",
                               "MII_UNAUTHORIZED_PROBLEM_DESCRIPTION":"Integration disabled: \"Not Authorized\" response from Microsoft Intune",
                               "MDM_EXTERNAL_SIGNING_CERTIFICATE_EXPIRED_DESCRIPTION":"Third-Party Signing Certificate Expired",
                               "MDM_EXTERNAL_SIGNING_CERTIFICATE_GOING_TO_EXPIRE_DESCRIPTION":"Third-Party Signing Certificate Expiring in {{days}} Days",
                               "MDM_EXTERNAL_SIGNING_CERTIFICATE_GOING_TO_EXPIRE_TODAY_DESCRIPTION":"Third-Party Signing Certificate Expiring Today",
                               "INSECURE_LDAP_DESCRIPTION":"LDAP Server Configuration Error",
                               "LDAP_CONNECTION_CHECK_THROUGH_JIM_SUCCESSFUL_DESCRIPTION":"Verification status for the {{serverName}} LDAP Proxy Server Connection: Success",
                               "LDAP_CONNECTION_CHECK_THROUGH_JIM_FAILED_DESCRIPTION":"Verification Status for the {{serverName}} LDAP Proxy Server Connection: Failed",
                               "USER_MAID_MISMATCH_ERROR_DESCRIPTION":"{{userName}}'s Managed Apple ID does not match the Managed Apple ID reported in Apple School Manager.",
                               "USER_MAID_DUPLICATE_ERROR_DESCRIPTION":"The {{maid}} Managed Apple ID is used by multiple users.",
                               "BUILT_IN_CA_EXPIRING_DESCRIPTION":"The Jamf Pro JSS Built-in Certificate Authority is set to expire soon.",
                               "BUILT_IN_CA_EXPIRED_DESCRIPTION":"The Jamf Pro JSS Built-in Certificate Authority is expired.",
                               "BUILT_IN_CA_RENEWAL_SUCCESS":"The Jamf Pro JSS Built-in Certificate Authority has been successfully renewed.",
                               "BUILT_IN_CA_RENEWAL_FAILED":"The Jamf Pro JSS Built-in Certificate Authority renewal process failed.",
                               "APNS_CERT_REVOKED":"Unable to connect to APNs because the push certificate was revoked. Navigate to Global Management > Push Certificates </a> and renew the certificate or generate a new one.",
                               "APNS_CONNECTION_FAILURE":"Connection to the APN Service Failed. Could not connect to the APNs server. The server is down or network is unreachable.",
                               "JAMF_PROTECT_UPDATE_AVAILABLE":"Jamf Protect {{latestVersion}} Now Available",
                               "JAMF_CONNECT_UPDATE_AVAILABLE":"Jamf Connect {{latestVersion}} Now Available",
                               "JAMF_CONNECT_MAJOR_UPDATE_AVAILABLE":"Major Update for Jamf Connect Now Available (Jamf Connect {{latestVersion}})",
                               "DEVICE_COMPLIANCE_CONNECTION_ERROR_DESCRIPTION":"Device Compliance Connection Interrupted",
                               "CONDITIONAL_ACCESS_CONNECTION_ERROR_DESCRIPTION":"Conditional Access Connection Interrupted"]
    
    static let humanReadable = ["TOMCAT_SSL_CERT_EXPIRED":"Tomcat SSL",
                      "TOMCAT_SSL_CERT_WILL_EXPIRE":"Tomcat SSL",
                      "PUSH_PROXY_CERT_EXPIRED":"Push Proxy",
                      "PUSH_CERT_WILL_EXPIRE":"Push Notification",
                      "PUSH_CERT_EXPIRED":"Push Notification"]
}

struct JamfProServer {
    static var accessToken  = ""
    static var authCreds    = ""
    static var authExpires  = 30.0
    static var authType     = "Basic"
    static var base64Creds  = ""
    static var build        = ""
    static var currentCred  = ""
    static let maxThreads   = 2
    static var majorVersion = 0
    static var minorVersion = 0
    static var password     = ""
    static var patchVersion = 0
    static var tokenCreated = Date()
    static var url          = ""
    static var username     = ""
    static var validToken   = false
    static var version      = ""
}

struct Log {
    static var path: String? = (NSHomeDirectory() + "/Library/Logs/jamfStatus/")
    static var file     = "jamfStatus.log"
    static var maxFiles = 10
    static var maxSize  = 500000 // 5MB
}

struct Preferences {
    static var hideMenubarIcon: Bool?       = false
    static var hideUntilStatusChange: Bool? = true
    static var launchAgent: Bool?           = false
    static var pollingInterval: Int?        = 300
    static var baseUrl: String?             = "https://status.jamf.com"
    static var jamfServerUrl                = ""
    static var username                     = ""
    static var password                     = ""
    static var menuIconStyle                = "color"
}


struct token {
    static var refreshInterval:UInt32 = 10*60  // 10 minutes
    static var sourceServer  = ""
    static var sourceExpires = ""
    static var startTime     = Date()
    static var isValid       = false
}

public func timeDiff(startTime: Date) -> (Int, Int, Int, Double) {
    let endTime = Date()
//                    let components = Calendar.current.dateComponents([.second, .nanosecond], from: startTime, to: endTime)
//                    let timeDifference = Double(components.second!) + Double(components.nanosecond!)/1000000000
//                    WriteToLog().message(stringOfText: "[ViewController.download] time difference: \(timeDifference) seconds")
    let components = Calendar.current.dateComponents([
        .hour, .minute, .second, .nanosecond], from: startTime, to: endTime)
    var diffInSeconds = Double(components.hour!)*3600 + Double(components.minute!)*60 + Double(components.second!) + Double(components.nanosecond!)/1000000000
    diffInSeconds = Double(round(diffInSeconds * 1000) / 1000)
//    let timeDifference = Int(components.second!) //+ Double(components.nanosecond!)/1000000000
//    let (h,r) = timeDifference.quotientAndRemainder(dividingBy: 3600)
//    let (m,s) = r.quotientAndRemainder(dividingBy: 60)
//    WriteToLog().message(stringOfText: "[ViewController.download] download time: \(h):\(m):\(s) (h:m:s)")
    return (Int(components.hour!), Int(components.minute!), Int(components.second!), diffInSeconds)
//    return (h, m, s)
}

extension String {
    var fqdnFromUrl: String {
        get {
            var fqdn = ""
            let nameArray = self.components(separatedBy: "/")
            if nameArray.count > 2 {
                fqdn = nameArray[2]
            } else {
                fqdn =  self
            }
            if fqdn.contains(":") {
                let fqdnArray = fqdn.components(separatedBy: ":")
                fqdn = fqdnArray[0]
            }
            let urlRegex = try! NSRegularExpression(pattern: "/?failover(.*?)", options:.caseInsensitive)
            fqdn = urlRegex.stringByReplacingMatches(in: fqdn, options: [], range: NSRange(0..<fqdn.utf16.count), withTemplate: "")
            return fqdn
        }
    }
}
