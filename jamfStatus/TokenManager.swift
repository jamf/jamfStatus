//
//  TokenManager.swift
//  Wallpaper
//
//  Created by leslie on 7/9/25.
//

import Foundation

actor TokenManager {
    static let shared = TokenManager()
    
    @MainActor private(set) var tokenInfo: TokenInfo?
    
    func getToken() async -> TokenInfo? {
        await MainActor.run { tokenInfo }
    }

    func setToken(serverUrl: String, username: String, password: String) async {
        
        let newTokenInfo: TokenInfo
        
        let tokenUrlString = (useApiClient == 0) ? "\(serverUrl)/api/v1/auth/token" : "\(serverUrl)/api/oauth/token"
        
        guard let tokenUrl = URL(string: tokenUrlString) else {
            WriteToLog.shared.message("Invalid URL: \(tokenUrlString)")
            newTokenInfo = TokenInfo(url: serverUrl, token: "", expiresAt: Date(), authMessage: "Invalid URL: \(tokenUrlString)")
            await MainActor.run {
                self.tokenInfo = newTokenInfo
            }
            return
        }

        var request = URLRequest(url: tokenUrl)
        request.httpMethod = "POST"

        if useApiClient == 0 {
            let base64creds = Data("\(username):\(password)".utf8).base64EncodedString()
            request.setValue("Basic \(base64creds)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        } else {
            let clientString = "grant_type=client_credentials&client_id=\(username)&client_secret=\(password)"
            let requestData = clientString.data(using: .utf8)
            request.httpBody = requestData
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        }
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(AppInfo.userAgentHeader, forHTTPHeaderField: "User-Agent")
        
        var authMessage = ""

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                print("[setToken] Failed to authenticate, \(serverUrl). Status code: \(statusCode)")
                switch statusCode {
                case 401:
                    authMessage = "\(401): Incorrect credentials"
                case 404:
                    authMessage = "\(404): Server not found"
                default:
                    let code = statusCode == -1 ? "Unknown error" : "\(statusCode)"
                    authMessage = "\(code): login failed"
                }
                print("[setToken] authMessage: \(authMessage)")
                newTokenInfo = TokenInfo(url: serverUrl, token: "", expiresAt: Date(), authMessage: authMessage)
                await MainActor.run {
                    self.tokenInfo = newTokenInfo
                }
                return
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(DateFormatter.customISO8601)

            let tokenResponse = try decoder.decode(TokenResponse.self, from: data)

            switch tokenResponse {
            case .tokenData(let data):
                let token = data.token
                let expiration: Date

                if let date = data.expires as? Date {
                    let renewIn = timeDiff(startTime: date)
                    expiration = Date.now + renewIn.3
                } else {
                    expiration = Date.now + 20 * 60
                }

                newTokenInfo = TokenInfo(url: serverUrl,
                                         token: token,
                                         expiresAt: expiration,
                                         authMessage: "success")

            case .accessTokenData(let data):
                newTokenInfo = TokenInfo(
                    url: serverUrl,
                    token: data.accessToken,
                    expiresAt: Date.now + data.expiresIn,
                    authMessage: "success"
                )
            }

            JamfProServer.accessToken = newTokenInfo.token
            
            await MainActor.run {
                self.tokenInfo = newTokenInfo
            }

        } catch {
            print("Token request failed: \(error.localizedDescription)")
            newTokenInfo = TokenInfo(url: serverUrl, token: "", expiresAt: Date(), authMessage: error.localizedDescription)
            await MainActor.run {
                self.tokenInfo = newTokenInfo
            }
        }
    }
}

