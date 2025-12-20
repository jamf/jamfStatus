//
//  Token.swift
//  Wallpaper
//
//  Created by leslie on 7/2/25.
//

//import Cocoa
import Foundation
//import OSLog


final class TokenInfo: Encodable, @unchecked Sendable {

    var id: UUID?

    var url: String
    var token: String
    var expiresAt: Date
    
    var authMessage: String
    
    init(id: UUID? = nil, url: String, token: String, expiresAt: Date, authMessage: String) {
        self.id = id
        self.url = url
        self.token = token
        self.expiresAt = expiresAt
        self.authMessage = authMessage
    }
    
    var renewToken: Bool {
        expiresAt >= Date().addingTimeInterval(-30)
    }
}

// MARK: - Token Response Types
enum TokenResponse: Codable {
    case tokenData(TokenData)
    case accessTokenData(AccessTokenData)

    enum CodingKeys: String, CodingKey {
        case expires, token
        case expiresIn = "expires_in"
        case tokenType = "token_type"
        case accessToken = "access_token"
        case scope
    }

    // Custom Decoding
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if container.contains(.expires) {
            let data = try TokenData(from: decoder)
            self = .tokenData(data)
        } else if container.contains(.expiresIn) {
            let data = try AccessTokenData(from: decoder)
            self = .accessTokenData(data)
        } else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "Unknown token format")
            )
        }
    }

    // Custom Encoding
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .tokenData(let data):
            try container.encode(data.expires, forKey: .expires)
            try container.encode(data.token, forKey: .token)
        case .accessTokenData(let data):
            try container.encode(data.expiresIn, forKey: .expiresIn)
            try container.encode(data.tokenType, forKey: .tokenType)
            try container.encode(data.accessToken, forKey: .accessToken)
            try container.encodeIfPresent(data.scope, forKey: .scope)
        }
    }
}

// MARK: - First JSON Format
struct TokenData: Codable {
    let expires: Date
    let token: String

    enum CodingKeys: String, CodingKey {
        case expires
        case token
    }
}

// MARK: - Second JSON Format
struct AccessTokenData: Codable {
    let expiresIn: Double
    let tokenType: String
    let accessToken: String
    let scope: String?

    enum CodingKeys: String, CodingKey {
        case expiresIn = "expires_in"
        case tokenType = "token_type"
        case accessToken = "access_token"
        case scope
    }
}

func timeDiff(startTime: Date, renewalInterval: Bool = false) -> (Int, Int, Int, Double) {
    let start = renewalInterval ? startTime : Date()
    let end = renewalInterval ?  Date() : startTime
    if start == end { return (0, 0, 0, 0) }
    let components = Calendar.current.dateComponents([
        .hour, .minute, .second, .nanosecond], from: start, to: end)
    var diffInSeconds = Double(components.hour!)*3600 + Double(components.minute!)*60 + Double(components.second!) + Double(components.nanosecond!)/1000000000
    diffInSeconds = Double(round(diffInSeconds * 100) / 100)
    return (Int(components.hour!), Int(components.minute!), Int(components.second!), diffInSeconds)
}

// MARK: - Custom Date Formatter for ISO 8601 Strings
extension DateFormatter {
    static let customISO8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}
