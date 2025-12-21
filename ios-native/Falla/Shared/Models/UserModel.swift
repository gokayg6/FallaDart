// UserModel.swift
// Falla - iOS 26 Fortune Telling App
// User data model matching Flutter's user_model.dart

import Foundation

// MARK: - User Model
/// Core user model with all profile and preference data
struct UserModel: Codable, Identifiable, Equatable {
    // MARK: - Identity
    let id: String
    var name: String
    var email: String
    
    // MARK: - Profile Information
    var birthDate: Date?
    var gender: String?
    var relationshipStatus: String?
    var job: String?
    var birthPlace: String?
    var avatarURL: String?
    
    // MARK: - Derived Properties
    var age: Int?
    var ageGroup: String?
    var zodiacSign: String?
    
    // MARK: - Economy
    var karma: Int
    var isPremium: Bool
    
    // MARK: - Timestamps
    var createdAt: Date
    var lastLoginAt: Date
    
    // MARK: - Usage Stats
    var dailyFortunesUsed: Int
    var favoriteFortuneTypes: [String]
    var totalFortunes: Int
    var totalTests: Int
    
    // MARK: - Social
    var socialVisible: Bool
    var blockedUsers: [String]
    var freeAuraMatches: Int
    var lastWeeklyAuraMatchReset: Date?
    
    // MARK: - Preferences
    var preferences: UserPreferences
    
    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id, name, email
        case birthDate, gender, relationshipStatus, job, birthPlace
        case avatarURL = "photoURL"
        case age, ageGroup, zodiacSign
        case karma, isPremium
        case createdAt, lastLoginAt
        case dailyFortunesUsed, favoriteFortuneTypes, totalFortunes, totalTests
        case socialVisible, blockedUsers, freeAuraMatches, lastWeeklyAuraMatchReset
        case preferences
    }
    
    // MARK: - Initialization
    init(
        id: String,
        name: String,
        email: String = "",
        birthDate: Date? = nil,
        gender: String? = nil,
        relationshipStatus: String? = nil,
        job: String? = nil,
        birthPlace: String? = nil,
        avatarURL: String? = nil,
        age: Int? = nil,
        ageGroup: String? = nil,
        zodiacSign: String? = nil,
        karma: Int = 10,
        isPremium: Bool = false,
        createdAt: Date = Date(),
        lastLoginAt: Date = Date(),
        dailyFortunesUsed: Int = 0,
        favoriteFortuneTypes: [String] = [],
        totalFortunes: Int = 0,
        totalTests: Int = 0,
        socialVisible: Bool = true,
        blockedUsers: [String] = [],
        freeAuraMatches: Int = 3,
        lastWeeklyAuraMatchReset: Date? = nil,
        preferences: UserPreferences = UserPreferences()
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.birthDate = birthDate
        self.gender = gender
        self.relationshipStatus = relationshipStatus
        self.job = job
        self.birthPlace = birthPlace
        self.avatarURL = avatarURL
        self.age = age
        self.ageGroup = ageGroup
        self.zodiacSign = zodiacSign
        self.karma = karma
        self.isPremium = isPremium
        self.createdAt = createdAt
        self.lastLoginAt = lastLoginAt
        self.dailyFortunesUsed = dailyFortunesUsed
        self.favoriteFortuneTypes = favoriteFortuneTypes
        self.totalFortunes = totalFortunes
        self.totalTests = totalTests
        self.socialVisible = socialVisible
        self.blockedUsers = blockedUsers
        self.freeAuraMatches = freeAuraMatches
        self.lastWeeklyAuraMatchReset = lastWeeklyAuraMatchReset
        self.preferences = preferences
    }
    
    // MARK: - Computed Properties
    
    /// Check if user has enough karma for an action
    func hasEnoughKarma(_ required: Int) -> Bool {
        return karma >= required
    }
    
    /// Calculate zodiac sign from birth date
    static func calculateZodiacSign(from date: Date) -> String {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        
        switch (month, day) {
        case (3, 21...31), (4, 1...19): return "Koç"
        case (4, 20...30), (5, 1...20): return "Boğa"
        case (5, 21...31), (6, 1...20): return "İkizler"
        case (6, 21...30), (7, 1...22): return "Yengeç"
        case (7, 23...31), (8, 1...22): return "Aslan"
        case (8, 23...31), (9, 1...22): return "Başak"
        case (9, 23...30), (10, 1...22): return "Terazi"
        case (10, 23...31), (11, 1...21): return "Akrep"
        case (11, 22...30), (12, 1...21): return "Yay"
        case (12, 22...31), (1, 1...19): return "Oğlak"
        case (1, 20...31), (2, 1...18): return "Kova"
        case (2, 19...29), (3, 1...20): return "Balık"
        default: return "Bilinmiyor"
        }
    }
    
    /// Calculate age from birth date
    static func calculateAge(from date: Date) -> Int {
        let calendar = Calendar.current
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: date, to: now)
        return ageComponents.year ?? 0
    }
    
    /// Guest user factory
    static func guest(id: String, birthDate: Date? = nil) -> UserModel {
        var user = UserModel(
            id: id,
            name: "Misafir",
            email: "",
            karma: 10
        )
        
        if let birthDate = birthDate {
            user.birthDate = birthDate
            user.zodiacSign = calculateZodiacSign(from: birthDate)
            user.age = calculateAge(from: birthDate)
            user.ageGroup = user.age ?? 0 < 18 ? "under18" : "adult"
        }
        
        return user
    }
}

