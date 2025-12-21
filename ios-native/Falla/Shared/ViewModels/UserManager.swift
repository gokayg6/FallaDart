// UserManager.swift
// Falla - iOS 26 Fortune Telling App
// User state management with karma and premium status

import Foundation
import SwiftUI

/// Observable manager for user state
@MainActor
class UserManager: ObservableObject {
    // MARK: - Published Properties
    @Published var karma: Int = 0
    @Published var isPremium: Bool = false
    @Published var dailyFortuneUsed: Bool = false
    @Published var spinWheelUsed: Bool = false
    @Published var displayName: String = ""
    @Published var zodiacSign: String = ""
    
    // MARK: - Dependencies
    private let firebaseService = FirebaseService.shared
    
    // MARK: - Initialization
    init() {
        Task {
            await loadUserData()
        }
    }
    
    // MARK: - Load User Data
    func loadUserData() async {
        guard let userId = AuthManager.shared.currentUser?.uid else { return }
        
        do {
            if let profile = try await firebaseService.getUserProfile(userId: userId) {
                karma = profile.karma
                isPremium = profile.isPremium
                dailyFortuneUsed = !profile.canUseDailyFortune
                displayName = profile.name
                zodiacSign = profile.zodiacSign ?? ""
                spinWheelUsed = profile.lastSpinDate?.isToday == true
            }
        } catch {
            print("Failed to load user data: \(error)")
        }
    }
    
    // MARK: - Karma Management
    func updateKarma(_ amount: Int) async {
        guard let userId = AuthManager.shared.currentUser?.uid else { return }
        
        do {
            if amount > 0 {
                try await firebaseService.addKarma(userId: userId, amount: amount, reason: "Karma eklendi")
            } else {
                try await firebaseService.spendKarma(userId: userId, amount: abs(amount), reason: "Karma harcandı")
            }
            
            karma += amount
        } catch {
            print("Failed to update karma: \(error)")
        }
    }
    
    func addKarma(_ amount: Int, reason: String) async {
        guard let userId = AuthManager.shared.currentUser?.uid else { return }
        
        do {
            try await firebaseService.addKarma(userId: userId, amount: amount, reason: reason)
            karma += amount
        } catch {
            print("Failed to add karma: \(error)")
        }
    }
    
    func spendKarma(_ amount: Int, reason: String) async -> Bool {
        guard karma >= amount else { return false }
        guard let userId = AuthManager.shared.currentUser?.uid else { return false }
        
        do {
            try await firebaseService.spendKarma(userId: userId, amount: amount, reason: reason)
            karma -= amount
            return true
        } catch {
            print("Failed to spend karma: \(error)")
            return false
        }
    }
    
    // MARK: - Daily Fortune
    func useDailyFortune() async {
        guard let userId = AuthManager.shared.currentUser?.uid else { return }
        
        do {
            try await firebaseService.updateUserField(
                userId: userId,
                field: "lastDailyFortuneDate",
                value: Date()
            )
            dailyFortuneUsed = true
        } catch {
            print("Failed to use daily fortune: \(error)")
        }
    }
    
    func canUseDailyFortune() -> Bool {
        return !dailyFortuneUsed || isPremium
    }
    
    // MARK: - Spin Wheel
    func useSpinWheel() async {
        guard let userId = AuthManager.shared.currentUser?.uid else { return }
        
        do {
            try await firebaseService.recordSpinWheelUse(userId: userId)
            spinWheelUsed = true
        } catch {
            print("Failed to record spin wheel use: \(error)")
        }
    }
    
    func canUseSpinWheel() -> Bool {
        return !spinWheelUsed
    }
    
    // MARK: - Premium
    func setPremium(_ value: Bool) async {
        guard let userId = AuthManager.shared.currentUser?.uid else { return }
        
        do {
            try await firebaseService.updateUserField(
                userId: userId,
                field: "isPremium",
                value: value
            )
            isPremium = value
        } catch {
            print("Failed to update premium status: \(error)")
        }
    }
    
    // MARK: - Reset Daily
    func checkAndResetDaily() async {
        guard let userId = AuthManager.shared.currentUser?.uid else { return }
        
        do {
            if let profile = try await firebaseService.getUserProfile(userId: userId) {
                // Check if daily fortune should reset
                if let lastFortuneDate = profile.lastDailyFortuneDate,
                   !Calendar.current.isDateInToday(lastFortuneDate) {
                    dailyFortuneUsed = false
                }
                
                // Check if spin wheel should reset
                if let lastSpinDate = profile.lastSpinDate,
                   !Calendar.current.isDateInToday(lastSpinDate) {
                    spinWheelUsed = false
                }
            }
        } catch {
            print("Failed to check daily reset: \(error)")
        }
    }
}

// MARK: - Date Extension
extension Date {
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
}
