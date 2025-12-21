// APIClient.swift
// Falla - iOS 26 Fortune Telling App
// URLSession-based networking layer mirroring Flutter's Dio patterns

import Foundation

// MARK: - API Client
/// Actor-based networking client for thread-safe API requests
actor APIClient {
    // MARK: - Singleton
    static let shared = APIClient()
    
    // MARK: - Configuration
    private let baseURL = URL(string: "https://api.falla.com")!
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    // MARK: - Timeout Configuration
    private let defaultTimeout: TimeInterval = 30
    private let uploadTimeout: TimeInterval = 120
    
    // MARK: - Initialization
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = defaultTimeout
        configuration.timeoutIntervalForResource = uploadTimeout
        configuration.waitsForConnectivity = true
        configuration.httpMaximumConnectionsPerHost = 6
        
        self.session = URLSession(configuration: configuration)
        
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        self.encoder.keyEncodingStrategy = .convertToSnakeCase
    }
    
    // MARK: - Request Methods
    
    /// Perform a GET request
    func get<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let request = try await buildRequest(for: endpoint, method: .get)
        return try await perform(request)
    }
    
    /// Perform a POST request with JSON body
    func post<T: Decodable, B: Encodable>(_ endpoint: Endpoint, body: B) async throws -> T {
        var request = try await buildRequest(for: endpoint, method: .post)
        request.httpBody = try encoder.encode(body)
        return try await perform(request)
    }
    
    /// Perform a POST request without response body
    func post<B: Encodable>(_ endpoint: Endpoint, body: B) async throws {
        var request = try await buildRequest(for: endpoint, method: .post)
        request.httpBody = try encoder.encode(body)
        let _: EmptyResponse = try await perform(request)
    }
    
    /// Perform a PUT request
    func put<T: Decodable, B: Encodable>(_ endpoint: Endpoint, body: B) async throws -> T {
        var request = try await buildRequest(for: endpoint, method: .put)
        request.httpBody = try encoder.encode(body)
        return try await perform(request)
    }
    
    /// Perform a DELETE request
    func delete(_ endpoint: Endpoint) async throws {
        let request = try await buildRequest(for: endpoint, method: .delete)
        let _: EmptyResponse = try await perform(request)
    }
    
    /// Upload multipart form data
    func upload<T: Decodable>(_ endpoint: Endpoint, data: Data, mimeType: String, fileName: String) async throws -> T {
        var request = try await buildRequest(for: endpoint, method: .post)
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        return try await perform(request)
    }
    
    // MARK: - Private Methods
    
    private func buildRequest(for endpoint: Endpoint, method: HTTPMethod) async throws -> URLRequest {
        let url = baseURL.appendingPathComponent(endpoint.path)
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        
        if let queryItems = endpoint.queryItems {
            urlComponents.queryItems = queryItems
        }
        
        guard let finalURL = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: finalURL)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Falla-iOS/1.0", forHTTPHeaderField: "User-Agent")
        
        // Inject auth token if available
        if let token = await getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Add custom headers from endpoint
        endpoint.headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        #if DEBUG
        logRequest(request)
        #endif
        
        return request
    }
    
    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        #if DEBUG
        logResponse(httpResponse, data: data)
        #endif
        
        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                print("❌ Decoding error: \(error)")
                throw APIError.decodingFailed(error)
            }
            
        case 401:
            // Unauthorized - trigger logout
            await handleUnauthorized()
            throw APIError.unauthorized
            
        case 403:
            throw APIError.forbidden
            
        case 404:
            throw APIError.notFound
            
        case 422:
            // Validation error
            if let errorResponse = try? decoder.decode(ValidationErrorResponse.self, from: data) {
                throw APIError.validationError(errorResponse.errors)
            }
            throw APIError.validationError([:])
            
        case 429:
            throw APIError.rateLimited
            
        case 500...599:
            throw APIError.serverError(httpResponse.statusCode)
            
        default:
            throw APIError.unknown(httpResponse.statusCode)
        }
    }
    
    private func getAuthToken() async -> String? {
        // Get token from Firebase Auth
        return try? await AuthManager.shared.currentUser?.getIDToken()
    }
    
    private func handleUnauthorized() async {
        await AuthManager.shared.signOut()
    }
    
    // MARK: - Debug Logging
    
    #if DEBUG
    private func logRequest(_ request: URLRequest) {
        print("📤 \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "")")
        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            print("   Body: \(bodyString.prefix(500))")
        }
    }
    
    private func logResponse(_ response: HTTPURLResponse, data: Data) {
        let emoji = (200...299).contains(response.statusCode) ? "✅" : "❌"
        print("\(emoji) \(response.statusCode) \(response.url?.absoluteString ?? "")")
        if let bodyString = String(data: data, encoding: .utf8) {
            print("   Response: \(bodyString.prefix(500))")
        }
    }
    #endif
}

// MARK: - HTTP Methods
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

// MARK: - API Error
enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingFailed(Error)
    case unauthorized
    case forbidden
    case notFound
    case validationError([String: [String]])
    case rateLimited
    case serverError(Int)
    case networkError(Error)
    case unknown(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Geçersiz URL"
        case .invalidResponse:
            return "Geçersiz sunucu yanıtı"
        case .decodingFailed:
            return "Veri işlenemedi"
        case .unauthorized:
            return "Oturum süresi doldu. Lütfen tekrar giriş yapın."
        case .forbidden:
            return "Bu işlem için yetkiniz yok"
        case .notFound:
            return "İstenen kaynak bulunamadı"
        case .validationError(let errors):
            return errors.values.flatMap { $0 }.joined(separator: ", ")
        case .rateLimited:
            return "Çok fazla istek gönderildi. Lütfen bekleyin."
        case .serverError(let code):
            return "Sunucu hatası: \(code)"
        case .networkError:
            return "Ağ bağlantısı hatası"
        case .unknown(let code):
            return "Bilinmeyen hata: \(code)"
        }
    }
}

// MARK: - Empty Response
struct EmptyResponse: Decodable {}

// MARK: - Validation Error Response
struct ValidationErrorResponse: Decodable {
    let errors: [String: [String]]
}