// MARK: - User Preferences
/// User settings and preferences
struct UserPreferences: Codable, Equatable {
    var notificationsEnabled: Bool
    var soundEnabled: Bool
    var vibrationEnabled: Bool
    var language: String
    var theme: String
    var autoSaveFortunes: Bool
    var showKarmaNotifications: Bool
    var premiumNotifications: Bool
    var analyticsEnabled: Bool
    var adsPersonalizationEnabled: Bool
    
    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case notificationsEnabled = "notifications"
        case soundEnabled = "sound"
        case vibrationEnabled = "vibration"
        case language, theme
        case autoSaveFortunes, showKarmaNotifications, premiumNotifications
        case analyticsEnabled = "analytics"
        case adsPersonalizationEnabled = "adsPersonalization"
    }
    
    // MARK: - Initialization
    init(
        notificationsEnabled: Bool = true,
        soundEnabled: Bool = true,
        vibrationEnabled: Bool = true,
        language: String = "tr",
        theme: String = "mystical",
        autoSaveFortunes: Bool = true,
        showKarmaNotifications: Bool = true,
        premiumNotifications: Bool = false,
        analyticsEnabled: Bool = true,
        adsPersonalizationEnabled: Bool = true
    ) {
        self.notificationsEnabled = notificationsEnabled
        self.soundEnabled = soundEnabled
        self.vibrationEnabled = vibrationEnabled
        self.language = language
        self.theme = theme
        self.autoSaveFortunes = autoSaveFortunes
        self.showKarmaNotifications = showKarmaNotifications
        self.premiumNotifications = premiumNotifications
        self.analyticsEnabled = analyticsEnabled
        self.adsPersonalizationEnabled = adsPersonalizationEnabled
    }
}

// MARK: - Firestore Conversion
extension UserModel {
    /// Convert to Firestore-compatible dictionary
    func toFirestore() -> [String: Any] {
        var data: [String: Any] = [
            "id": id,
            "name": name,
            "email": email,
            "karma": karma,
            "isPremium": isPremium,
            "dailyFortunesUsed": dailyFortunesUsed,
            "favoriteFortuneTypes": favoriteFortuneTypes,
            "totalFortunes": totalFortunes,
            "totalTests": totalTests,
            "socialVisible": socialVisible,
            "blockedUsers": blockedUsers,
            "freeAuraMatches": freeAuraMatches,
            "preferences": preferences.toFirestore()
        ]
        
        if let birthDate = birthDate {
            data["birthDate"] = birthDate
        }
        if let gender = gender {
            data["gender"] = gender
        }
        if let zodiacSign = zodiacSign {
            data["zodiacSign"] = zodiacSign
        }
        if let age = age {
            data["age"] = age
        }
        if let ageGroup = ageGroup {
            data["ageGroup"] = ageGroup
        }
        if let avatarURL = avatarURL {
            data["photoURL"] = avatarURL
        }
        
        return data
    }
    
    /// Create from Firestore document data
    static func fromFirestore(_ data: [String: Any]) -> UserModel? {
        guard let id = data["id"] as? String,
              let name = data["name"] as? String else {
            return nil
        }
        
        let preferencesData = data["preferences"] as? [String: Any]
        let preferences = preferencesData.map { UserPreferences.fromFirestore($0) } ?? UserPreferences()
        
        return UserModel(
            id: id,
            name: name,
            email: data["email"] as? String ?? "",
            birthDate: (data["birthDate"] as? Date),
            gender: data["gender"] as? String,
            relationshipStatus: data["relationshipStatus"] as? String,
            job: data["job"] as? String,
            birthPlace: data["birthPlace"] as? String,
            avatarURL: data["photoURL"] as? String,
            age: data["age"] as? Int,
            ageGroup: data["ageGroup"] as? String,
            zodiacSign: data["zodiacSign"] as? String,
            karma: data["karma"] as? Int ?? 10,
            isPremium: data["isPremium"] as? Bool ?? false,
            createdAt: (data["createdAt"] as? Date) ?? Date(),
            lastLoginAt: (data["lastLoginAt"] as? Date) ?? Date(),
            dailyFortunesUsed: data["dailyFortunesUsed"] as? Int ?? 0,
            favoriteFortuneTypes: data["favoriteFortuneTypes"] as? [String] ?? [],
            totalFortunes: data["totalFortunes"] as? Int ?? 0,
            totalTests: data["totalTests"] as? Int ?? 0,
            socialVisible: data["socialVisible"] as? Bool ?? true,
            blockedUsers: data["blockedUsers"] as? [String] ?? [],
            freeAuraMatches: data["freeAuraMatches"] as? Int ?? 3,
            lastWeeklyAuraMatchReset: data["lastWeeklyAuraMatchReset"] as? Date,
            preferences: preferences
        )
    }
}

extension UserPreferences {
    func toFirestore() -> [String: Any] {
        return [
            "notifications": notificationsEnabled,
            "sound": soundEnabled,
            "vibration": vibrationEnabled,
            "language": language,
            "theme": theme,
            "autoSaveFortunes": autoSaveFortunes,
            "showKarmaNotifications": showKarmaNotifications,
            "premiumNotifications": premiumNotifications
        ]
    }
    
    static func fromFirestore(_ data: [String: Any]) -> UserPreferences {
        return UserPreferences(
            notificationsEnabled: data["notifications"] as? Bool ?? true,
            soundEnabled: data["sound"] as? Bool ?? true,
            vibrationEnabled: data["vibration"] as? Bool ?? true,
            language: data["language"] as? String ?? "tr",
            theme: data["theme"] as? String ?? "mystical",
            autoSaveFortunes: data["autoSaveFortunes"] as? Bool ?? true,
            showKarmaNotifications: data["showKarmaNotifications"] as? Bool ?? true,
            premiumNotifications: data["premiumNotifications"] as? Bool ?? false
        )
    }
}
