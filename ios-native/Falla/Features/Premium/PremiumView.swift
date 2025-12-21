// PremiumView.swift
// Falla - iOS 26 Fortune Telling App
// Premium subscription and karma purchase screen

import SwiftUI
import StoreKit

// MARK: - Premium View
struct PremiumMainView: View {
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userManager: UserManager
    @EnvironmentObject private var purchaseManager: PurchaseManager
    
    // MARK: - State
    @State private var selectedPlan: SubscriptionPlan = .monthly
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var animateGlow = false
    
    // MARK: - Body
    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Features
                    featuresSection
                    
                    // Subscription plans
                    plansSection
                    
                    // Karma packages
                    karmaSection
                    
                    // Terms
                    termsSection
                    
                    Spacer()
                        .frame(height: 100)
                }
                .padding(.horizontal, 20)
            }
            
            // Purchase button
            VStack {
                Spacer()
                purchaseButton
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                animateGlow = true
            }
        }
        .alert("Hata", isPresented: $showError) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Background
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.08, green: 0.04, blue: 0.12),
                Color(red: 0.12, green: 0.06, blue: 0.18),
                Color(red: 0.06, green: 0.02, blue: 0.10)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Close button
            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            
            // Crown icon with glow
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.82, green: 0.71, blue: 0.55).opacity(animateGlow ? 0.4 : 0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 30,
                            endRadius: 80
                        )
                    )
                    .frame(width: 150, height: 150)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.9, green: 0.8, blue: 0.5),
                                Color(red: 0.82, green: 0.71, blue: 0.55)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            
            Text("Premium'a Geç")
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundColor(.white)
            
            Text("Sınırsız fal, özel içerikler ve reklamsız deneyim")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Features Section
    private var featuresSection: some View {
        GlassCard(cornerRadius: 20, padding: 20) {
            VStack(spacing: 16) {
                ForEach(premiumFeatures, id: \.title) { feature in
                    HStack(spacing: 14) {
                        Image(systemName: feature.icon)
                            .font(.system(size: 20))
                            .foregroundColor(Color(red: 0.82, green: 0.71, blue: 0.55))
                            .frame(width: 36, height: 36)
                            .background(Color(red: 0.82, green: 0.71, blue: 0.55).opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(feature.title)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text(feature.description)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            }
        }
    }
    
    private var premiumFeatures: [(icon: String, title: String, description: String)] {
        [
            ("infinity", "Sınırsız Fal", "Tüm fal türlerini dilediğiniz kadar kullanın"),
            ("nosign", "Reklamsız", "Hiçbir reklam görmeden keyfini çıkarın"),
            ("star.fill", "Özel İçerikler", "Premium üyelere özel yorumlar"),
            ("person.2.fill", "Öncelikli Destek", "7/24 öncelikli müşteri desteği"),
            ("sparkles", "Bonus Karma", "Her ay 100 bonus karma kazanın")
        ]
    }
    
    // MARK: - Plans Section
    private var plansSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Abonelik Planları")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            ForEach(SubscriptionPlan.allCases, id: \.self) { plan in
                planCard(plan)
            }
        }
    }
    
    private func planCard(_ plan: SubscriptionPlan) -> some View {
        let isSelected = selectedPlan == plan
        
        return Button(action: {
            withAnimation(.spring(response: 0.3)) {
                selectedPlan = plan
            }
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(plan.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        if plan == .yearly {
                            Text("EN POPÜLER")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.orange)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(plan.subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(plan.price)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(red: 0.82, green: 0.71, blue: 0.55))
                    
                    if let savings = plan.savings {
                        Text(savings)
                            .font(.system(size: 11))
                            .foregroundColor(.green)
                    }
                }
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? Color(red: 0.82, green: 0.71, blue: 0.55) : .white.opacity(0.3))
                    .padding(.leading, 8)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(isSelected ? 0.1 : 0.05))
                    .strokeBorder(
                        isSelected 
                            ? Color(red: 0.82, green: 0.71, blue: 0.55)
                            : Color.white.opacity(0.1),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
    }
    
    // MARK: - Karma Section
    private var karmaSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Karma Paketleri")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                ForEach(karmaPackages, id: \.karma) { package in
                    karmaPackageCard(package)
                }
            }
        }
    }
    
    private func karmaPackageCard(_ package: KarmaPackage) -> some View {
        Button(action: {
            purchaseKarma(package)
        }) {
            VStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 24))
                    .foregroundColor(Color(red: 0.82, green: 0.71, blue: 0.55))
                
                Text("\(package.karma)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Karma")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
                
                Text(package.price)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(red: 0.82, green: 0.71, blue: 0.55))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
    
    private var karmaPackages: [KarmaPackage] {
        [
            KarmaPackage(karma: 50, price: "₺29.99"),
            KarmaPackage(karma: 100, price: "₺49.99"),
            KarmaPackage(karma: 250, price: "₺99.99"),
            KarmaPackage(karma: 500, price: "₺179.99")
        ]
    }
    
    // MARK: - Terms Section
    private var termsSection: some View {
        VStack(spacing: 8) {
            Text("Abonelik otomatik olarak yenilenir. İstediğiniz zaman iptal edebilirsiniz.")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
            
            HStack(spacing: 20) {
                Button("Kullanım Koşulları") {}
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
                
                Button("Gizlilik Politikası") {}
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
                
                Button("Satın Almaları Geri Yükle") {}
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Purchase Button
    private var purchaseButton: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.white.opacity(0.1))
            
            Button(action: purchaseSubscription) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "crown.fill")
                        Text("Premium'a Geç - \(selectedPlan.price)")
                    }
                }
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.82, green: 0.71, blue: 0.55),
                            Color(red: 0.7, green: 0.55, blue: 0.4)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(isLoading)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial)
        }
    }
    
    // MARK: - Methods
    private func purchaseSubscription() {
        isLoading = true
        
        Task {
            let success = await purchaseManager.purchase(productId: selectedPlan.productId)
            
            await MainActor.run {
                isLoading = false
                if success {
                    dismiss()
                } else {
                    errorMessage = "Satın alma işlemi başarısız oldu"
                    showError = true
                }
            }
        }
    }
    
    private func purchaseKarma(_ package: KarmaPackage) {
        // Implement karma purchase
    }
}

// MARK: - Subscription Plan
enum SubscriptionPlan: CaseIterable {
    case weekly
    case monthly
    case yearly
    
    var title: String {
        switch self {
        case .weekly: return "Haftalık"
        case .monthly: return "Aylık"
        case .yearly: return "Yıllık"
        }
    }
    
    var subtitle: String {
        switch self {
        case .weekly: return "7 gün deneme"
        case .monthly: return "Her ay faturalandırılır"
        case .yearly: return "Her yıl faturalandırılır"
        }
    }
    
    var price: String {
        switch self {
        case .weekly: return "₺29.99"
        case .monthly: return "₺79.99"
        case .yearly: return "₺599.99"
        }
    }
    
    var savings: String? {
        switch self {
        case .weekly: return nil
        case .monthly: return nil
        case .yearly: return "%37 Tasarruf"
        }
    }
    
    var productId: String {
        switch self {
        case .weekly: return "com.falla.premium.weekly"
        case .monthly: return "com.falla.premium.monthly"
        case .yearly: return "com.falla.premium.yearly"
        }
    }
}

// MARK: - Karma Package
struct KarmaPackage {
    let karma: Int
    let price: String
}

// MARK: - Preview
#Preview {
    PremiumMainView()
        .environmentObject(UserManager())
        .environmentObject(PurchaseManager())
}
