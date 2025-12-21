// FirebaseService.swift
// Falla - iOS 26 Fortune Telling App
// Firebase Firestore operations matching Flutter's firebase_service.dart

import Foundation
import FirebaseFirestore
import FirebaseStorage

// MARK: - Firebase Service
/// Singleton service for all Firebase Firestore and Storage operations
actor FirebaseService {
    // MARK: - Singleton
    static let shared = FirebaseService()
    
    // MARK: - Firebase References
    private let firestore = Firestore.firestore()
    private let storage = Storage.storage()
    
    // MARK: - Initialization
    private init() {
        // Configure Firestore settings
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings()
        firestore.settings = settings
    }
    
    // MARK: - User Profile Methods
    
    /// Create user profile
    func createUserProfile(_ userId: String, userData: [String: Any]) async throws {
        try await firestore.collection("users").document(userId).setData(userData)
    }
    
    /// Get user profile
    func getUserProfile(_ userId: String) async throws -> UserModel? {
        let document = try await firestore.collection("users").document(userId).getDocument()
        guard let data = document.data() else { return nil }
        return UserModel.fromFirestore(data)
    }
    
    /// Update user profile
    func updateUserProfile(_ userId: String, data: [String: Any]) async throws {
        var updateData = data
        updateData["updatedAt"] = FieldValue.serverTimestamp()
        try await firestore.collection("users").document(userId).updateData(updateData)
    }
    
    /// Stream user profile updates
    func getUserProfileStream(_ userId: String) -> AsyncStream<UserModel?> {
        AsyncStream { continuation in
            let listener = firestore.collection("users").document(userId)
                .addSnapshotListener { snapshot, error in
                    guard let data = snapshot?.data() else {
                        continuation.yield(nil)
                        return
                    }
                    continuation.yield(UserModel.fromFirestore(data))
                }
            
            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }
    
    // MARK: - Karma Methods
    
    /// Update karma balance
    func updateKarma(_ userId: String, amount: Int, reason: String) async throws {
        let userRef = firestore.collection("users").document(userId)
        
        try await firestore.runTransaction { transaction, errorPointer in
            let userDoc: DocumentSnapshot
            do {
                userDoc = try transaction.getDocument(userRef)
            } catch let error {
                errorPointer?.pointee = error as NSError
                return nil
            }
            
            let currentKarma = userDoc.data()?["karma"] as? Int ?? 0
            let newKarma = max(0, currentKarma + amount)
            
            transaction.updateData(["karma": newKarma, "updatedAt": FieldValue.serverTimestamp()], forDocument: userRef)
            
            return nil
        }
        
        // Log karma transaction
        try await addKarmaTransaction(userId, amount: amount, reason: reason)
    }
    
    /// Add karma transaction log
    func addKarmaTransaction(_ userId: String, amount: Int, reason: String) async throws {
        let transaction: [String: Any] = [
            "userId": userId,
            "amount": amount,
            "reason": reason,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        try await firestore.collection("users").document(userId)
            .collection("karmaTransactions")
            .addDocument(data: transaction)
    }
    
    // MARK: - Fortune Methods
    
    /// Save fortune result
    func saveFortune(_ userId: String, fortuneData: [String: Any]) async throws -> String {
        var data = fortuneData
        data["createdAt"] = FieldValue.serverTimestamp()
        
        let docRef = try await firestore.collection("users").document(userId)
            .collection("fortunes")
            .addDocument(data: data)
        
        return docRef.documentID
    }
    
    /// Get user fortunes
    func getUserFortunes(_ userId: String) async throws -> [FortuneModel] {
        let snapshot = try await firestore.collection("users").document(userId)
            .collection("fortunes")
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            var data = doc.data()
            data["id"] = doc.documentID
            return FortuneModel.fromFirestore(data)
        }
    }
    
    /// Get single fortune
    func getFortune(_ userId: String, fortuneId: String) async throws -> FortuneModel? {
        let document = try await firestore.collection("users").document(userId)
            .collection("fortunes")
            .document(fortuneId)
            .getDocument()
        
        guard var data = document.data() else { return nil }
        data["id"] = document.documentID
        return FortuneModel.fromFirestore(data)
    }
    
    /// Update fortune
    func updateFortune(_ userId: String, fortuneId: String, data: [String: Any]) async throws {
        try await firestore.collection("users").document(userId)
            .collection("fortunes")
            .document(fortuneId)
            .updateData(data)
    }
    
    /// Delete fortune
    func deleteFortune(_ userId: String, fortuneId: String) async throws {
        try await firestore.collection("users").document(userId)
            .collection("fortunes")
            .document(fortuneId)
            .delete()
    }
    
    // MARK: - Image Upload
    
    /// Upload image to Firebase Storage
    func uploadImage(path: String, imageData: Data) async throws -> String {
        let storageRef = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()
        
        return downloadURL.absoluteString
    }
    
    /// Delete image from Firebase Storage
    func deleteImage(url: String) async throws {
        let storageRef = storage.reference(forURL: url)
        try await storageRef.delete()
    }
    
    // MARK: - Spin Wheel Methods
    
    /// Check if user can spin
    func canSpin(_ userId: String, cooldown: TimeInterval = 86400) async throws -> Bool {
        let spinDoc = try await getSpinDoc(userId)
        
        guard let lastSpin = spinDoc?["lastSpin"] as? Timestamp else {
            return true
        }
        
        return Date().timeIntervalSince(lastSpin.dateValue()) >= cooldown
    }
    
    /// Get spin document
    func getSpinDoc(_ userId: String) async throws -> [String: Any]? {
        let document = try await firestore.collection("users").document(userId)
            .collection("gamification")
            .document("spin")
            .getDocument()
        
        return document.data()
    }
    
    /// Record spin
    func recordSpin(_ userId: String, reward: [String: Any], isAdSpin: Bool = false, doubledReward: Bool = false) async throws {
        let spinData: [String: Any] = [
            "lastSpin": FieldValue.serverTimestamp(),
            "reward": reward,
            "isAdSpin": isAdSpin,
            "doubledReward": doubledReward
        ]
        
        try await firestore.collection("users").document(userId)
            .collection("gamification")
            .document("spin")
            .setData(spinData, merge: true)
    }
    
    // MARK: - Daily Login Methods
    
    /// Check daily login status
    func checkDailyLogin(_ userId: String) async throws -> Bool {
        let document = try await firestore.collection("users").document(userId)
            .collection("gamification")
            .document("login")
            .getDocument()
        
        guard let data = document.data(),
              let lastLogin = data["lastLogin"] as? Timestamp else {
            return false
        }
        
        return Calendar.current.isDateInToday(lastLogin.dateValue())
    }
    
    /// Record daily login
    func recordDailyLogin(_ userId: String) async throws {
        let loginData: [String: Any] = [
            "lastLogin": FieldValue.serverTimestamp()
        ]
        
        try await firestore.collection("users").document(userId)
            .collection("gamification")
            .document("login")
            .setData(loginData, merge: true)
    }
    
    /// Get login streak
    func getLoginStreak(_ userId: String) async throws -> Int {
        let document = try await firestore.collection("users").document(userId)
            .collection("gamification")
            .document("login")
            .getDocument()
        
        guard let data = document.data() else { return 0 }
        return data["streak"] as? Int ?? 0
    }
    
    // MARK: - IP Address Methods
    
    /// Check if IP is used for account type
    func isIPAddressUsed(_ ipAddress: String, accountType: String) async -> Bool {
        do {
            let snapshot = try await firestore.collection("ip_addresses")
                .whereField("ipAddress", isEqualTo: ipAddress)
                .whereField("accountType", isEqualTo: accountType)
                .getDocuments()
            
            return !snapshot.documents.isEmpty
        } catch {
            print("⚠️ Error checking IP: \(error)")
            return false
        }
    }
    
    /// Register IP address
    func registerIPAddress(_ ipAddress: String, userId: String, accountType: String) async {
        let ipData: [String: Any] = [
            "ipAddress": ipAddress,
            "userId": userId,
            "accountType": accountType,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        do {
            try await firestore.collection("ip_addresses").addDocument(data: ipData)
        } catch {
            print("⚠️ Error registering IP: \(error)")
        }
    }
    
    /// Unregister IP for user
    func unregisterIPForUser(_ userId: String) async {
        do {
            let snapshot = try await firestore.collection("ip_addresses")
                .whereField("userId", isEqualTo: userId)
                .getDocuments()
            
            for document in snapshot.documents {
                try await document.reference.delete()
            }
        } catch {
            print("⚠️ Error unregistering IP: \(error)")
        }
    }
    
    // MARK: - Love Candidate Methods
    
    /// Create love candidate
    func createLoveCandidate(_ userId: String, candidateData: [String: Any]) async throws -> String {
        var data = candidateData
        data["createdAt"] = FieldValue.serverTimestamp()
        
        let docRef = try await firestore.collection("users").document(userId)
            .collection("loveCandidates")
            .addDocument(data: data)
        
        return docRef.documentID
    }
    
    /// Get love candidates
    func getLoveCandidates(_ userId: String) async throws -> [[String: Any]] {
        let snapshot = try await firestore.collection("users").document(userId)
            .collection("loveCandidates")
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.map { doc in
            var data = doc.data()
            data["id"] = doc.documentID
            return data
        }
    }
    
    /// Update love candidate
    func updateLoveCandidate(_ userId: String, candidateId: String, data: [String: Any]) async throws {
        try await firestore.collection("users").document(userId)
            .collection("loveCandidates")
            .document(candidateId)
            .updateData(data)
    }
    
    /// Delete love candidate
    func deleteLoveCandidate(_ userId: String, candidateId: String) async throws {
        try await firestore.collection("users").document(userId)
            .collection("loveCandidates")
            .document(candidateId)
            .delete()
    }
    
    // MARK: - Dream Draw Methods
    
    /// Save dream draw
    func saveDreamDraw(_ userId: String, data: [String: Any]) async throws -> String {
        var drawData = data
        drawData["createdAt"] = FieldValue.serverTimestamp()
        
        let docRef = try await firestore.collection("users").document(userId)
            .collection("dreamDraws")
            .addDocument(data: drawData)
        
        return docRef.documentID
    }
    
    /// Get dream draws
    func getDreamDraws(_ userId: String) async throws -> [[String: Any]] {
        let snapshot = try await firestore.collection("users").document(userId)
            .collection("dreamDraws")
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.map { doc in
            var data = doc.data()
            data["id"] = doc.documentID
            return data
        }
    }
    
    // MARK: - Quest Methods
    
    /// Record quest completion
    func recordQuestCompletion(_ userId: String, questType: String) async throws {
        let questData: [String: Any] = [
            "type": questType,
            "completedAt": FieldValue.serverTimestamp()
        ]
        
        try await firestore.collection("users").document(userId)
            .collection("completedQuests")
            .addDocument(data: questData)
    }
    
    /// Get completed quests
    func getCompletedQuests(_ userId: String) async throws -> [String] {
        let today = Calendar.current.startOfDay(for: Date())
        
        let snapshot = try await firestore.collection("users").document(userId)
            .collection("completedQuests")
            .whereField("completedAt", isGreaterThanOrEqualTo: today)
            .getDocuments()
        
        return snapshot.documents.compactMap { $0.data()["type"] as? String }
    }
    
    // MARK: - Analytics
    
    /// Log event to Firestore
    func logEvent(_ eventName: String, parameters: [String: Any]) async throws {
        var eventData = parameters
        eventData["eventName"] = eventName
        eventData["createdAt"] = FieldValue.serverTimestamp()
        
        try await firestore.collection("analytics").addDocument(data: eventData)
    }
}
