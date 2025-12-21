// Endpoints.swift
// Falla - iOS 26 Fortune Telling App
// API endpoint definitions matching Flutter's api_endpoints.dart

import Foundation

// MARK: - Endpoint Protocol
/// Protocol defining an API endpoint
struct Endpoint {
    let path: String
    var queryItems: [URLQueryItem]?
    var headers: [String: String]?
    
    init(path: String, queryItems: [URLQueryItem]? = nil, headers: [String: String]? = nil) {
        self.path = path
        self.queryItems = queryItems
        self.headers = headers
    }
}

// MARK: - API Endpoints
/// All API endpoints matching Flutter's api_endpoints.dart
enum APIEndpoints {
    
    // MARK: - Authentication
    static let login = Endpoint(path: "/auth/login")
    static let register = Endpoint(path: "/auth/register")
    static let logout = Endpoint(path: "/auth/logout")
    static let resetPassword = Endpoint(path: "/auth/reset-password")
    static let verifyEmail = Endpoint(path: "/auth/verify-email")
    
    // MARK: - Fortune Reading
    static let fortuneReading = Endpoint(path: "/fortune/reading")
    static let tarotReading = Endpoint(path: "/fortune/tarot")
    static let palmReading = Endpoint(path: "/fortune/palm")
    static let astrologyReading = Endpoint(path: "/fortune/astrology")
    static let dreamInterpretation = Endpoint(path: "/fortune/dream")
    static let coffeeReading = Endpoint(path: "/fortune/coffee")
    
    static func fortune(type: String) -> Endpoint {
        switch type.lowercased() {
        case "tarot": return tarotReading
        case "palm": return palmReading
        case "astrology": return astrologyReading
        case "dream": return dreamInterpretation
        case "coffee": return coffeeReading
        default: return fortuneReading
        }
    }
    
    // MARK: - AI Integration (OpenAI)
    static let openAIChat = Endpoint(path: "/chat/completions")
    static let openAIImage = Endpoint(path: "/images/generations")
    static let openAIModeration = Endpoint(path: "/moderations")
    
    // MARK: - User Management
    static let userProfile = Endpoint(path: "/user/profile")
    static let updateProfile = Endpoint(path: "/user/update")
    static let userKarma = Endpoint(path: "/user/karma")
    static let userHistory = Endpoint(path: "/user/history")
    
    static func user(id: String) -> Endpoint {
        return Endpoint(path: "/user/profile/\(id)")
    }
    
    // MARK: - Aura Matching
    static let auraMatching = Endpoint(path: "/aura/matching")
    static let biorhythmAnalysis = Endpoint(path: "/aura/biorhythm")
    static let compatibilityCheck = Endpoint(path: "/aura/compatibility")
    static let dailyMatches = Endpoint(path: "/aura/daily-matches")
    
    // MARK: - Social Features
    static let socialFeed = Endpoint(path: "/social/feed")
    static let friendRequests = Endpoint(path: "/social/friend-requests")
    static let chatMessages = Endpoint(path: "/social/chat")
    static let sendMessage = Endpoint(path: "/social/send-message")
    static let blockUser = Endpoint(path: "/social/block")
    static let reportUser = Endpoint(path: "/social/report")
    
    static func chat(id: String) -> Endpoint {
        return Endpoint(path: "/social/chat/\(id)")
    }
    
    // MARK: - Mini Games
    static let wheelOfFortune = Endpoint(path: "/games/wheel")
    static let cardGames = Endpoint(path: "/games/cards")
    static let predictionGames = Endpoint(path: "/games/prediction")
    static let gameRewards = Endpoint(path: "/games/rewards")
    
    static func game(type: String) -> Endpoint {
        switch type.lowercased() {
        case "wheel": return wheelOfFortune
        case "cards": return cardGames
        case "prediction": return predictionGames
        default: return wheelOfFortune
        }
    }
    
    // MARK: - Admin Panel
    static let adminUsers = Endpoint(path: "/admin/users")
    static let adminAnalytics = Endpoint(path: "/admin/analytics")
    static let adminModeration = Endpoint(path: "/admin/moderation")
    static let adminSettings = Endpoint(path: "/admin/settings")
    static let adminReports = Endpoint(path: "/admin/reports")
    
    // MARK: - Payments
    static let premiumSubscription = Endpoint(path: "/payment/subscription")
    static let inAppPurchase = Endpoint(path: "/payment/purchase")
    static let paymentHistory = Endpoint(path: "/payment/history")
    static let refundRequest = Endpoint(path: "/payment/refund")
    
    // MARK: - Analytics
    static let userAnalytics = Endpoint(path: "/analytics/user")
    static let appAnalytics = Endpoint(path: "/analytics/app")
    static let revenueAnalytics = Endpoint(path: "/analytics/revenue")
    static let engagementAnalytics = Endpoint(path: "/analytics/engagement")
    
    // MARK: - Content
    static let tarotCards = Endpoint(path: "/content/tarot-cards")
    static let oracleCards = Endpoint(path: "/content/oracle-cards")
    static let zodiacSigns = Endpoint(path: "/content/zodiac-signs")
    static let dreamSymbols = Endpoint(path: "/content/dream-symbols")
    static let palmLines = Endpoint(path: "/content/palm-lines")
    
    // MARK: - Notifications
    static let sendNotification = Endpoint(path: "/notifications/send")
    static let notificationHistory = Endpoint(path: "/notifications/history")
    static let notificationSettings = Endpoint(path: "/notifications/settings")
    
    // MARK: - File Upload
    static let uploadImage = Endpoint(path: "/upload/image")
    static let uploadAudio = Endpoint(path: "/upload/audio")
    static let uploadVideo = Endpoint(path: "/upload/video")
    static let deleteFile = Endpoint(path: "/upload/delete")
    
    // MARK: - Utility
    static let healthCheck = Endpoint(path: "/health")
    static let versionCheck = Endpoint(path: "/version")
    static let maintenanceMode = Endpoint(path: "/maintenance")
    static let featureFlags = Endpoint(path: "/features")
}

// MARK: - External API URLs
enum ExternalAPIs {
    static let openAIBaseURL = "https://api.openai.com/v1"
    static let weatherAPI = "https://api.openweathermap.org/data/2.5/weather"
    static let horoscopeAPI = "https://api.horoscope.com/v1"
    static let numerologyAPI = "https://api.numerology.com/v1"
    static let chineseZodiacAPI = "https://api.chinese-zodiac.com/v1"
}

// MARK: - WebSocket URLs
enum WebSocketURLs {
    static let chat = "wss://api.falla.com/chat"
    static let realTimeUpdates = "wss://api.falla.com/updates"
    static let liveFortune = "wss://api.falla.com/live-fortune"
}
