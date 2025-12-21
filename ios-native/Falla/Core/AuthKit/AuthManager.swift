// AuthManager.swift
// Falla - iOS 26 Fortune Telling App
// Authentication manager mirroring Flutter's auth_provider.dart

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

// MARK: - Auth Manager
/// Singleton authentication manager handling Firebase Auth operations
@MainActor
final class AuthManager: ObservableObject {
    // MARK: - Singleton
    static let shared = AuthManager()
    
    // MARK: - Published Properties
    @Published private(set) var currentUser: User?
    @Published private(set) var userProfile: UserModel?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    
    // MARK: - Computed Properties
    var isAuthenticated: Bool { currentUser != nil }
    var currentToken: String? { nil } // Token fetched async when needed
    
    // MARK: - Private Properties
    private let auth = Auth.auth()
    private let firestore = Firestore.firestore()
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    private init() {
        setupAuthStateListener()
    }
    
    deinit {
        if let listener = authStateListener {
            auth.removeStateDidChangeListener(listener)
        }
    }
    
    // MARK: - Auth State Setup
    private func setupAuthStateListener() {
        authStateListener = auth.addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
                if let user = user {
                    await self?.ensureUserProfile(for: user)
                } else {
                    self?.userProfile = nil
                }
            }
        }
    }
    
    // MARK: - Loading & Error State
    private func setLoading(_ loading: Bool) {
        isLoading = loading
    }
    
    private func setError(_ error: String?) {
        errorMessage = error
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Sign In with Email & Password
    /// Sign in with email and password
    /// - Returns: `true` if sign in was successful
    func signInWithEmailAndPassword(email: String, password: String) async throws -> Bool {
        setLoading(true)
        setError(nil)
        
        defer { setLoading(false) }
        
        do {
            let result = try await auth.signIn(withEmail: email.trimmingCharacters(in: .whitespaces), password: password)
            currentUser = result.user
            
            if result.user != nil {
                await ensureUserProfile(for: result.user)
                print("✅ Login successful: \(result.user.email ?? "")")
                return true
            }
            return false
        } catch let error as NSError {
            setError(getAuthErrorMessage(error))
            throw error
        }
    }
    
    // MARK: - Register with Email & Password
    /// Register new user with email and password
    func registerWithEmailAndPassword(
        email: String,
        password: String,
        displayName: String,
        birthDate: Date,
        zodiacSign: String,
        gender: String
    ) async throws -> Bool {
        setLoading(true)
        setError(nil)
        
        defer { setLoading(false) }
        
        do {
            // Check IP address (optional - fail open)
            let ipAddress = await IPService.shared.getPublicIP()
            if let ip = ipAddress {
                let isIPUsed = await FirebaseService.shared.isIPAddressUsed(ip, accountType: "registered")
                if isIPUsed {
                    setError("Bu IP adresinden zaten bir kayıtlı hesap oluşturulmuş.")
                    return false
                }
            }
            
            // Create user
            let result = try await auth.createUser(withEmail: email.trimmingCharacters(in: .whitespaces), password: password)
            currentUser = result.user
            
            // Update display name
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            try await changeRequest.commitChanges()
            
            // Register IP
            if let ip = ipAddress {
                await FirebaseService.shared.registerIPAddress(ip, userId: result.user.uid, accountType: "registered")
            }
            
            // Create user profile
            await createUserProfile(
                user: result.user,
                displayName: displayName,
                birthDate: birthDate,
                zodiacSign: zodiacSign,
                gender: gender
            )
            
            return true
        } catch let error as NSError {
            setError(getAuthErrorMessage(error))
            throw error
        }
    }
    
    // MARK: - Sign In Anonymously (Guest)
    /// Sign in as guest user
    func signInAnonymously(birthDate: Date? = nil) async throws -> Bool {
        setLoading(true)
        setError(nil)
        
        defer { setLoading(false) }
        
        do {
            // Check IP address (optional - fail open)
            let ipAddress = await IPService.shared.getPublicIP()
            if let ip = ipAddress {
                let isIPUsed = await FirebaseService.shared.isIPAddressUsed(ip, accountType: "guest")
                if isIPUsed {
                    setError("Bu IP adresinden zaten bir misafir hesabı oluşturulmuş.")
                    return false
                }
            }
            
            let result = try await auth.signInAnonymously()
            currentUser = result.user
            
            // Register IP
            if let ip = ipAddress {
                await FirebaseService.shared.registerIPAddress(ip, userId: result.user.uid, accountType: "guest")
            }
            
            // Create guest profile
            await createGuestProfile(user: result.user, birthDate: birthDate)
            print("✅ Guest login successful: \(result.user.uid)")
            
            return true
        } catch let error as NSError {
            setError(getAuthErrorMessage(error))
            throw error
        }
    }
    
    // MARK: - Sign Out
    /// Sign out current user
    func signOut() async {
        do {
            try auth.signOut()
            currentUser = nil
            userProfile = nil
        } catch {
            setError("Çıkış yapılırken hata oluştu: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Reset Password
    /// Send password reset email
    func resetPassword(email: String) async throws -> Bool {
        setLoading(true)
        setError(nil)
        
        defer { setLoading(false) }
        
        // Validate email format
        guard email.contains("@") && email.contains(".") else {
            setError("📮 Geçersiz e-posta adresi.")
            return false
        }
        
        do {
            try await auth.sendPasswordReset(withEmail: email.trimmingCharacters(in: .whitespaces))
            print("✅ Şifre sıfırlama e-postası gönderildi: \(email)")
            return true
        } catch let error as NSError {
            setError(getAuthErrorMessage(error))
            throw error
        }
    }
    
    // MARK: - Update Profile
    /// Update user profile
    func updateProfile(displayName: String? = nil, photoURL: String? = nil) async throws -> Bool {
        guard let user = currentUser else { return false }
        
        setLoading(true)
        setError(nil)
        
        defer { setLoading(false) }
        
        do {
            let changeRequest = user.createProfileChangeRequest()
            
            if let displayName = displayName {
                changeRequest.displayName = displayName
            }
            
            if let photoURL = photoURL, let url = URL(string: photoURL) {
                changeRequest.photoURL = url
            }
            
            try await changeRequest.commitChanges()
            
            // Update Firestore
            var updateData: [String: Any] = ["updatedAt": FieldValue.serverTimestamp()]
            if let displayName = displayName { updateData["name"] = displayName }
            if let photoURL = photoURL { updateData["photoURL"] = photoURL }
            
            try await firestore.collection("users").document(user.uid).updateData(updateData)
            
            return true
        } catch {
            setError("Profil güncellenirken hata oluştu: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Delete Account
    /// Delete user account
    func deleteAccount() async throws -> Bool {
        guard let user = currentUser else { return false }
        
        setLoading(true)
        setError(nil)
        
        defer { setLoading(false) }
        
        do {
            // Unregister IP
            await FirebaseService.shared.unregisterIPForUser(user.uid)
            
            // Delete Firestore data
            try await firestore.collection("users").document(user.uid).delete()
            
            // Delete auth user
            try await user.delete()
            
            currentUser = nil
            userProfile = nil
            
            return true
        } catch {
            setError("Hesap silinirken hata oluştu: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Re-authenticate
    /// Re-authenticate user for sensitive operations
    func reAuthenticate(password: String) async throws -> Bool {
        guard let user = currentUser, let email = user.email else { return false }
        
        do {
            let credential = EmailAuthProvider.credential(withEmail: email, password: password)
            try await user.reauthenticate(with: credential)
            return true
        } catch {
            setError("Kimlik doğrulama başarısız: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Get User Karma
    /// Get current user's karma balance
    func getUserKarma() async -> Int {
        return userProfile?.karma ?? 0
    }
    
    // MARK: - Add Karma
    /// Add karma to current user
    func addKarma(_ amount: Int) async -> Bool {
        guard let user = currentUser else { return false }
        
        do {
            try await firestore.collection("users").document(user.uid).updateData([
                "karma": FieldValue.increment(Int64(amount)),
                "updatedAt": FieldValue.serverTimestamp()
            ])
            
            // Update local profile
            if var profile = userProfile {
                profile.karma += amount
                userProfile = profile
            }
            
            return true
        } catch {
            setError("Karma eklenirken hata oluştu: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Private Methods
    
    private func ensureUserProfile(for user: User) async {
        let docRef = firestore.collection("users").document(user.uid)
        
        do {
            let document = try await docRef.getDocument()
            
            if document.exists, let data = document.data() {
                userProfile = UserModel.fromFirestore(data)
                
                // Update last login
                try? await docRef.updateData(["lastLoginAt": FieldValue.serverTimestamp()])
            } else {
                // Create basic profile for existing auth user
                await createBasicUserProfile(user: user)
            }
        } catch {
            print("❌ Error ensuring user profile: \(error)")
        }
    }
    
    private func createBasicUserProfile(user: User) async {
        let userData: [String: Any] = [
            "id": user.uid,
            "name": user.displayName ?? user.email?.components(separatedBy: "@").first ?? "Kullanıcı",
            "email": user.email ?? "",
            "karma": 10,
            "isPremium": false,
            "createdAt": FieldValue.serverTimestamp(),
            "lastLoginAt": FieldValue.serverTimestamp(),
            "dailyFortunesUsed": 0,
            "favoriteFortuneTypes": [],
            "totalFortunes": 0,
            "totalTests": 0,
            "preferences": [
                "notifications": true,
                "sound": true,
                "vibration": true,
                "language": "tr",
                "theme": "mystical",
                "autoSaveFortunes": true,
                "showKarmaNotifications": true,
                "premiumNotifications": false
            ]
        ]
        
        do {
            try await firestore.collection("users").document(user.uid).setData(userData, merge: true)
            userProfile = UserModel.fromFirestore(userData)
        } catch {
            print("❌ Error creating basic profile: \(error)")
        }
    }
    
    private func createUserProfile(user: User, displayName: String, birthDate: Date, zodiacSign: String, gender: String) async {
        let age = UserModel.calculateAge(from: birthDate)
        let ageGroup = age < 18 ? "under18" : "adult"
        
        let userData: [String: Any] = [
            "id": user.uid,
            "name": displayName,
            "email": user.email ?? "",
            "birthDate": birthDate,
            "zodiacSign": zodiacSign,
            "gender": gender,
            "age": age,
            "ageGroup": ageGroup,
            "karma": 10,
            "isPremium": false,
            "createdAt": FieldValue.serverTimestamp(),
            "lastLoginAt": FieldValue.serverTimestamp(),
            "dailyFortunesUsed": 0,
            "favoriteFortuneTypes": [],
            "totalFortunes": 0,
            "totalTests": 0,
            "socialVisible": true,
            "blockedUsers": [],
            "preferences": [
                "notifications": true,
                "sound": true,
                "vibration": true,
                "language": "tr",
                "theme": "mystical",
                "autoSaveFortunes": true,
                "showKarmaNotifications": true,
                "premiumNotifications": false
            ]
        ]
        
        do {
            try await firestore.collection("users").document(user.uid).setData(userData, merge: true)
            userProfile = UserModel.fromFirestore(userData)
        } catch {
            print("❌ Error creating user profile: \(error)")
        }
    }
    
    private func createGuestProfile(user: User, birthDate: Date?) async {
        var guestData: [String: Any] = [
            "id": user.uid,
            "name": "Misafir",
            "email": "",
            "karma": 10,
            "isPremium": false,
            "createdAt": FieldValue.serverTimestamp(),
            "lastLoginAt": FieldValue.serverTimestamp(),
            "dailyFortunesUsed": 0,
            "favoriteFortuneTypes": [],
            "totalFortunes": 0,
            "totalTests": 0,
            "preferences": [
                "notifications": true,
                "sound": true,
                "vibration": true,
                "language": "tr",
                "theme": "mystical",
                "autoSaveFortunes": true,
                "showKarmaNotifications": true,
                "premiumNotifications": false
            ]
        ]
        
        if let birthDate = birthDate {
            guestData["birthDate"] = birthDate
            guestData["zodiacSign"] = UserModel.calculateZodiacSign(from: birthDate)
        }
        
        do {
            try await firestore.collection("users").document(user.uid).setData(guestData)
            userProfile = UserModel.fromFirestore(guestData)
        } catch {
            print("❌ Error creating guest profile: \(error)")
        }
    }
    
    // MARK: - Error Messages
    private func getAuthErrorMessage(_ error: NSError) -> String {
        let code = AuthErrorCode(rawValue: error.code)
        
        switch code {
        case .userNotFound:
            return "🔍 Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı."
        case .wrongPassword:
            return "🔐 Hatalı şifre girdiniz."
        case .emailAlreadyInUse:
            return "📧 Bu e-posta adresi zaten kullanımda."
        case .weakPassword:
            return "🛡️ Şifre çok zayıf. En az 6 karakter olmalıdır."
        case .invalidEmail:
            return "📮 Geçersiz e-posta adresi."
        case .userDisabled:
            return "🚫 Bu hesap devre dışı bırakılmış."
        case .tooManyRequests:
            return "⏰ Çok fazla deneme yapıldı. 15 dakika bekleyin."
        case .networkError:
            return "🌐 İnternet bağlantınızı kontrol edin."
        case .invalidCredential:
            return "❌ Geçersiz kimlik bilgileri."
        default:
            return "⚠️ Kimlik doğrulama hatası oluştu."
        }
    }
}
