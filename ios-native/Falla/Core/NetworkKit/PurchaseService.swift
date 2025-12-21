// PurchaseService.swift
// Falla - iOS 26 Fortune Telling App
// StoreKit 2 integration for subscriptions and karma purchases

import Foundation
import StoreKit

/// Service for handling in-app purchases using StoreKit 2
@MainActor
class PurchaseManager: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var isPremium = false
    @Published private(set) var isLoading = false
    
    // MARK: - Product IDs
    private let subscriptionProductIDs = [
        "com.falla.premium.weekly",
        "com.falla.premium.monthly",
        "com.falla.premium.yearly"
    ]
    
    private let karmaProductIDs = [
        "com.falla.karma.50",
        "com.falla.karma.100",
        "com.falla.karma.250",
        "com.falla.karma.500"
    ]
    
    private var updateListenerTask: Task<Void, Never>? = nil
    
    // MARK: - Initialization
    init() {
        updateListenerTask = listenForTransactions()
        
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Load Products
    func loadProducts() async {
        isLoading = true
        
        do {
            let allProductIDs = subscriptionProductIDs + karmaProductIDs
            products = try await Product.products(for: allProductIDs)
            products.sort { $0.price < $1.price }
        } catch {
            print("Failed to load products: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Purchase
    func purchase(productId: String) async -> Bool {
        guard let product = products.first(where: { $0.id == productId }) else {
            print("Product not found: \(productId)")
            return false
        }
        
        return await purchase(product: product)
    }
    
    func purchase(product: Product) async -> Bool {
        isLoading = true
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                
                // Handle the purchase
                await handlePurchase(transaction)
                
                // Finish the transaction
                await transaction.finish()
                
                isLoading = false
                return true
                
            case .userCancelled:
                isLoading = false
                return false
                
            case .pending:
                isLoading = false
                return false
                
            @unknown default:
                isLoading = false
                return false
            }
        } catch {
            print("Purchase failed: \(error)")
            isLoading = false
            return false
        }
    }
    
    // MARK: - Handle Purchase
    private func handlePurchase(_ transaction: Transaction) async {
        if subscriptionProductIDs.contains(transaction.productID) {
            // Subscription purchase
            purchasedProductIDs.insert(transaction.productID)
            isPremium = true
            
            // Record in Firebase
            do {
                let userId = AuthManager.shared.currentUser?.uid ?? ""
                try await FirebaseService.shared.updateUserField(
                    userId: userId,
                    field: "isPremium",
                    value: true
                )
            } catch {
                print("Failed to update premium status: \(error)")
            }
            
        } else if karmaProductIDs.contains(transaction.productID) {
            // Karma purchase
            let karmaAmount = karmaAmountForProduct(transaction.productID)
            
            // Add karma to user
            let userId = AuthManager.shared.currentUser?.uid ?? ""
            if !userId.isEmpty {
                do {
                    try await FirebaseService.shared.addKarma(
                        userId: userId,
                        amount: karmaAmount,
                        reason: "Karma satın alma"
                    )
                } catch {
                    print("Failed to add karma: \(error)")
                }
            }
        }
    }
    
    private func karmaAmountForProduct(_ productId: String) -> Int {
        switch productId {
        case "com.falla.karma.50": return 50
        case "com.falla.karma.100": return 100
        case "com.falla.karma.250": return 250
        case "com.falla.karma.500": return 500
        default: return 0
        }
    }
    
    // MARK: - Update Purchased Products
    func updatePurchasedProducts() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            
            if transaction.revocationDate == nil {
                purchasedProductIDs.insert(transaction.productID)
                
                if subscriptionProductIDs.contains(transaction.productID) {
                    isPremium = true
                }
            } else {
                purchasedProductIDs.remove(transaction.productID)
            }
        }
    }
    
    // MARK: - Transaction Listener
    private func listenForTransactions() -> Task<Void, Never> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.handlePurchase(transaction)
                    await transaction.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Verification
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Restore Purchases
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
        } catch {
            print("Failed to restore purchases: \(error)")
        }
    }
    
    // MARK: - Subscription Status
    func subscriptionStatus() async -> Product.SubscriptionInfo.Status? {
        guard let subscriptionProduct = products.first(where: { subscriptionProductIDs.contains($0.id) }),
              let subscription = subscriptionProduct.subscription else {
            return nil
        }
        
        do {
            let statuses = try await subscription.status
            return statuses.first
        } catch {
            print("Failed to get subscription status: \(error)")
            return nil
        }
    }
    
    // MARK: - Get Products by Type
    var subscriptionProducts: [Product] {
        products.filter { subscriptionProductIDs.contains($0.id) }
    }
    
    var karmaProducts: [Product] {
        products.filter { karmaProductIDs.contains($0.id) }
    }
    
    // MARK: - Check Premium Status
    func checkPremiumStatus() async -> Bool {
        for productId in subscriptionProductIDs {
            if purchasedProductIDs.contains(productId) {
                return true
            }
        }
        return false
    }
}

// MARK: - Store Error
enum StoreError: LocalizedError {
    case failedVerification
    case productNotFound
    case purchaseFailed
    
    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "İşlem doğrulanamadı"
        case .productNotFound:
            return "Ürün bulunamadı"
        case .purchaseFailed:
            return "Satın alma başarısız"
        }
    }
}
