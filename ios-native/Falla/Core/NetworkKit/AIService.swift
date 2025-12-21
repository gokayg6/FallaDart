// AIService.swift
// Falla - iOS 26 Fortune Telling App
// AI fortune generation service matching Flutter's ai_service.dart

import Foundation

// MARK: - AI Service
/// Service for AI-powered fortune generation using OpenAI
actor AIService {
    // MARK: - Singleton
    static let shared = AIService()
    
    // MARK: - Configuration
    private var apiKey: String?
    private var baseURL = URL(string: "https://api.openai.com/v1")!
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    // MARK: - Default Model
    private let defaultModel = "gpt-4o"
    private let visionModel = "gpt-4o"
    private let imageModel = "dall-e-3"
    
    // MARK: - Initialization
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }
    
    // MARK: - Configuration
    func configure(apiKey: String, baseURL: String? = nil) {
        self.apiKey = apiKey
        if let baseURL = baseURL, let url = URL(string: baseURL) {
            self.baseURL = url
        }
    }
    
    // MARK: - System Prompts
    private func systemPrompt(english: Bool = false) -> String {
        if english {
            return """
            You are a mystical fortune teller with deep knowledge of astrology, tarot, palmistry, and dream interpretation.
            Speak in a warm, mysterious, yet professional tone.
            Provide detailed, personalized readings based on the user's information.
            Always be positive and encouraging while being honest about challenges.
            Use mystical language and symbols to enhance the experience.
            Format your responses with clear sections using emojis as dividers.
            """
        } else {
            return """
            Sen derin astroloji, tarot, el falı ve rüya yorumu bilgisine sahip mistik bir falcısın.
            Sıcak, gizemli ama profesyonel bir tonda konuş.
            Kullanıcının bilgilerine göre detaylı, kişiselleştirilmiş yorumlar yap.
            Zorluklardan bahsederken dürüst ol ama her zaman pozitif ve cesaretlendirici ol.
            Deneyimi zenginleştirmek için mistik dil ve semboller kullan.
            Yanıtlarını emoji ayırıcılarla net bölümler halinde formatla.
            """
        }
    }
    
    // MARK: - Tarot Reading
    func generateTarotReading(
        cardIds: [String],
        cardNames: [String],
        user: UserModel,
        question: String? = nil,
        english: Bool = false
    ) async throws -> String {
        let cardsDescription = zip(cardIds, cardNames).map { "\($0): \($1)" }.joined(separator: ", ")
        
        let userContext = english 
            ? "User: \(user.name), Zodiac: \(user.zodiacSign ?? "Unknown")"
            : "Kullanıcı: \(user.name), Burç: \(user.zodiacSign ?? "Bilinmiyor")"
        
        let prompt = english
            ? """
            Perform a tarot reading for the following cards: \(cardsDescription)
            \(userContext)
            \(question.map { "Question: \($0)" } ?? "")
            
            Provide a detailed interpretation covering:
            1. 🔮 Overall Energy
            2. 🌟 Past Influences
            3. ⏰ Present Situation
            4. 🌙 Future Possibilities
            5. 💡 Advice and Guidance
            """
            : """
            Şu kartlar için tarot yorumu yap: \(cardsDescription)
            \(userContext)
            \(question.map { "Soru: \($0)" } ?? "")
            
            Detaylı bir yorum yap:
            1. 🔮 Genel Enerji
            2. 🌟 Geçmiş Etkiler
            3. ⏰ Şimdiki Durum
            4. 🌙 Gelecek Olasılıkları
            5. 💡 Tavsiye ve Rehberlik
            """
        
        return try await chat(prompt: prompt, english: english)
    }
    
    // MARK: - Coffee Reading
    func generateCoffeeReading(
        imageUrls: [String],
        user: UserModel,
        question: String? = nil,
        topics: [String]? = nil,
        english: Bool = false
    ) async throws -> String {
        let userContext = english
            ? "User: \(user.name), Zodiac: \(user.zodiacSign ?? "Unknown")"
            : "Kullanıcı: \(user.name), Burç: \(user.zodiacSign ?? "Bilinmiyor")"
        
        let topicsText = topics?.joined(separator: ", ") ?? (english ? "general" : "genel")
        
        let prompt = english
            ? """
            Analyze the coffee cup images and provide a detailed fortune reading.
            \(userContext)
            Focus areas: \(topicsText)
            \(question.map { "Question: \($0)" } ?? "")
            
            Describe the symbols you see and provide interpretations for:
            1. ☕ Cup Symbols & Their Meanings
            2. 💕 Love & Relationships
            3. 💼 Career & Finance
            4. 🏥 Health & Wellness
            5. 🔮 General Future Outlook
            """
            : """
            Kahve fincanı görsellerini analiz et ve detaylı fal yorumu yap.
            \(userContext)
            Odak alanları: \(topicsText)
            \(question.map { "Soru: \($0)" } ?? "")
            
            Gördüğün sembolleri tanımla ve şunlar için yorumla:
            1. ☕ Fincan Sembolleri ve Anlamları
            2. 💕 Aşk ve İlişkiler
            3. 💼 Kariyer ve Finans
            4. 🏥 Sağlık ve Wellness
            5. 🔮 Genel Gelecek Görünümü
            """
        
        // Use vision model for image analysis
        return try await visionChat(prompt: prompt, imageUrls: imageUrls, english: english)
    }
    
    // MARK: - Palm Reading
    func generatePalmReading(
        palmImageUrl: String,
        user: UserModel,
        question: String? = nil,
        english: Bool = false
    ) async throws -> String {
        let userContext = english
            ? "User: \(user.name), Zodiac: \(user.zodiacSign ?? "Unknown")"
            : "Kullanıcı: \(user.name), Burç: \(user.zodiacSign ?? "Bilinmiyor")"
        
        let prompt = english
            ? """
            Analyze the palm image and provide a detailed palm reading.
            \(userContext)
            \(question.map { "Question: \($0)" } ?? "")
            
            Analyze these lines and provide interpretations:
            1. ❤️ Heart Line - Love & Emotional Life
            2. 🧠 Head Line - Intellect & Decision Making
            3. ⏳ Life Line - Vitality & Major Life Events
            4. 🌟 Fate Line - Career & Destiny
            5. 💫 Overall Palm Character
            """
            : """
            El görselini analiz et ve detaylı el falı yorumu yap.
            \(userContext)
            \(question.map { "Soru: \($0)" } ?? "")
            
            Bu çizgileri analiz et ve yorumla:
            1. ❤️ Kalp Çizgisi - Aşk ve Duygusal Yaşam
            2. 🧠 Kafa Çizgisi - Zeka ve Karar Verme
            3. ⏳ Yaşam Çizgisi - Canlılık ve Önemli Yaşam Olayları
            4. 🌟 Kader Çizgisi - Kariyer ve Kader
            5. 💫 Genel El Karakteri
            """
        
        return try await visionChat(prompt: prompt, imageUrls: [palmImageUrl], english: english)
    }
    
    // MARK: - Dream Interpretation
    func generateDreamInterpretation(
        dreamDescription: String,
        user: UserModel,
        english: Bool = false
    ) async throws -> String {
        let userContext = english
            ? "User: \(user.name), Zodiac: \(user.zodiacSign ?? "Unknown")"
            : "Kullanıcı: \(user.name), Burç: \(user.zodiacSign ?? "Bilinmiyor")"
        
        let prompt = english
            ? """
            Interpret the following dream:
            "\(dreamDescription)"
            \(userContext)
            
            Provide a detailed interpretation covering:
            1. 🌙 Dream Symbols & Their Meanings
            2. 🔮 Hidden Messages & Subconscious
            3. 💭 Connection to Waking Life
            4. 🌟 Spiritual Significance
            5. 💡 Guidance for the Dreamer
            """
            : """
            Şu rüyayı yorumla:
            "\(dreamDescription)"
            \(userContext)
            
            Detaylı yorum yap:
            1. 🌙 Rüya Sembolleri ve Anlamları
            2. 🔮 Gizli Mesajlar ve Bilinçaltı
            3. 💭 Uyanık Yaşamla Bağlantı
            4. 🌟 Ruhani Anlam
            5. 💡 Rüya Gören İçin Rehberlik
            """
        
        return try await chat(prompt: prompt, english: english)
    }
    
    // MARK: - Daily Horoscope
    func generateDailyHoroscope(
        zodiacSign: String,
        date: Date,
        english: Bool = false
    ) async throws -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMMM yyyy"
        dateFormatter.locale = Locale(identifier: english ? "en_US" : "tr_TR")
        let dateString = dateFormatter.string(from: date)
        
        let prompt = english
            ? """
            Generate a daily horoscope for \(zodiacSign) for \(dateString).
            
            Include:
            1. 🌟 Overall Mood & Energy (score /10)
            2. 💕 Love & Relationships (score /10)
            3. 💼 Career & Finance (score /10)
            4. 🏥 Health (score /10)
            5. 🔮 Lucky Numbers & Colors
            6. 💡 Daily Advice
            """
            : """
            \(zodiacSign) burcu için \(dateString) günlük yorumu oluştur.
            
            Şunları içersin:
            1. 🌟 Genel Ruh Hali ve Enerji (puan /10)
            2. 💕 Aşk ve İlişkiler (puan /10)
            3. 💼 Kariyer ve Finans (puan /10)
            4. 🏥 Sağlık (puan /10)
            5. 🔮 Şanslı Sayılar ve Renkler
            6. 💡 Günlük Tavsiye
            """
        
        return try await chat(prompt: prompt, english: english)
    }
    
    // MARK: - Love Compatibility
    func generateLoveCompatibilityAnalysis(
        userZodiac: String,
        candidateZodiac: String,
        candidateName: String,
        relationshipType: String? = nil,
        english: Bool = false
    ) async throws -> String {
        let prompt = english
            ? """
            Analyze the love compatibility between \(userZodiac) and \(candidateZodiac) (\(candidateName)).
            Relationship type: \(relationshipType ?? "romantic")
            
            Provide:
            1. 💕 Overall Compatibility Score (/100)
            2. 🔥 Physical Chemistry
            3. 💬 Communication Style
            4. 🏠 Long-term Potential
            5. ⚠️ Potential Challenges
            6. 💡 Advice for Success
            """
            : """
            \(userZodiac) ve \(candidateZodiac) (\(candidateName)) arasındaki aşk uyumunu analiz et.
            İlişki türü: \(relationshipType ?? "romantik")
            
            Şunları ver:
            1. 💕 Genel Uyum Puanı (/100)
            2. 🔥 Fiziksel Çekim
            3. 💬 İletişim Tarzı
            4. 🏠 Uzun Vadeli Potansiyel
            5. ⚠️ Potansiyel Zorluklar
            6. 💡 Başarı İçin Tavsiye
            """
        
        return try await chat(prompt: prompt, english: english)
    }
    
    // MARK: - Test Generation
    func generateLoveTest() async throws -> QuizTest {
        let prompt = """
        Aşk testioluştur. JSON formatında döndür:
        {
            "title": "Aşk Testi",
            "description": "...",
            "questions": [
                {
                    "id": "q1",
                    "text": "Soru metni",
                    "options": ["A seçeneği", "B seçeneği", "C seçeneği", "D seçeneği"],
                    "scores": [3, 2, 1, 0]
                }
            ],
            "resultRanges": [
                {"min": 0, "max": 5, "title": "...", "description": "..."}
            ]
        }
        En az 10 soru olsun.
        """
        
        let response = try await chat(prompt: prompt, english: false)
        
        // Parse JSON response
        guard let data = response.data(using: .utf8),
              let test = try? JSONDecoder().decode(QuizTest.self, from: data) else {
            throw AIError.parsingFailed
        }
        
        return test
    }
    
    // MARK: - Private Methods
    
    private func chat(prompt: String, english: Bool) async throws -> String {
        try ensureConfigured()
        
        let messages = [
            ChatMessage(role: "system", content: systemPrompt(english: english)),
            ChatMessage(role: "user", content: prompt)
        ]
        
        let request = ChatRequest(model: defaultModel, messages: messages)
        let response: ChatResponse = try await post(path: "/chat/completions", body: request)
        
        return response.choices.first?.message.content ?? ""
    }
    
    private func visionChat(prompt: String, imageUrls: [String], english: Bool) async throws -> String {
        try ensureConfigured()
        
        var content: [VisionContent] = [.init(type: "text", text: prompt)]
        
        for url in imageUrls {
            content.append(.init(type: "image_url", imageUrl: .init(url: url)))
        }
        
        let messages = [
            VisionMessage(role: "system", content: [.init(type: "text", text: systemPrompt(english: english))]),
            VisionMessage(role: "user", content: content)
        ]
        
        let request = VisionRequest(model: visionModel, messages: messages)
        let response: ChatResponse = try await post(path: "/chat/completions", body: request)
        
        return response.choices.first?.message.content ?? ""
    }
    
    private func post<T: Encodable, R: Decodable>(path: String, body: T) async throws -> R {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey!)", forHTTPHeaderField: "Authorization")
        request.httpBody = try encoder.encode(body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw AIError.apiError(httpResponse.statusCode)
        }
        
        return try decoder.decode(R.self, from: data)
    }
    
    private func ensureConfigured() throws {
        guard apiKey != nil else {
            throw AIError.notConfigured
        }
    }
}

