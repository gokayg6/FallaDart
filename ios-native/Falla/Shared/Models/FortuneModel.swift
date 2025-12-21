// FortuneModel.swift
// Falla - iOS 26 Fortune Telling App
// Fortune data models matching Flutter's fortune_model.dart

import Foundation

// MARK: - Fortune Type
/// Types of fortune readings available
enum FortuneType: String, Codable, CaseIterable {
    case tarot
    case coffee
    case palm
    case katina
    case face
    case astrology
    case dream
    case daily
    
    var displayName: String {
        switch self {
        case .tarot: return "Tarot Falı"
        case .coffee: return "Kahve Falı"
        case .palm: return "El Falı"
        case .katina: return "Katina Falı"
        case .face: return "Yüz Analizi"
        case .astrology: return "Astroloji"
        case .dream: return "Rüya Yorumu"
        case .daily: return "Günlük Burç"
        }
    }
    
    var iconName: String {
        switch self {
        case .tarot: return "suit.spade.fill"
        case .coffee: return "cup.and.saucer.fill"
        case .palm: return "hand.raised.fill"
        case .katina: return "wand.and.stars"
        case .face: return "face.smiling"
        case .astrology: return "star.circle.fill"
        case .dream: return "moon.zzz.fill"
        case .daily: return "sun.max.fill"
        }
    }
    
    var karmaCost: Int {
        switch self {
        case .tarot: return 5
        case .coffee: return 8
        case .palm: return 7
        case .katina: return 6
        case .face: return 10
        case .astrology: return 5
        case .dream: return 4
        case .daily: return 0
        }
    }
}

// MARK: - Fortune Status
/// Status of a fortune reading
enum FortuneStatus: String, Codable {
    case pending
    case processing
    case completed
    case failed
}

// MARK: - Fortune Model
/// Main fortune reading data model
struct FortuneModel: Codable, Identifiable, Equatable {
    // MARK: - Identity
    let id: String
    let userId: String
    
    // MARK: - Type & Status
    var type: FortuneType
    var status: FortuneStatus
    
    // MARK: - Content
    var title: String
    var interpretation: String?
    var inputData: [String: AnyCodable]?
    var selectedCards: [String]?
    var imageUrls: [String]?
    var question: String?
    
    // MARK: - Timestamps
    var createdAt: Date
    var completedAt: Date?
    
    // MARK: - User Actions
    var isFavorite: Bool
    var rating: Int?
    var notes: String?
    
    // MARK: - Target
    var isForSelf: Bool
    var targetPersonName: String?
    
    // MARK: - Metadata
    var metadata: [String: AnyCodable]?
    var karmaUsed: Int
    var isPremium: Bool
    
    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id, userId, type, status, title, interpretation
        case inputData, selectedCards, imageUrls, question
        case createdAt, completedAt
        case isFavorite, rating, notes
        case isForSelf, targetPersonName
        case metadata, karmaUsed, isPremium
    }
    
    // MARK: - Initialization
    init(
        id: String = UUID().uuidString,
        userId: String,
        type: FortuneType,
        status: FortuneStatus = .pending,
        title: String = "",
        interpretation: String? = nil,
        inputData: [String: AnyCodable]? = nil,
        selectedCards: [String]? = nil,
        imageUrls: [String]? = nil,
        question: String? = nil,
        createdAt: Date = Date(),
        completedAt: Date? = nil,
        isFavorite: Bool = false,
        rating: Int? = nil,
        notes: String? = nil,
        isForSelf: Bool = true,
        targetPersonName: String? = nil,
        metadata: [String: AnyCodable]? = nil,
        karmaUsed: Int = 0,
        isPremium: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.type = type
        self.status = status
        self.title = title.isEmpty ? type.displayName : title
        self.interpretation = interpretation
        self.inputData = inputData
        self.selectedCards = selectedCards
        self.imageUrls = imageUrls
        self.question = question
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.isFavorite = isFavorite
        self.rating = rating
        self.notes = notes
        self.isForSelf = isForSelf
        self.targetPersonName = targetPersonName
        self.metadata = metadata
        self.karmaUsed = karmaUsed
        self.isPremium = isPremium
    }
}

// MARK: - Tarot Card
/// Individual tarot card data
struct TarotCard: Codable, Identifiable, Equatable {
    let id: String
    var name: String
    var nameEn: String?
    var description: String?
    var imageUrl: String?
    var category: String?
    var suit: String?
    var number: Int?
    var keywords: [String]
    var uprightMeaning: String?
    var reversedMeaning: String?
    var isReversed: Bool
    
    init(
        id: String,
        name: String,
        nameEn: String? = nil,
        description: String? = nil,
        imageUrl: String? = nil,
        category: String? = nil,
        suit: String? = nil,
        number: Int? = nil,
        keywords: [String] = [],
        uprightMeaning: String? = nil,
        reversedMeaning: String? = nil,
        isReversed: Bool = false
    ) {
        self.id = id
        self.name = name
        self.nameEn = nameEn
        self.description = description
        self.imageUrl = imageUrl
        self.category = category
        self.suit = suit
        self.number = number
        self.keywords = keywords
        self.uprightMeaning = uprightMeaning
        self.reversedMeaning = reversedMeaning
        self.isReversed = isReversed
    }
}

