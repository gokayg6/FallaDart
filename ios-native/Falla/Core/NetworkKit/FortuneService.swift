// FortuneService.swift
// Falla - iOS 26 Fortune Telling App
// Fortune generation and management service

import Foundation
import FirebaseFirestore
import FirebaseStorage

/// Service for managing fortune readings
actor FortuneService {
    // MARK: - Shared Instance
    static let shared = FortuneService()
    
    // MARK: - Dependencies
    private let firebaseService = FirebaseService.shared
    private let aiService = AIService.shared
    private let apiClient = APIClient.shared
    
    // MARK: - Fortune Generation
    
    /// Generate a coffee fortune reading
    func generateCoffeeFortune(
        imageUrls: [String],
        question: String?,
        userId: String
    ) async throws -> FortuneModel {
        // Get AI interpretation
        let interpretation = try await aiService.generateCoffeeFortune(
            imageUrls: imageUrls,
            question: question
        )
        
        // Create fortune model
        let fortune = FortuneModel(
            id: UUID().uuidString,
            userId: userId,
            type: .coffee,
            status: .completed,
            title: "Kahve Falı",
            interpretation: interpretation,
            imageUrls: imageUrls,
            question: question,
            karmaUsed: 8
        )
        
        // Save to Firebase
        try await firebaseService.saveFortune(fortune)
        
        return fortune
    }
    
    /// Generate a tarot fortune reading
    func generateTarotFortune(
        selectedCards: [String],
        spreadType: String,
        formData: [String: String],
        question: String?,
        userId: String
    ) async throws -> FortuneModel {
        // Get AI interpretation
        let interpretation = try await aiService.generateTarotFortune(
            selectedCards: selectedCards,
            spreadType: spreadType,
            question: question
        )
        
        let fortune = FortuneModel(
            id: UUID().uuidString,
            userId: userId,
            type: .tarot,
            status: .completed,
            title: "Tarot Falı",
            interpretation: interpretation,
            selectedCards: selectedCards,
            question: question,
            karmaUsed: 5,
            metadata: formData
        )
        
        try await firebaseService.saveFortune(fortune)
        
        return fortune
    }
    
    /// Generate a palm reading
    func generatePalmFortune(
        imageUrl: String,
        question: String?,
        userId: String
    ) async throws -> FortuneModel {
        let interpretation = try await aiService.generatePalmReading(
            imageUrl: imageUrl,
            question: question
        )
        
        let fortune = FortuneModel(
            id: UUID().uuidString,
            userId: userId,
            type: .palm,
            status: .completed,
            title: "El Falı",
            interpretation: interpretation,
            imageUrls: [imageUrl],
            question: question,
            karmaUsed: 10
        )
        
        try await firebaseService.saveFortune(fortune)
        
        return fortune
    }
    
    /// Generate a dream interpretation
    func generateDreamFortune(
        dreamDescription: String,
        mood: String,
        symbols: [String],
        userId: String
    ) async throws -> FortuneModel {
        let interpretation = try await aiService.generateDreamInterpretation(
            dreamDescription: dreamDescription,
            symbols: symbols
        )
        
        let fortune = FortuneModel(
            id: UUID().uuidString,
            userId: userId,
            type: .dream,
            status: .completed,
            title: "Rüya Yorumu",
            interpretation: interpretation,
            question: dreamDescription,
            karmaUsed: 6,
            metadata: [
                "mood": mood,
                "symbols": symbols.joined(separator: ",")
            ]
        )
        
        try await firebaseService.saveFortune(fortune)
        
        return fortune
    }
    
    /// Generate daily horoscope
    func generateDailyHoroscope(
        zodiacSign: String,
        userId: String
    ) async throws -> FortuneModel {
        let interpretation = try await aiService.generateDailyHoroscope(
            zodiacSign: zodiacSign,
            birthDate: nil
        )
        
        let fortune = FortuneModel(
            id: UUID().uuidString,
            userId: userId,
            type: .daily,
            status: .completed,
            title: "Günlük Burç - \(zodiacSign)",
            interpretation: interpretation,
            karmaUsed: 0 // Free
        )
        
        try await firebaseService.saveFortune(fortune)
        
        return fortune
    }
    
    // MARK: - Image Upload
    
    /// Upload images to Firebase Storage
    func uploadImages(_ images: [Data], userId: String) async throws -> [String] {
        var imageUrls: [String] = []
        
        for (index, imageData) in images.enumerated() {
            let filename = "\(userId)/fortune_\(Date().timeIntervalSince1970)_\(index).jpg"
            let url = try await firebaseService.uploadImage(imageData, path: filename)
            imageUrls.append(url)
        }
        
        return imageUrls
    }
    
    // MARK: - Fortune Retrieval
    
    /// Get all fortunes for a user
    func getFortunes(userId: String, limit: Int = 20) async throws -> [FortuneModel] {
        return try await firebaseService.getFortuneHistory(userId: userId)
    }
    
    /// Get a specific fortune by ID
    func getFortune(id: String, userId: String) async throws -> FortuneModel? {
        return try await firebaseService.getFortune(userId: userId, fortuneId: id)
    }
    
    /// Get recent fortunes
    func getRecentFortunes(userId: String, limit: Int = 5) async throws -> [FortuneModel] {
        let allFortunes = try await getFortunes(userId: userId, limit: limit)
        return Array(allFortunes.prefix(limit))
    }
    
    /// Get favorite fortunes
    func getFavoriteFortunes(userId: String) async throws -> [FortuneModel] {
        let allFortunes = try await getFortunes(userId: userId)
        return allFortunes.filter { $0.isFavorite }
    }
    
    // MARK: - Fortune Updates
    
    /// Toggle favorite status
    func toggleFavorite(fortuneId: String, userId: String) async throws {
        guard var fortune = try await getFortune(id: fortuneId, userId: userId) else {
            throw FortuneServiceError.fortuneNotFound
        }
        
        fortune.isFavorite.toggle()
        try await firebaseService.updateFortune(fortune)
    }
    
    /// Rate a fortune
    func rateFortune(fortuneId: String, userId: String, rating: Int) async throws {
        guard var fortune = try await getFortune(id: fortuneId, userId: userId) else {
            throw FortuneServiceError.fortuneNotFound
        }
        
        fortune.rating = rating
        try await firebaseService.updateFortune(fortune)
    }
    
    /// Delete a fortune
    func deleteFortune(fortuneId: String, userId: String) async throws {
        try await firebaseService.deleteFortune(userId: userId, fortuneId: fortuneId)
    }
    
    // MARK: - Statistics
    
    /// Get fortune count by type
    func getFortuneStats(userId: String) async throws -> [FortuneType: Int] {
        let fortunes = try await getFortunes(userId: userId, limit: 1000)
        var stats: [FortuneType: Int] = [:]
        
        for fortune in fortunes {
            stats[fortune.type, default: 0] += 1
        }
        
        return stats
    }
    
    /// Get total fortune count
    func getTotalFortuneCount(userId: String) async throws -> Int {
        let fortunes = try await getFortunes(userId: userId, limit: 1000)
        return fortunes.count
    }
}

// MARK: - Errors
enum FortuneServiceError: LocalizedError {
    case fortuneNotFound
    case uploadFailed
    case generationFailed
    
    var errorDescription: String? {
        switch self {
        case .fortuneNotFound:
            return "Fal bulunamadı"
        case .uploadFailed:
            return "Resim yüklenirken hata oluştu"
        case .generationFailed:
            return "Fal oluşturulurken hata oluştu"
        }
    }
}