// MARK: - Request/Response Models
private struct ChatRequest: Encodable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double = 0.7
    let maxTokens: Int = 2000
    
    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case maxTokens = "max_tokens"
    }
}

private struct ChatMessage: Codable {
    let role: String
    let content: String
}

private struct VisionRequest: Encodable {
    let model: String
    let messages: [VisionMessage]
    let temperature: Double = 0.7
    let maxTokens: Int = 2000
    
    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case maxTokens = "max_tokens"
    }
}

private struct VisionMessage: Encodable {
    let role: String
    let content: [VisionContent]
}

private struct VisionContent: Encodable {
    let type: String
    var text: String?
    var imageUrl: ImageURL?
    
    enum CodingKeys: String, CodingKey {
        case type, text
        case imageUrl = "image_url"
    }
    
    struct ImageURL: Encodable {
        let url: String
    }
}

private struct ChatResponse: Decodable {
    let choices: [Choice]
    
    struct Choice: Decodable {
        let message: ResponseMessage
    }
    
    struct ResponseMessage: Decodable {
        let content: String
    }
}

// MARK: - Quiz Test Model
struct QuizTest: Codable {
    let title: String
    let description: String
    let questions: [QuizQuestion]
    let resultRanges: [ResultRange]
    
    struct QuizQuestion: Codable {
        let id: String
        let text: String
        let options: [String]
        let scores: [Int]
    }
    
    struct ResultRange: Codable {
        let min: Int
        let max: Int
        let title: String
        let description: String
    }
}

// MARK: - AI Errors
enum AIError: LocalizedError {
    case notConfigured
    case invalidResponse
    case apiError(Int)
    case parsingFailed
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "AI service is not configured"
        case .invalidResponse:
            return "Invalid response from AI service"
        case .apiError(let code):
            return "API error: \(code)"
        case .parsingFailed:
            return "Failed to parse AI response"
        }
    }
}