// MARK: - Fortune Teller
/// Fortune teller/reader profile
struct FortuneTeller: Codable, Identifiable, Equatable {
    let id: String
    var name: String
    var title: String?
    var avatarUrl: String?
    var specialties: [FortuneType]
    var rating: Double
    var totalReadings: Int
    var bio: String?
    var isOnline: Bool
    var responseTime: String?
    
    init(
        id: String,
        name: String,
        title: String? = nil,
        avatarUrl: String? = nil,
        specialties: [FortuneType] = [],
        rating: Double = 5.0,
        totalReadings: Int = 0,
        bio: String? = nil,
        isOnline: Bool = false,
        responseTime: String? = nil
    ) {
        self.id = id
        self.name = name
        self.title = title
        self.avatarUrl = avatarUrl
        self.specialties = specialties
        self.rating = rating
        self.totalReadings = totalReadings
        self.bio = bio
        self.isOnline = isOnline
        self.responseTime = responseTime
    }
}

// MARK: - Fortune Result
/// Result data returned from AI fortune generation
struct FortuneResult: Codable {
    let success: Bool
    let fortuneId: String?
    let interpretation: String?
    let error: String?
    let metadata: [String: AnyCodable]?
}

// MARK: - Firestore Conversion
extension FortuneModel {
    func toFirestore() -> [String: Any] {
        var data: [String: Any] = [
            "id": id,
            "userId": userId,
            "type": type.rawValue,
            "status": status.rawValue,
            "title": title,
            "createdAt": createdAt,
            "isFavorite": isFavorite,
            "isForSelf": isForSelf,
            "karmaUsed": karmaUsed,
            "isPremium": isPremium
        ]
        
        if let interpretation = interpretation { data["interpretation"] = interpretation }
        if let question = question { data["question"] = question }
        if let selectedCards = selectedCards { data["selectedCards"] = selectedCards }
        if let imageUrls = imageUrls { data["imageUrls"] = imageUrls }
        if let completedAt = completedAt { data["completedAt"] = completedAt }
        if let rating = rating { data["rating"] = rating }
        if let notes = notes { data["notes"] = notes }
        if let targetPersonName = targetPersonName { data["targetPersonName"] = targetPersonName }
        
        return data
    }
    
    static func fromFirestore(_ data: [String: Any]) -> FortuneModel? {
        guard let id = data["id"] as? String,
              let userId = data["userId"] as? String,
              let typeStr = data["type"] as? String,
              let type = FortuneType(rawValue: typeStr) else {
            return nil
        }
        
        let statusStr = data["status"] as? String ?? "pending"
        let status = FortuneStatus(rawValue: statusStr) ?? .pending
        
        return FortuneModel(
            id: id,
            userId: userId,
            type: type,
            status: status,
            title: data["title"] as? String ?? type.displayName,
            interpretation: data["interpretation"] as? String,
            selectedCards: data["selectedCards"] as? [String],
            imageUrls: data["imageUrls"] as? [String],
            question: data["question"] as? String,
            createdAt: (data["createdAt"] as? Date) ?? Date(),
            completedAt: data["completedAt"] as? Date,
            isFavorite: data["isFavorite"] as? Bool ?? false,
            rating: data["rating"] as? Int,
            notes: data["notes"] as? String,
            isForSelf: data["isForSelf"] as? Bool ?? true,
            targetPersonName: data["targetPersonName"] as? String,
            karmaUsed: data["karmaUsed"] as? Int ?? 0,
            isPremium: data["isPremium"] as? Bool ?? false
        )
    }
}

extension TarotCard {
    func toFirestore() -> [String: Any] {
        var data: [String: Any] = [
            "id": id,
            "name": name,
            "keywords": keywords,
            "isReversed": isReversed
        ]
        
        if let nameEn = nameEn { data["nameEn"] = nameEn }
        if let description = description { data["description"] = description }
        if let imageUrl = imageUrl { data["imageUrl"] = imageUrl }
        if let category = category { data["category"] = category }
        if let suit = suit { data["suit"] = suit }
        if let number = number { data["number"] = number }
        if let uprightMeaning = uprightMeaning { data["uprightMeaning"] = uprightMeaning }
        if let reversedMeaning = reversedMeaning { data["reversedMeaning"] = reversedMeaning }
        
        return data
    }
}

// MARK: - AnyCodable Helper
/// Type-erased Codable wrapper for dynamic data
struct AnyCodable: Codable, Equatable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let arrayValue as [Any]:
            try container.encode(arrayValue.map { AnyCodable($0) })
        case let dictValue as [String: Any]:
            try container.encode(dictValue.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
    
    static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        switch (lhs.value, rhs.value) {
        case (let l as Int, let r as Int): return l == r
        case (let l as Double, let r as Double): return l == r
        case (let l as String, let r as String): return l == r
        case (let l as Bool, let r as Bool): return l == r
        default: return false
        }
    }
}
