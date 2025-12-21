// IPService.swift
// Falla - iOS 26 Fortune Telling App
// IP address service for account creation validation

import Foundation

// MARK: - IP Service
/// Service for retrieving and managing IP addresses
actor IPService {
    // MARK: - Singleton
    static let shared = IPService()
    
    // MARK: - Configuration
    private let ipifyURL = URL(string: "https://api.ipify.org?format=json")!
    private let session: URLSession
    
    // MARK: - Cached IP
    private var cachedIP: String?
    private var lastFetchTime: Date?
    private let cacheTimeout: TimeInterval = 300 // 5 minutes
    
    // MARK: - Initialization
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10
        self.session = URLSession(configuration: configuration)
    }
    
    // MARK: - Public Methods
    
    /// Get public IP address
    /// - Returns: Public IP address string or nil if unable to fetch
    func getPublicIP() async -> String? {
        // Return cached IP if still valid
        if let cachedIP = cachedIP,
           let lastFetchTime = lastFetchTime,
           Date().timeIntervalSince(lastFetchTime) < cacheTimeout {
            return cachedIP
        }
        
        do {
            let (data, response) = try await session.data(from: ipifyURL)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("⚠️ IP fetch failed: Invalid response")
                return nil
            }
            
            let result = try JSONDecoder().decode(IPifyResponse.self, from: data)
            cachedIP = result.ip
            lastFetchTime = Date()
            
            return result.ip
        } catch {
            print("⚠️ Could not retrieve IP address: \(error)")
            return nil
        }
    }
    
    /// Clear cached IP
    func clearCache() {
        cachedIP = nil
        lastFetchTime = nil
    }
}

// MARK: - IPify Response
private struct IPifyResponse: Decodable {
    let ip: String
}
